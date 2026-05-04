import Testing
import Foundation
@testable import Core

@Suite("UploadHistory")
struct UploadHistoryTests {
    private func suite() -> UserDefaults {
        UserDefaults(suiteName: "test-history-\(UUID().uuidString)")!
    }

    @Test("Newly created history is empty")
    func startsEmpty() {
        let history = UploadHistory(defaults: suite(), maxCount: 5)
        #expect(history.uploads.isEmpty)
    }

    @Test("Add appends to the front")
    func addAppendsToFront() {
        let history = UploadHistory(defaults: suite(), maxCount: 5)
        let img = UploadedImage(id: "a", link: URL(string: "https://i.imgur.com/a.png")!, deleteHash: nil, uploadedAt: Date(), originalFilename: nil)
        history.add(img)
        #expect(history.uploads.first?.id == "a")
    }

    @Test("Eviction caps the list at maxCount")
    func eviction() {
        let history = UploadHistory(defaults: suite(), maxCount: 3)
        for i in 0..<5 {
            history.add(UploadedImage(id: "\(i)", link: URL(string: "https://i.imgur.com/\(i).png")!, deleteHash: nil, uploadedAt: Date(), originalFilename: nil))
        }
        #expect(history.uploads.count == 3)
        #expect(history.uploads.map(\.id) == ["4", "3", "2"])
    }

    @Test("Persistence round-trips across instances")
    func persistence() {
        let s = suite()
        let h1 = UploadHistory(defaults: s, maxCount: 5)
        h1.add(UploadedImage(id: "z", link: URL(string: "https://i.imgur.com/z.png")!, deleteHash: nil, uploadedAt: Date(), originalFilename: nil))
        let h2 = UploadHistory(defaults: s, maxCount: 5)
        #expect(h2.uploads.first?.id == "z")
    }
}
