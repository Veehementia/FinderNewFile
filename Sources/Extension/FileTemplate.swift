import Foundation

/// A kind of file the "New File" menu can create.
struct FileTemplate {
    enum Source {
        case contents(String)
        case copy(URL)
    }

    let title: String
    /// Name of the new file before a number is added to keep it unique, e.g. "untitled.txt" (in English).
    let fileName: String
    let symbol: String
    let source: Source
    var executable = false

    /// Base name of new files, like Finder's "untitled folder".
    private static let untitled = NSLocalizedString("untitled", comment: "Base name of a new file")

    static let builtIn: [FileTemplate] = [
        FileTemplate(title: NSLocalizedString("Text File", comment: "File type in the New File menu"), fileName: "\(untitled).txt", symbol: "doc.text", source: .contents("")),
        FileTemplate(title: "Markdown", fileName: "\(untitled).md", symbol: "doc.plaintext", source: .contents("")),
        FileTemplate(
            title: NSLocalizedString("Rich Text", comment: "File type in the New File menu"), fileName: "\(untitled).rtf", symbol: "doc.richtext",
            source: .contents("{\\rtf1\\ansi\\ansicpg1252\\cocoartf2822\n}\n")
        ),
        FileTemplate(
            title: "HTML", fileName: "index.html", symbol: "globe",
            source: .contents("""
            <!doctype html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>Untitled</title>
            </head>
            <body>

            </body>
            </html>

            """)
        ),
        FileTemplate(title: "JSON", fileName: "\(untitled).json", symbol: "curlybraces", source: .contents("{}\n")),
        FileTemplate(title: "Python", fileName: "\(untitled).py", symbol: "chevron.left.forwardslash.chevron.right", source: .contents("")),
        FileTemplate(
            title: NSLocalizedString("Shell Script", comment: "File type in the New File menu"), fileName: "\(untitled).sh", symbol: "terminal",
            source: .contents("#!/bin/zsh\n\n"), executable: true
        ),
        FileTemplate(title: "Swift", fileName: "\(untitled).swift", symbol: "swift", source: .contents("")),
        FileTemplate(title: NSLocalizedString("Empty File", comment: "File type in the New File menu"), fileName: untitled, symbol: "doc", source: .contents("")),
    ]

    /// Files the user put in the templates folder, e.g. an empty Word or Pages document.
    static func custom() -> [FileTemplate] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: templatesFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        )) ?? []
        return urls
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map { FileTemplate(title: $0.lastPathComponent, fileName: $0.lastPathComponent, symbol: "doc.on.doc", source: .copy($0)) }
    }

    static var templatesFolder: URL {
        realHomeDirectory.appendingPathComponent("Library/Application Support/FinderNewFile/Templates", isDirectory: true)
    }

    /// The user's home folder. In the sandbox, `homeDirectoryForCurrentUser` points into the container instead.
    private static var realHomeDirectory: URL {
        if let entry = getpwuid(getuid()), let dir = entry.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir), isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    /// Creates the file in `folder` without overwriting anything, and returns where it went.
    func create(in folder: URL) throws -> URL {
        let url = Self.uniqueURL(for: fileName, in: folder)
        switch source {
        case .contents(let text):
            try Data(text.utf8).write(to: url, options: .withoutOverwriting)
        case .copy(let templateURL):
            try FileManager.default.copyItem(at: templateURL, to: url)
        }
        if executable {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        }
        return url
    }

    /// "untitled.txt", then "untitled 2.txt", "untitled 3.txt", … like Finder's "untitled folder 2".
    private static func uniqueURL(for fileName: String, in folder: URL) -> URL {
        let ext = (fileName as NSString).pathExtension
        let base = (fileName as NSString).deletingPathExtension
        var candidate = folder.appendingPathComponent(fileName)
        var number = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(base) \(number)" : "\(base) \(number).\(ext)"
            candidate = folder.appendingPathComponent(name)
            number += 1
        }
        return candidate
    }
}
