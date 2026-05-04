import Testing
import Foundation
@testable import Core

@Suite("UploadedImage")
struct UploadedImageTests {
    @Test("Initializes with all fields")
    func initialization() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let image = UploadedImage(
            id: "abc123",
            link: URL(string: "https://i.imgur.com/abc123.png")!,
            deleteHash: "def456",
            uploadedAt: date,
            originalFilename: "screenshot.png"
        )
        #expect(image.id == "abc123")
        #expect(image.link.absoluteString == "https://i.imgur.com/abc123.png")
        #expect(image.deleteHash == "def456")
        #expect(image.uploadedAt == date)
        #expect(image.originalFilename == "screenshot.png")
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = UploadedImage(
            id: "xyz",
            link: URL(string: "https://i.imgur.com/xyz.png")!,
            deleteHash: "hash",
            uploadedAt: Date(timeIntervalSince1970: 1_700_000_000),
            originalFilename: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UploadedImage.self, from: data)
        #expect(decoded == original)
    }
}
