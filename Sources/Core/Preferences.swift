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
import Observation

/// UserDefaults keys used by mac2imgur.
///
/// CRITICAL: these raw values are the public contract with the 2018 mac2imgur
/// install on the user's Mac. SwiftUI views in a future Tier 3 rewrite will use
/// `@AppStorage` against these exact strings. Changing any value requires a
/// migration plan.
public enum PreferencesKey: String {
    case refreshToken = "RefreshToken"
    case imgurAlbum = "ImgurAlbum"
    case deleteAfterUpload = "DeleteAfterUpload"
    case disableScreenshotDetection = "DisableScreenshotDetection"
    case requireConfirmation = "RequireConfirmation"
    case copyLinkToClipboard = "CopyLinkToClipboard"
    case clearClipboard = "ClearClipboard"
}

@Observable
public final class Preferences {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var refreshToken: String? {
        get { defaults.string(forKey: PreferencesKey.refreshToken.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.refreshToken.rawValue) }
    }

    public var imgurAlbumID: String? {
        get { defaults.string(forKey: PreferencesKey.imgurAlbum.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.imgurAlbum.rawValue) }
    }

    public var deleteAfterUpload: Bool {
        get { defaults.bool(forKey: PreferencesKey.deleteAfterUpload.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.deleteAfterUpload.rawValue) }
    }

    public var disableScreenshotDetection: Bool {
        get { defaults.bool(forKey: PreferencesKey.disableScreenshotDetection.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.disableScreenshotDetection.rawValue) }
    }

    public var requireConfirmation: Bool {
        get { defaults.bool(forKey: PreferencesKey.requireConfirmation.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.requireConfirmation.rawValue) }
    }

    public var copyLinkToClipboard: Bool {
        get { defaults.bool(forKey: PreferencesKey.copyLinkToClipboard.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.copyLinkToClipboard.rawValue) }
    }

    public var clearClipboard: Bool {
        get { defaults.bool(forKey: PreferencesKey.clearClipboard.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.clearClipboard.rawValue) }
    }
}
