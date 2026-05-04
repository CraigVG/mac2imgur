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

/// Watches macOS for new screenshots via Spotlight metadata.
///
/// Uses `kMDItemIsScreenCapture` which is the same attribute the Screenshot.app
/// and Spotlight rely on. More reliable than path-watching because it survives
/// users moving the screenshot folder, renaming files, or Apple changing the
/// default location.
public final class ScreenshotMonitor: @unchecked Sendable {
    public typealias Handler = @Sendable (URL) -> Void

    public static let spotlightPredicate = NSPredicate(format: "kMDItemIsScreenCapture = 1")

    public static let acceptableExtensions: Set<String> = ["png", "jpg", "jpeg"]

    public static func isAcceptableScreenshot(filename: String) -> Bool {
        let ext = (filename as NSString).pathExtension.lowercased()
        return acceptableExtensions.contains(ext)
    }

    private let query: NSMetadataQuery
    private let handler: Handler
    private var notifiedURLs = Set<URL>()
    private let queue = DispatchQueue(label: "com.mileswd.mac2imgur.screenshotmonitor")

    public init(handler: @escaping Handler) {
        self.handler = handler
        self.query = NSMetadataQuery()
        self.query.predicate = Self.spotlightPredicate
        self.query.searchScopes = [NSMetadataQueryUserHomeScope]
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        query.stop()
    }

    public func start() {
        query.start()
    }

    public func stop() {
        query.stop()
    }

    @objc private func handleUpdate(_ note: Notification) {
        let added = (note.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]) ?? []
        for item in added {
            guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { continue }
            let url = URL(fileURLWithPath: path)
            queue.sync {
                guard !notifiedURLs.contains(url) else { return }
                guard Self.isAcceptableScreenshot(filename: url.lastPathComponent) else { return }
                notifiedURLs.insert(url)
                handler(url)
            }
        }
    }
}
