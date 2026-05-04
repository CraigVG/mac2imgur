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

struct AboutSettingsView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("mac2imgur")
                .font(.title2)
                .fontWeight(.medium)
            Text(version)
                .foregroundStyle(.secondary)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("A modernized fork of mac2imgur (2013–2018) by Miles Wu, maintained by Craig Vander Galien.")
                    .font(.callout)
                Link("github.com/CraigVG/mac2imgur",
                     destination: URL(string: "https://github.com/CraigVG/mac2imgur")!)
                    .font(.callout)
                Link("Original by Miles Wu",
                     destination: URL(string: "https://github.com/mileswd/mac2imgur")!)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding(20)
    }
}
