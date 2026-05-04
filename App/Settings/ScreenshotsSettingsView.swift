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

struct ScreenshotsSettingsView: View {
    @Environment(Preferences.self) private var preferences

    var body: some View {
        @Bindable var preferences = preferences

        Form {
            Section("Detection") {
                Toggle("Disable Screenshot Detection", isOn: $preferences.disableScreenshotDetection)
                Text("When enabled, mac2imgur ignores new screenshots taken via ⌘⇧3, ⌘⇧4, etc. You can still upload manually.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("After Upload") {
                Toggle("Move Screenshot to Trash", isOn: $preferences.deleteAfterUpload)
                    .disabled(preferences.disableScreenshotDetection)
                Toggle("Require Confirmation Before Upload", isOn: $preferences.requireConfirmation)
                    .disabled(preferences.disableScreenshotDetection)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
