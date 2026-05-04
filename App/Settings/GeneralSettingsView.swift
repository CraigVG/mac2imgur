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

import SwiftUI
import Core

struct GeneralSettingsView: View {
    @Environment(Preferences.self) private var preferences
    @State private var launchAtLogin = LoginItemService.isEnabled
    @State private var loginToggleError: String?

    var body: some View {
        @Bindable var preferences = preferences

        Form {
            Section("Launch") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            try LoginItemService.setEnabled(newValue)
                            loginToggleError = nil
                        } catch {
                            loginToggleError = error.localizedDescription
                            // Snap toggle back if registration failed
                            launchAtLogin = LoginItemService.isEnabled
                        }
                    }
                if let err = loginToggleError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Clipboard") {
                Toggle("Copy Link to Clipboard After Upload", isOn: $preferences.copyLinkToClipboard)
                Toggle("Clear Clipboard Before Setting Link", isOn: $preferences.clearClipboard)
                    .disabled(!preferences.copyLinkToClipboard)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
