import AppKit
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let statusIcon = NSImageView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let extensionButton = NSButton(title: "", target: nil, action: nil)

    private static let contentWidth: CGFloat = 540
    private static let margin: CGFloat = 22

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildWindow()
        refreshStatus()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshStatus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func buildMainMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: NSLocalizedString("Quit FinderNewFile", comment: "App menu item"),
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
        )
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        let mainMenu = NSMenu()
        mainMenu.addItem(appItem)
        NSApp.mainMenu = mainMenu
    }

    private func buildWindow() {
        let innerWidth = Self.contentWidth - 2 * Self.margin

        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let title = NSTextField(labelWithString: "FinderNewFile")
        title.font = .boldSystemFont(ofSize: 18)
        let subtitle = wrappingLabel(
            NSLocalizedString("Right-click empty space in any Finder window and choose New File.", comment: "Window subtitle"),
            width: innerWidth - 56 - 14
        )
        subtitle.textColor = .secondaryLabelColor
        let header = NSStackView(views: [icon, stack([title, subtitle], spacing: 2)])
        header.spacing = 14

        statusIcon.setContentHuggingPriority(.required, for: .horizontal)
        // The label takes the spare width, which pushes the button to the right edge.
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        extensionButton.target = self
        extensionButton.action = #selector(openExtensionSettings)
        extensionButton.bezelStyle = .rounded
        extensionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        let statusRow = NSStackView(views: [statusIcon, statusLabel, extensionButton])
        statusRow.distribution = .fill
        statusRow.spacing = 8

        let templatesButton = NSButton(
            title: NSLocalizedString("Open Templates Folder", comment: "Button"),
            target: self, action: #selector(openTemplatesFolder)
        )
        templatesButton.bezelStyle = .rounded
        templatesButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        templatesButton.setContentHuggingPriority(.required, for: .horizontal)
        let templatesText = wrappingLabel(
            NSLocalizedString(
                "Put any file in the templates folder, like an empty Word, Excel or Pages document, and it shows up in the New File menu too.",
                comment: "Explains the templates folder"
            ),
            width: innerWidth - 2 * CardView.padding - templatesButton.intrinsicContentSize.width - 16
        )
        let templatesRow = NSStackView(views: [templatesText, templatesButton])
        templatesRow.spacing = 16

        let footer = wrappingLabel(
            NSLocalizedString("You can quit this app: the menu keeps working while it's closed.", comment: "Window footer"),
            width: innerWidth
        )
        footer.textColor = .secondaryLabelColor
        footer.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

        let cards = [CardView(statusRow), CardView(templatesRow)]
        let content = stack([header] + cards + [footer], spacing: 16)
        content.edgeInsets = NSEdgeInsets(top: Self.margin, left: Self.margin, bottom: Self.margin, right: Self.margin)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.widthAnchor.constraint(equalToConstant: Self.contentWidth).isActive = true
        for card in cards {
            card.widthAnchor.constraint(equalToConstant: innerWidth).isActive = true
        }

        window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "FinderNewFile"
        window.contentView = content
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func refreshStatus() {
        let enabled = FIFinderSyncController.isExtensionEnabled
        statusIcon.image = NSImage(
            systemSymbolName: enabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
            accessibilityDescription: nil
        )
        statusIcon.contentTintColor = enabled ? .systemGreen : .systemOrange
        statusLabel.stringValue = enabled
            ? NSLocalizedString("The Finder extension is on.", comment: "Status")
            : NSLocalizedString("The Finder extension is off.", comment: "Status")
        extensionButton.title = enabled
            ? NSLocalizedString("Extension Settings…", comment: "Button")
            : NSLocalizedString("Turn On…", comment: "Button")
    }

    @objc private func openExtensionSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    @objc private func openTemplatesFolder() {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/FinderNewFile/Templates", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(folder)
    }

    private func stack(_ views: [NSView], spacing: CGFloat) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = spacing
        return stack
    }

    private func wrappingLabel(_ text: String, width: CGFloat) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.isSelectable = false
        label.preferredMaxLayoutWidth = width
        return label
    }
}

/// A rounded panel around a row of controls, sized by its content.
final class CardView: NSView {
    static let padding: CGFloat = 14

    init(_ content: NSView) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.padding),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.padding),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func draw(_ dirtyRect: NSRect) {
        // Drawn here rather than with a layer, so the colors follow light and dark mode.
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
        NSColor.controlBackgroundColor.setFill()
        path.fill()
        NSColor.separatorColor.setStroke()
        path.stroke()
    }
}
