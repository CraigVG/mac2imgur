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

import Foundation

public struct OAuthTokens: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let accountUsername: String?

    public init(accessToken: String, refreshToken: String, accountUsername: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accountUsername = accountUsername
    }
}

public enum OAuthError: Error, Equatable, Sendable {
    case refreshExpired
    case http(Int)
    case decoding(String)
    case invalidResponse
}

/// Pure-logic OAuth helper. The interactive web-auth flow lives in App/Auth/
/// (uses ASWebAuthenticationSession which is AppKit-bound).
public struct OAuthCoordinator: Sendable {
    private let urlSession: ImgurURLSession
    private let tokenURL: URL

    public init(
        urlSession: ImgurURLSession = URLSession.shared,
        tokenURL: URL = URL(string: "https://api.imgur.com/oauth2/token")!
    ) {
        self.urlSession = urlSession
        self.tokenURL = tokenURL
    }

    /// Exchange a refresh token for a fresh access token.
    public func refresh(refreshToken: String) async throws -> OAuthTokens {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "refresh_token=\(refreshToken)",
            "client_id=\(Secrets.imgurClientID)",
            "client_secret=\(Secrets.imgurClientSecret)",
            "grant_type=refresh_token"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw OAuthError.refreshExpired
        }
        guard (200..<300).contains(http.statusCode) else {
            throw OAuthError.http(http.statusCode)
        }
        struct ResponsePayload: Decodable {
            let access_token: String
            let refresh_token: String
            let account_username: String?
        }
        do {
            let payload = try JSONDecoder().decode(ResponsePayload.self, from: data)
            return OAuthTokens(
                accessToken: payload.access_token,
                refreshToken: payload.refresh_token,
                accountUsername: payload.account_username
            )
        } catch {
            throw OAuthError.decoding(error.localizedDescription)
        }
    }
}
