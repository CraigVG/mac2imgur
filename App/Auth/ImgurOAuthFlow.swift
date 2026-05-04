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
import AuthenticationServices
import Core
import Observation

/// Handles the interactive Imgur OAuth login flow using ASWebAuthenticationSession.
@Observable
@MainActor
final class ImgurOAuthFlow: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let authURL = URL(string: "https://api.imgur.com/oauth2/authorize?client_id=\(Secrets.imgurClientID)&response_type=token")!
    private let callbackScheme = "mac2imgur"

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.windows.first ?? NSWindow()
    }

    /// Launches the Imgur authorization page and returns tokens on success.
    func login() async throws -> OAuthTokens {
        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: error ?? OAuthError.invalidResponse)
                }
            }
            session.presentationContextProvider = self
            session.start()
        }
        return try Self.parseTokens(from: callbackURL)
    }

    static func parseTokens(from url: URL) throws -> OAuthTokens {
        // Imgur returns tokens in the URL fragment, e.g.
        // mac2imgur://oauth#access_token=...&refresh_token=...&account_username=...
        guard let fragment = url.fragment else { throw OAuthError.invalidResponse }
        var dict: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                dict[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
            }
        }
        guard let access = dict["access_token"], let refresh = dict["refresh_token"] else {
            throw OAuthError.invalidResponse
        }
        return OAuthTokens(
            accessToken: access,
            refreshToken: refresh,
            accountUsername: dict["account_username"]
        )
    }
}
