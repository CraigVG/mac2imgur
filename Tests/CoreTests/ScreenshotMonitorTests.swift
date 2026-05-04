import Testing
import Foundation
@testable import Core

@Suite("ScreenshotMonitor")
struct ScreenshotMonitorTests {
    @Test("Spotlight predicate matches kMDItemIsScreenCapture true")
    func predicateString() {
        let predicate = ScreenshotMonitor.spotlightPredicate
        #expect(predicate.predicateFormat.contains("kMDItemIsScreenCapture"))
    }

    @Test("isAcceptableScreenshot returns true for png/jpg/jpeg")
    func acceptsImageExtensions() {
        #expect(ScreenshotMonitor.isAcceptableScreenshot(filename: "Screenshot.png"))
        #expect(ScreenshotMonitor.isAcceptableScreenshot(filename: "shot.jpg"))
        #expect(ScreenshotMonitor.isAcceptableScreenshot(filename: "shot.JPEG"))
    }

    @Test("isAcceptableScreenshot rejects non-images")
    func rejectsNonImages() {
        #expect(!ScreenshotMonitor.isAcceptableScreenshot(filename: "doc.pdf"))
        #expect(!ScreenshotMonitor.isAcceptableScreenshot(filename: "movie.mov"))
    }
}
