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

        // Upload action (top of menu)
        let uploadItem = NSMenuItem(title: "Upload Images…", action: #selector(uploadImages), keyEquivalent: "u")
        uploadItem.target = self
        menu.addItem(uploadItem)

        menu.addItem(.separator())

        // Recent Uploads as a real submenu
        let recentItem = NSMenuItem(title: "Recent Uploads", action: nil, keyEquivalent: "")
        recentItem.submenu = buildRecentUploadsSubmenu()
        menu.addItem(recentItem)

        menu.addItem(.separator())

        // Imgur Account submenu
        let accountItem = NSMenuItem(title: "Imgur Account", action: nil, keyEquivalent: "")
        accountItem.submenu = buildAccountSubmenu()
        menu.addItem(accountItem)

        // Preferences (leaf — opens SwiftUI Settings scene)
        let prefsItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        // About submenu
        let aboutItem = NSMenuItem(title: "About", action: nil, keyEquivalent: "")
        aboutItem.submenu = buildAboutSubmenu()
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: "Quit mac2imgur",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    // MARK: Submenu builders

    private func buildRecentUploadsSubmenu() -> NSMenu {
        let submenu = NSMenu()
        if history.uploads.isEmpty {
            let none = NSMenuItem(title: "No Recent Uploads", action: nil, keyEquivalent: "")
            none.isEnabled = false
            submenu.addItem(none)
        } else {
            for upload in history.uploads.prefix(20) {
                let title = upload.originalFilename ?? upload.id
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.submenu = buildUploadActionSubmenu(for: upload)
                submenu.addItem(item)
            }
            submenu.addItem(.separator())
            let clear = NSMenuItem(title: "Clear Uploads", action: #selector(clearUploads), keyEquivalent: "")
            clear.target = self
            submenu.addItem(clear)
        }
        return submenu
    }

    private func buildUploadActionSubmenu(for upload: UploadedImage) -> NSMenu {
        let submenu = NSMenu()

        let copy = NSMenuItem(title: "Copy Image URL", action: #selector(copyRecentLink(_:)), keyEquivalent: "")
        copy.target = self
        copy.representedObject = upload.link
        submenu.addItem(copy)

        submenu.addItem(.separator())

        let view = NSMenuItem(title: "View Image", action: #selector(openURL(_:)), keyEquivalent: "")
        view.target = self
        view.representedObject = upload.link
        submenu.addItem(view)

        if let pageURL = URL(string: "https://imgur.com/\(upload.id)") {
            let viewPage = NSMenuItem(title: "View on Imgur", action: #selector(openURL(_:)), keyEquivalent: "")
            viewPage.target = self
            viewPage.representedObject = pageURL
            submenu.addItem(viewPage)
        }

        if let deleteHash = upload.deleteHash,
           let deleteURL = URL(string: "https://imgur.com/delete/\(deleteHash)") {
            submenu.addItem(.separator())
            let del = NSMenuItem(title: "Delete from Imgur…", action: #selector(openURL(_:)), keyEquivalent: "")
            del.target = self
            del.representedObject = deleteURL
            submenu.addItem(del)
        }

        return submenu
    }

    private func buildAccountSubmenu() -> NSMenu {
        let submenu = NSMenu()
        let signedIn = preferences.refreshToken != nil

        let status = NSMenuItem(
            title: signedIn ? "Signed in" : "Uploading anonymously",
            action: nil,
            keyEquivalent: "")
        status.isEnabled = false
        submenu.addItem(status)

        submenu.addItem(.separator())

        if signedIn {
            let signOutItem = NSMenuItem(title: "Sign Out", action: #selector(signOut), keyEquivalent: "")
            signOutItem.target = self
            submenu.addItem(signOutItem)
        } else {
            let signInItem = NSMenuItem(title: "Sign In to Imgur…", action: #selector(signIn), keyEquivalent: "")
            signInItem.target = self
            submenu.addItem(signInItem)
        }

        return submenu
    }

    private func buildAboutSubmenu() -> NSMenu {
        let submenu = NSMenu()

        let aboutPanel = NSMenuItem(
            title: "About mac2imgur",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: "")
        submenu.addItem(aboutPanel)

        if let projectURL = URL(string: "https://github.com/CraigVG/mac2imgur") {
            let project = NSMenuItem(title: "Project Website", action: #selector(openURL(_:)), keyEquivalent: "")
            project.target = self
            project.representedObject = projectURL
            submenu.addItem(project)
        }

        submenu.addItem(.separator())

        let checkUpdates = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: "")
        checkUpdates.target = self
        submenu.addItem(checkUpdates)

        if let info = Bundle.main.infoDictionary,
           let version = info["CFBundleShortVersionString"] as? String,
           let build = info["CFBundleVersion"] as? String {
            let versionItem = NSMenuItem(title: "Version \(version) (\(build))", action: nil, keyEquivalent: "")
            versionItem.isEnabled = false
            submenu.addItem(versionItem)
        }

        return submenu
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

    @objc private func openURL(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func clearUploads() {
        history.clear()
    }

    @objc private func checkForUpdates() {
        // SPUStandardUpdaterController exposes a checkForUpdates: action selector
        // that walks the responder chain. The AppDelegate owns the controller.
        NSApp.sendAction(Selector(("checkForUpdates:")), to: nil, from: nil)
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
