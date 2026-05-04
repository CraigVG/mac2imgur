import Testing
@testable import Core

@Suite("Smoke")
struct SmokeTests {
    @Test("Core module compiles and imports cleanly")
    func coreImports() {
        // If this test file builds, the Core module exports correctly.
        #expect(true)
    }
}
