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

/// Minimal URLSession-shaped protocol so tests can inject mocks.
public protocol ImgurURLSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: ImgurURLSession {}

public enum ImgurError: Error, Equatable, Sendable {
    case invalidResponse
    case http(statusCode: Int, message: String?)
    case rateLimited
    case decoding(String)
}

public struct ImgurClient: Sendable {
    private let urlSession: ImgurURLSession
    private let baseURL: URL

    public init(
        urlSession: ImgurURLSession = URLSession.shared,
        baseURL: URL = URL(string: "https://api.imgur.com/3/")!
    ) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    /// Upload an image anonymously using the Client-ID credential.
    public func uploadAnonymous(data imageData: Data, filename: String) async throws -> UploadedImage {
        var request = URLRequest(url: baseURL.appendingPathComponent("image"))
        request.httpMethod = "POST"
        request.setValue("Client-ID \(Secrets.imgurClientID)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.makeMultipartBody(boundary: boundary, imageData: imageData, filename: filename)

        let (data, response) = try await urlSession.data(for: request)
        return try Self.parseUploadResponse(data: data, response: response, filename: filename)
    }

    /// Upload an image to the authenticated user's account using a bearer token.
    /// If `albumID` is non-nil the image is added to that album.
    public func uploadAuthenticated(
        data imageData: Data,
        filename: String,
        accessToken: String,
        albumID: String?
    ) async throws -> UploadedImage {
        var request = URLRequest(url: baseURL.appendingPathComponent("image"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.makeMultipartBody(
            boundary: boundary,
            imageData: imageData,
            filename: filename,
            albumID: albumID
        )

        let (data, response) = try await urlSession.data(for: request)
        return try Self.parseUploadResponse(data: data, response: response, filename: filename)
    }

    static func makeMultipartBody(
        boundary: String,
        imageData: Data,
        filename: String,
        albumID: String? = nil
    ) -> Data {
        var body = Data()
        if let albumID = albumID {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"album\"\r\n\r\n".data(using: .utf8)!)
            body.append(albumID.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    static func parseUploadResponse(data: Data, response: URLResponse, filename: String) throws -> UploadedImage {
        guard let http = response as? HTTPURLResponse else {
            throw ImgurError.invalidResponse
        }
        if http.statusCode == 429 {
            throw ImgurError.rateLimited
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw ImgurError.http(statusCode: http.statusCode, message: message)
        }
        struct Envelope: Decodable {
            let data: Payload
            struct Payload: Decodable {
                let id: String
                let link: String
                let deletehash: String?
            }
        }
        do {
            let envelope = try JSONDecoder().decode(Envelope.self, from: data)
            guard let url = URL(string: envelope.data.link) else {
                throw ImgurError.decoding("Invalid link URL: \(envelope.data.link)")
            }
            return UploadedImage(
                id: envelope.data.id,
                link: url,
                deleteHash: envelope.data.deletehash,
                uploadedAt: Date(),
                originalFilename: filename
            )
        } catch let error as ImgurError {
            throw error
        } catch {
            throw ImgurError.decoding(error.localizedDescription)
        }
    }
}
