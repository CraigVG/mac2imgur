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
import Sparkle

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let preferences = Preferences()
    let history = UploadHistory()
    let imgurClient = ImgurClient()
    let oauthCoordinator = OAuthCoordinator()
    let oauthFlow = ImgurOAuthFlow()

    private var screenshotMonitor: ScreenshotMonitor?
    private var statusItemController: StatusItemController?
    private var uploadHandler: UploadHandler!
    private var updaterController: SPUStandardUpdaterController?

    private var hasFinishedLaunching = false
    private var queuedFileURLs: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure Sparkle
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Set up upload pipeline
        uploadHandler = UploadHandler(
            client: imgurClient,
            oauth: oauthCoordinator,
            preferences: preferences,
            history: history,
            onActiveCountChange: { [weak self] count in
                Task { @MainActor in
                    self?.statusItemController?.activeUploadCount = count
                }
            }
        )

        // Set up status bar UI
        statusItemController = StatusItemController(
            uploader: uploadHandler,
            preferences: preferences,
            history: history,
            onSignIn: { [weak self] in self?.signIn() },
            onSignOut: { [weak self] in self?.signOut() }
        )

        // Watch for screenshots
        screenshotMonitor = ScreenshotMonitor { [weak self] url in
            Task { @MainActor in
                guard let self else { return }
                await self.uploadHandler.upload(url: url, isScreenshot: true)
            }
        }
        screenshotMonitor?.start()

        hasFinishedLaunching = true

        // Drain any queued files (open-with at launch)
        for url in queuedFileURLs {
            Task { await uploadHandler.upload(url: url, isScreenshot: false) }
        }
        queuedFileURLs.removeAll()
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        if hasFinishedLaunching {
            Task { await uploadHandler.upload(url: url, isScreenshot: false) }
        } else {
            queuedFileURLs.append(url)
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        screenshotMonitor?.stop()
    }

    // MARK: OAuth

    private func signIn() {
        Task { @MainActor in
            do {
                let tokens = try await oauthFlow.login()
                preferences.refreshToken = tokens.refreshToken
            } catch {
                await Notifications.deliver(Notifications.uploadFailureContent(reason: "Sign-in failed: \(error)"))
            }
        }
    }

    private func signOut() {
        preferences.refreshToken = nil
        preferences.imgurAlbumID = nil
    }
}
