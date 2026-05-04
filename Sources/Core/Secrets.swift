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

import Foundation

/// Imgur API credentials.
///
/// These are the upstream `mileswd/mac2imgur` keys, public on GitHub since 2018.
///
/// **Status as of v2.0.1 (May 2026):** Imgur partially revoked these keys:
/// - ✅ Anonymous uploads via `POST /3/image` with `Authorization: Client-ID …`
///       still work — verified live.
/// - ❌ OAuth via `/oauth2/authorize?client_id=…` returns Error 1024
///       ("Application not found"). Imgur's app-registration form at
///       `api.imgur.com/oauth2/addclient` 301-redirects to the homepage
///       regardless of auth state, suggesting public OAuth registration
///       has been closed. The Shell disables the Sign In UI accordingly.
///
/// If/when Imgur reopens registration or we obtain new keys, swap these
/// constants and re-enable the Sign In UI in
/// `App/Status/StatusItemController.swift` and
/// `App/Settings/AccountSettingsView.swift`.
public enum Secrets {
    public static let imgurClientID = "5867856c9027819"
    public static let imgurClientSecret = "7c2a63097cbb0f10f260291aab497be458388a64"
}
