import Testing
import Foundation
@testable import Core

@Suite("OAuthCoordinator")
struct OAuthCoordinatorTests {
    @Test("Refresh succeeds with new tokens on 200")
    func refreshHappyPath() async throws {
        let response = """
            {"access_token":"new_access","refresh_token":"new_refresh","token_type":"bearer","expires_in":3600,"account_id":42,"account_username":"craig"}
        """.data(using: .utf8)!
        let session = MockURLSession(responseData: response, statusCode: 200)
        let coord = OAuthCoordinator(urlSession: session)
        let tokens = try await coord.refresh(refreshToken: "old_refresh")
        #expect(tokens.accessToken == "new_access")
        #expect(tokens.refreshToken == "new_refresh")
        #expect(tokens.accountUsername == "craig")
    }

    @Test("Refresh on 401 throws .refreshExpired")
    func refreshExpired() async {
        let session = MockURLSession(responseData: Data(), statusCode: 401)
        let coord = OAuthCoordinator(urlSession: session)
        do {
            _ = try await coord.refresh(refreshToken: "stale")
            Issue.record("Expected throw")
        } catch OAuthError.refreshExpired {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("Refresh with malformed JSON throws .decoding")
    func malformedRefresh() async {
        let session = MockURLSession(responseData: Data("garbage".utf8), statusCode: 200)
        let coord = OAuthCoordinator(urlSession: session)
        do {
            _ = try await coord.refresh(refreshToken: "x")
            Issue.record("Expected throw")
        } catch OAuthError.decoding {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }
}
