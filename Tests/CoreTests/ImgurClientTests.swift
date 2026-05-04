import Testing
import Foundation
@testable import Core

@Suite("ImgurClient")
struct ImgurClientTests {
    @Test("Anonymous upload returns parsed UploadedImage on 200")
    func anonymousUploadHappyPath() async throws {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes
        let responseJSON = """
        {
          "data": {
            "id": "abc123",
            "deletehash": "del456",
            "link": "https://i.imgur.com/abc123.png"
          },
          "success": true,
          "status": 200
        }
        """.data(using: .utf8)!

        let session = MockURLSession(responseData: responseJSON, statusCode: 200)
        let client = ImgurClient(urlSession: session)
        let result = try await client.uploadAnonymous(data: imageData, filename: "test.png")
        #expect(result.id == "abc123")
        #expect(result.link.absoluteString == "https://i.imgur.com/abc123.png")
        #expect(result.deleteHash == "del456")
    }

    @Test("4xx response throws .http with status code")
    func http4xxError() async {
        let body = #"{"data":{"error":"Bad request"},"success":false,"status":400}"#.data(using: .utf8)!
        let session = MockURLSession(responseData: body, statusCode: 400)
        let client = ImgurClient(urlSession: session)
        await #expect(throws: ImgurError.self) {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
        }
    }

    @Test("429 maps to .rateLimited")
    func rateLimited() async {
        let session = MockURLSession(responseData: Data(), statusCode: 429)
        let client = ImgurClient(urlSession: session)
        do {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
            Issue.record("Expected throw")
        } catch ImgurError.rateLimited {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("5xx response throws .http")
    func http5xx() async {
        let session = MockURLSession(responseData: Data(), statusCode: 503)
        let client = ImgurClient(urlSession: session)
        do {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
            Issue.record("Expected throw")
        } catch let ImgurError.http(statusCode, _) {
            #expect(statusCode == 503)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("Malformed JSON throws .decoding")
    func malformedJSON() async {
        let session = MockURLSession(responseData: Data("garbage".utf8), statusCode: 200)
        let client = ImgurClient(urlSession: session)
        do {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
            Issue.record("Expected throw")
        } catch ImgurError.decoding {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("Multipart body contains image bytes and correct headers")
    func multipartBodyEncoding() async throws {
        let captureSession = CapturingURLSession(
            responseData: """
                {"data":{"id":"x","link":"https://i.imgur.com/x.png","deletehash":"d"},"success":true,"status":200}
            """.data(using: .utf8)!
        )
        let client = ImgurClient(urlSession: captureSession)
        let imageBytes = Data([0xAB, 0xCD, 0xEF])
        _ = try await client.uploadAnonymous(data: imageBytes, filename: "thing.png")

        let body = captureSession.captured!.httpBody!
        let header = #"Content-Disposition: form-data; name="image"; filename="thing.png""#.data(using: .utf8)!
        #expect(body.range(of: header) != nil)
        #expect(body.range(of: imageBytes) != nil)
    }

    @Test("Authorization header is set to Client-ID")
    func authHeader() async throws {
        let captureSession = CapturingURLSession(
            responseData: """
                {"data":{"id":"x","link":"https://i.imgur.com/x.png","deletehash":"d"},"success":true,"status":200}
            """.data(using: .utf8)!
        )
        let client = ImgurClient(urlSession: captureSession)
        _ = try await client.uploadAnonymous(data: Data([0x01]), filename: "a.png")
        let auth = captureSession.captured!.value(forHTTPHeaderField: "Authorization")
        #expect(auth == "Client-ID \(Secrets.imgurClientID)")
    }
}

// Test helpers
final class MockURLSession: ImgurURLSession {
    let responseData: Data
    let statusCode: Int
    init(responseData: Data, statusCode: Int) {
        self.responseData = responseData
        self.statusCode = statusCode
    }
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }
}

final class CapturingURLSession: ImgurURLSession, @unchecked Sendable {
    let responseData: Data
    var captured: URLRequest?
    init(responseData: Data) { self.responseData = responseData }
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        captured = request
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (responseData, response)
    }
}
