import Testing
@testable import Core

@Suite("Secrets")
struct SecretsTests {
    @Test("Imgur client ID is the upstream-compatible value")
    func clientID() {
        #expect(Secrets.imgurClientID == "5867856c9027819")
    }

    @Test("Imgur client secret is set")
    func clientSecret() {
        #expect(!Secrets.imgurClientSecret.isEmpty)
    }
}
