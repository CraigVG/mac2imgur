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
//
// Copyright © 2026 Craig Vander Galien
// Originally based on mac2imgur © 2013-2018 Miles Wu (https://github.com/mileswd/mac2imgur)

import Foundation

public struct UploadedImage: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let link: URL
    public let deleteHash: String?
    public let uploadedAt: Date
    public let originalFilename: String?

    public init(
        id: String,
        link: URL,
        deleteHash: String?,
        uploadedAt: Date,
        originalFilename: String?
    ) {
        self.id = id
        self.link = link
        self.deleteHash = deleteHash
        self.uploadedAt = uploadedAt
        self.originalFilename = originalFilename
    }
}
