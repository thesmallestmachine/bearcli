# BearCLI

A lightweight Swift command-line tool that reads and searches [Bear](https://bear.app) notes from the terminal.

BearCLI bridges Bear's x-callback-url API with stdout, making it possible for automation tools (like [Claude Code](https://claude.com/claude-code)) to programmatically read note content.

## Requirements

- macOS 12+
- Swift 5.9+
- [Bear](https://bear.app) (Pro) with API token

## Installation

```bash
git clone https://github.com/WayneAtHT/bearcli.git
cd bearcli
./build.sh
```

The build script compiles the source, packages it into an app bundle at `~/development/bear-cli/BearCLI.app/`, and registers the URL scheme with macOS Launch Services.

## Getting Your Bear API Token

In Bear: **Help > Advanced > API Token > Copy Token**

## Usage

```bash
BEAR=~/development/bear-cli/BearCLI.app/Contents/MacOS/bear-cli

# Read a note by title
$BEAR open-note --title "My Note" --token YOUR_TOKEN

# Read a note by ID
$BEAR open-note --id NOTE_UUID --token YOUR_TOKEN

# Search notes by keyword
$BEAR search --term "search query" --token YOUR_TOKEN

# Search notes by tag
$BEAR search --tag "work/projects" --token YOUR_TOKEN

# List all tags
$BEAR tags --token YOUR_TOKEN
```

### Options

| Option | Description |
|---|---|
| `--token` | Bear API token (required) |
| `--title` | Note title (for `open-note`) |
| `--id` | Note UUID (for `open-note`) |
| `--term` | Search keyword (for `search`) |
| `--tag` | Tag name (for `search`) |
| `--timeout` | Seconds to wait for callback (default: 10) |
| `--json` | Output raw JSON key-value pairs |

## How It Works

Bear uses Apple's [x-callback-url](https://x-callback-url.com) protocol for inter-app communication. CLI tools can't normally receive these callbacks. BearCLI solves this by:

1. Packaging itself as a minimal macOS app bundle with a registered URL scheme (`bear-cli-callback://`)
2. Sending a request to Bear with the callback URL pointing back to itself
3. Running an `NSApplication` event loop to receive the callback
4. Parsing the response parameters and printing to stdout

```
BearCLI ──bear://x-callback-url/...──> Bear
BearCLI <──bear-cli-callback://success?...── Bear
   │
   └──> stdout
```

## Project Structure

```
bearcli/
├── Package.swift           # Swift Package Manager manifest
├── build.sh                # Build and install script
├── OVERVIEW.md             # Detailed architecture docs
├── Sources/
│   └── BearCLI/
│       ├── main.swift      # All application code
│       └── Info.plist      # URL scheme declaration
├── LICENSE
└── README.md
```

## License

MIT
