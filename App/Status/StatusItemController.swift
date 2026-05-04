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

import AppKit
import Core
import Observation
import UniformTypeIdentifiers

/// Owns the menu bar status item, builds its menu, animates the icon during
/// uploads, and accepts dragged image files.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let uploader: UploadHandler
    private let preferences: Preferences
    private let history: UploadHistory
    private let onSignIn: () -> Void
    private let onSignOut: () -> Void

    var activeUploadCount = 0 {
        didSet { updateIcon() }
    }

    init(
        uploader: UploadHandler,
        preferences: Preferences,
        history: UploadHistory,
        onSignIn: @escaping () -> Void,
        onSignOut: @escaping () -> Void
    ) {
        self.uploader = uploader
        self.preferences = preferences
        self.history = history
        self.onSignIn = onSignIn
        self.onSignOut = onSignOut
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        if let button = statusItem.button {
            button.window?.registerForDraggedTypes([.fileURL, .png, .tiff])
            button.window?.delegate = self
        }
        updateIcon()
    }

    private func updateIcon() {
        let name = activeUploadCount > 0 ? "StatusActive" : "StatusInactive"
        statusItem.button?.image = NSImage(named: name)
        statusItem.button?.image?.isTemplate = true
    }

    // MARK: NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let signedIn = preferences.refreshToken != nil
        let header = NSMenuItem(
            title: signedIn ? "Signed in to Imgur" : "Anonymous uploads",
            action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        if signedIn {
            menu.addItem(.init(title: "Sign Out", action: #selector(signOut), keyEquivalent: ""))
        } else {
            menu.addItem(.init(title: "Sign In to Imgur…", action: #selector(signIn), keyEquivalent: ""))
        }

        menu.addItem(.separator())

        let uploadItem = NSMenuItem(title: "Upload Images…", action: #selector(uploadImages), keyEquivalent: "u")
        uploadItem.target = self
        menu.addItem(uploadItem)

        if !history.uploads.isEmpty {
            menu.addItem(.separator())
            let recentHeader = NSMenuItem(title: "Recent Uploads", action: nil, keyEquivalent: "")
            recentHeader.isEnabled = false
            menu.addItem(recentHeader)

            for upload in history.uploads.prefix(10) {
                let title = upload.originalFilename ?? upload.id
                let item = NSMenuItem(title: title, action: #selector(copyRecentLink(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = upload.link
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let aboutItem = NSMenuItem(
            title: "About mac2imgur",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: "")
        menu.addItem(aboutItem)

        menu.addItem(.init(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // Wire targets where action selectors are on this controller
        for item in menu.items where item.target == nil && item.action != nil {
            switch item.action {
            case #selector(signIn), #selector(signOut), #selector(uploadImages),
                 #selector(copyRecentLink(_:)):
                item.target = self
            default:
                break
            }
        }
    }

    @objc private func signIn() { onSignIn() }
    @objc private func signOut() { onSignOut() }

    @objc private func openPreferences() {
        // Triggers the SwiftUI Settings { } scene
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func copyRecentLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }

    @objc private func uploadImages() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]
        if panel.runModal() == .OK {
            for url in panel.urls {
                Task { await uploader.upload(url: url, isScreenshot: false) }
            }
        }
    }
}

extension StatusItemController: NSWindowDelegate {
    nonisolated func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    nonisolated func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        var urls: [URL] = []
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            urls = fileURLs
        }
        if urls.isEmpty, let data = pasteboard.data(forType: .png) {
            // Pasted image data — write to temp file and upload
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("dropped-\(UUID().uuidString).png")
            try? data.write(to: tmp)
            urls = [tmp]
        }
        guard !urls.isEmpty else { return false }
        Task { @MainActor in
            for url in urls {
                await uploader.upload(url: url, isScreenshot: false)
            }
        }
        return true
    }
}
