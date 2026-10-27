import Cocoa
import FinderSync

/// Adds a "New File" submenu to Finder's menu for empty space in a folder window or on the Desktop.
final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Watch every folder, so the menu shows up everywhere, including the Desktop and external drives.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer else { return nil }

        let title = NSLocalizedString("New File", comment: "Finder menu item next to New Folder")
        let submenu = NSMenu(title: title)
        let builtIn = FileTemplate.builtIn
        let custom = FileTemplate.custom()
        for template in builtIn {
            submenu.addItem(menuItem(for: template))
        }
        if !custom.isEmpty {
            submenu.addItem(.separator())
            for template in custom {
                submenu.addItem(menuItem(for: template))
            }
        }

        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
        item.submenu = submenu

        let menu = NSMenu(title: "")
        menu.addItem(item)
        return menu
    }

    private func menuItem(for template: FileTemplate) -> NSMenuItem {
        // Finder copies these items into its own menu and only keeps the title and action,
        // so the action finds its template again by title.
        let item = NSMenuItem(title: template.title, action: #selector(createFile(_:)), keyEquivalent: "")
        item.image = NSImage(systemSymbolName: template.symbol, accessibilityDescription: nil)
        return item
    }

    @objc private func createFile(_ sender: NSMenuItem) {
        guard let folder = FIFinderSyncController.default().targetedURL(),
              let template = (FileTemplate.builtIn + FileTemplate.custom()).first(where: { $0.title == sender.title })
        else { return }

        do {
            let url = try template.create(in: folder)
            // Select the new file so pressing Return renames it.
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } catch {
            NSLog("FinderNewFile: could not create \(template.title) in \(folder.path): \(error)")
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }
}
