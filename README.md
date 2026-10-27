# FinderNewFile

A small app for Apple Silicon Macs that adds **New File** to Finder's right-click menu, next to New Folder.

Right-click empty space in any Finder window or on the Desktop, choose **New File**, and pick a type:

Text File · Markdown · Rich Text · HTML · JSON · Python · Shell Script · Swift · Empty File

The file is named `untitled.txt` (then `untitled 2.txt`, …) and selected, so press **Return** to rename it. Shell scripts are made executable.

The app and the menu are in English and Italian, following your Mac's language. In Italian, new files are named `senza titolo.txt`, like Finder's `cartella senza titolo`.

## Your own templates

Open FinderNewFile and click **Open Templates Folder** (`~/Library/Application Support/FinderNewFile/Templates`). Any file you put there, like an empty Word, Excel or Pages document, shows up in the menu under its file name and is copied when you pick it.

## How it works

The app contains a [Finder Sync extension](https://developer.apple.com/documentation/findersync) that watches every folder and adds the menu to Finder's menu for empty space. Like every Finder extension it runs sandboxed, with an exception that lets it write into folders you can write to. The app itself only shows whether the extension is on, and you can quit it: the menu keeps working.

## Install

Requires macOS 13 or later and the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/Veehementia/FinderNewFile.git
cd FinderNewFile
./scripts/install.sh
```

The script builds the app, copies it to `/Applications`, turns on the Finder extension, relaunches Finder and opens the app. If the menu doesn't appear, click **Turn On…** in the app (System Settings → General → Login Items & Extensions → Finder).

The first time you create a file on the Desktop or in Documents or Downloads, macOS may ask to allow access to that folder.

To build without installing, run `./scripts/build.sh`. The app goes to `build/FinderNewFile.app`. To sign with your own certificate instead of ad-hoc:

```bash
SIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./scripts/install.sh
```

## Uninstall

```bash
pluginkit -r /Applications/FinderNewFile.app/Contents/PlugIns/FinderNewFileExtension.appex && rm -rf /Applications/FinderNewFile.app && killall Finder
```

## License

[MIT](LICENSE)
