// This file is part of mac2imgur.
//
// mac2imgur is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// mac2imgur is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with mac2imgur.  If not, see <http://www.gnu.org/licenses/>.

import AppKit
import Core
import Foundation

/// Bridges between Core (`ImgurClient`/`OAuthCoordinator`) and the AppKit shell.
/// Owns the upload pipeline: read file → upload → notify → pasteboard → trash.
@MainActor
final class UploadHandler {
    private let client: ImgurClient
    private let oauth: OAuthCoordinator
    private let preferences: Preferences
    private let history: UploadHistory
    private let onActiveCountChange: (Int) -> Void

    private var activeCount = 0 {
        didSet { onActiveCountChange(activeCount) }
    }

    init(
        client: ImgurClient,
        oauth: OAuthCoordinator,
        preferences: Preferences,
        history: UploadHistory,
        onActiveCountChange: @escaping (Int) -> Void
    ) {
        self.client = client
        self.oauth = oauth
        self.preferences = preferences
        self.history = history
        self.onActiveCountChange = onActiveCountChange
    }

    func upload(url: URL, isScreenshot: Bool) async {
        if isScreenshot && preferences.disableScreenshotDetection { return }

        activeCount += 1
        defer { activeCount -= 1 }

        do {
            let data = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let result = try await uploadData(data, filename: filename)
            history.add(result)
            await Notifications.deliver(Notifications.uploadSuccessContent(link: result.link))
            if preferences.copyLinkToClipboard {
                if preferences.clearClipboard {
                    NSPasteboard.general.clearContents()
                }
                NSPasteboard.general.setString(result.link.absoluteString, forType: .string)
            }
            if isScreenshot && preferences.deleteAfterUpload {
                try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
            }
        } catch {
            await Notifications.deliver(Notifications.uploadFailureContent(reason: "\(error)"))
        }
    }

    private func uploadData(_ data: Data, filename: String) async throws -> UploadedImage {
        if let refreshToken = preferences.refreshToken {
            do {
                let tokens = try await oauth.refresh(refreshToken: refreshToken)
                preferences.refreshToken = tokens.refreshToken
                return try await client.uploadAuthenticated(
                    data: data,
                    filename: filename,
                    accessToken: tokens.accessToken,
                    albumID: preferences.imgurAlbumID
                )
            } catch OAuthError.refreshExpired {
                // Token dead - clear and fall back to anonymous
                preferences.refreshToken = nil
                preferences.imgurAlbumID = nil
                return try await client.uploadAnonymous(data: data, filename: filename)
            }
        }
        return try await client.uploadAnonymous(data: data, filename: filename)
    }
}
