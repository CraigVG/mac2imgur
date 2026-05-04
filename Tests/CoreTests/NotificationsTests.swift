import Testing
import Foundation
@testable import Core

@Suite("Notifications")
struct NotificationsTests {
    @Test("Builds upload-success notification content")
    func uploadSuccessContent() {
        let content = Notifications.uploadSuccessContent(link: URL(string: "https://i.imgur.com/abc.png")!)
        #expect(content.title == "Image Uploaded")
        #expect(content.body.contains("https://i.imgur.com/abc.png"))
    }

    @Test("Builds upload-failure notification content")
    func uploadFailureContent() {
        let content = Notifications.uploadFailureContent(reason: "Rate limited")
        #expect(content.title == "Upload Failed")
        #expect(content.body.contains("Rate limited"))
    }
}
