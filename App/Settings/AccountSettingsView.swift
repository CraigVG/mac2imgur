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
//
// Copyright © 2026 Craig Vander Galien
// Originally based on mac2imgur © 2013-2018 Miles Wu (https://github.com/mileswd/mac2imgur)

import SwiftUI
import Core

struct AccountSettingsView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(ImgurOAuthFlow.self) private var oauthFlow
    @State private var status: String?
    @State private var loggingIn = false

    var body: some View {
        @Bindable var preferences = preferences

        Form {
            if preferences.refreshToken == nil {
                Section("Anonymous (current)") {
                    Text("Uploads are anonymous and the URL is copied to your clipboard. Anonymous uploads work normally.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Section("Imgur sign-in") {
                    Text("Imgur OAuth login is currently unavailable. The Imgur API key shipped with mac2imgur was revoked for OAuth (anonymous uploads still work), and Imgur appears to have closed public app registration. Sign-in will return when this is resolved upstream.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Button("Sign In to Imgur…") {
                        Task { await login() }
                    }
                    .disabled(true)
                }
            } else {
                Section("Signed in") {
                    Text("You are signed in to Imgur.")
                    Button("Sign Out") { signOut() }
                }
                Section("Album") {
                    TextField("Album ID (optional)", text: Binding(
                        get: { preferences.imgurAlbumID ?? "" },
                        set: { preferences.imgurAlbumID = $0.isEmpty ? nil : $0 }
                    ))
                    Text("Find your album ID at imgur.com/account → Albums.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let status {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func login() async {
        loggingIn = true
        defer { loggingIn = false }
        do {
            let tokens = try await oauthFlow.login()
            preferences.refreshToken = tokens.refreshToken
            status = nil
        } catch {
            status = "Sign-in failed: \(error.localizedDescription)"
        }
    }

    private func signOut() {
        preferences.refreshToken = nil
        preferences.imgurAlbumID = nil
        status = nil
    }
}
