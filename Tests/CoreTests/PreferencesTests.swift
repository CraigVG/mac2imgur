import Testing
import Foundation
@testable import Core

@Suite("Preferences")
struct PreferencesTests {
    /// CRITICAL: these key names are part of the public contract with the
    /// 2018 mac2imgur install on the user's Mac. Tier 3 SwiftUI views will
    /// use @AppStorage with these exact strings. Do not change without a
    /// migration plan.
    @Test("UserDefaults keys are the documented stable values")
    func keyStability() {
        #expect(PreferencesKey.refreshToken.rawValue == "RefreshToken")
        #expect(PreferencesKey.imgurAlbum.rawValue == "ImgurAlbum")
        #expect(PreferencesKey.deleteAfterUpload.rawValue == "DeleteAfterUpload")
        #expect(PreferencesKey.disableScreenshotDetection.rawValue == "DisableScreenshotDetection")
        #expect(PreferencesKey.requireConfirmation.rawValue == "RequireConfirmation")
        #expect(PreferencesKey.copyLinkToClipboard.rawValue == "CopyLinkToClipboard")
        #expect(PreferencesKey.clearClipboard.rawValue == "ClearClipboard")
    }

    @Test("Round-trips a string value through UserDefaults")
    func stringRoundTrip() {
        let suite = UserDefaults(suiteName: "test-string-\(UUID().uuidString)")!
        defer { suite.removePersistentDomain(forName: suite.dictionaryRepresentation().keys.first ?? "") }
        let prefs = Preferences(defaults: suite)
        prefs.imgurAlbumID = "myalbum"
        #expect(prefs.imgurAlbumID == "myalbum")
    }

    @Test("Round-trips a bool value")
    func boolRoundTrip() {
        let suite = UserDefaults(suiteName: "test-bool-\(UUID().uuidString)")!
        let prefs = Preferences(defaults: suite)
        prefs.deleteAfterUpload = true
        #expect(prefs.deleteAfterUpload == true)
        prefs.deleteAfterUpload = false
        #expect(prefs.deleteAfterUpload == false)
    }
}
