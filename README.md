# BearCLI

A lightweight Swift command-line tool that gives you full read and write access to [Bear](https://bear.app) notes from the terminal.

Bear's [x-callback-url API](https://bear.app/faq/x-callback-url-scheme-documentation/) makes writing notes from the command line easy — just `open "bear://x-callback-url/create?..."` and you're done. But reading notes back is a different story. The x-callback-url protocol sends responses to a registered app bundle, and plain CLI tools don't have one — the callback goes nowhere.

BearCLI solves this by acting as a minimal, invisible macOS app that registers a custom URL scheme, sends requests to Bear, receives the callback, prints the result to stdout, and exits. This turns Bear's entire callback-based API into a straightforward CLI interface, giving you full programmatic access to your notes from scripts, automation tools, and AI coding assistants like [Claude Code](https://claude.com/claude-code).

Bear must be running for BearCLI to work. If Bear is not already open, BearCLI will automatically start it, run the command, and close it when done. Note that Bear may briefly flash open and closed on screen when this happens, as macOS does not support running GUI apps like Bear in a fully headless mode.

## Requirements

- macOS 12+
- Swift 5.9+
- [Bear](https://bear.app) (Pro) with API token

## Installation

```bash
git clone https://github.com/thesmallestmachine/bearcli.git
cd bearcli
./build.sh
```

The build script compiles the source, packages it into an app bundle at `~/development/bearcli/bearcli.app/`, and registers the URL scheme with macOS Launch Services.

To make `bearcli` available as a command, add an alias to your `~/.zshrc`:

```bash
echo 'alias bearcli="$HOME/development/bearcli/bearcli.app/Contents/MacOS/bearcli"' >> ~/.zshrc
source ~/.zshrc
```

## Getting Your Bear API Token

In Bear: **Help > Advanced > API Token > Copy Token**

## Usage

```bash
# Read a note by title or ID
bearcli open-note --title "My Note" --token YOUR_TOKEN
bearcli open-note --id NOTE_UUID --token YOUR_TOKEN

# Search notes by keyword or tag
bearcli search --term "search query" --token YOUR_TOKEN
bearcli search --tag "work/projects" --token YOUR_TOKEN

# List all tags
bearcli tags --token YOUR_TOKEN

# List notes by tag
bearcli open-tag --name "work/projects" --token YOUR_TOKEN

# List untagged notes, notes with todos, or today's notes
bearcli untagged --token YOUR_TOKEN
bearcli todo --token YOUR_TOKEN
bearcli today --token YOUR_TOKEN

# Create a new note
bearcli create --title "New Note" --text "Content" --tags "tag1,tag2" --token YOUR_TOKEN

# Append text to an existing note
bearcli add-text --title "My Note" --text "Appended text" --mode append --new-line yes --token YOUR_TOKEN

# Create a note from a web page
bearcli grab-url --url "https://example.com" --tags "reading" --token YOUR_TOKEN
```

### Commands

| Command | Type | Description |
|---|---|---|
| `open-note` | Read | Read a note by title or ID |
| `search` | Read | Search notes by term or tag |
| `tags` | Read | List all tags |
| `open-tag` | Read | List notes with a specific tag |
| `untagged` | Read | List notes without tags |
| `todo` | Read | List notes containing todo items |
| `today` | Read | List notes created or modified today |
| `create` | Write | Create a new note |
| `add-text` | Write | Append or prepend text to a note |
| `grab-url` | Write | Create a note from a web page URL |

### Options

| Option | Description |
|---|---|
| `--token` | Bear API token (required) |
| `--title` | Note title (for `open-note`, `add-text`) |
| `--id` | Note UUID (for `open-note`, `add-text`) |
| `--term` | Search keyword (for `search`) |
| `--tag` | Tag name (for `search`) |
| `--name` | Tag name (for `open-tag`) |
| `--search` | Filter string (for `untagged`, `todo`, `today`) |
| `--text` | Text content (for `add-text`, `create`) |
| `--mode` | Insert mode: append, prepend, replace_all, replace (for `add-text`) |
| `--new-line` | If "yes", adds text on a new line (for `add-text`) |
| `--tags` | Comma-separated tags (for `add-text`, `grab-url`, `create`) |
| `--url` | Web page URL (for `grab-url`) |
| `--pin` | If "yes", pin the note (for `grab-url`, `create`) |
| `--timestamp` | If "yes", prepend date/time (for `add-text`, `create`) |
| `--exclude-trashed` | If "yes", exclude trashed notes (for `add-text`) |
| `--timeout` | Seconds to wait for callback (default: 10) |
| `--json` | Output raw JSON key-value pairs |

## How It Works

Bear uses Apple's [x-callback-url](https://x-callback-url.com) protocol for inter-app communication. CLI tools can't normally receive these callbacks because macOS only routes URL scheme responses to registered app bundles. BearCLI solves this by:

1. Packaging itself as a minimal macOS app bundle with a registered URL scheme (`bearcli-callback://`)
2. Sending a request to Bear with the callback URL pointing back to itself
3. Running a macOS event loop (using AppKit, Apple's GUI framework) to receive the callback
4. Parsing the response parameters and printing to stdout

The app runs invisibly — no dock icon, no windows — and exits as soon as the callback arrives.

```
BearCLI ──bear://x-callback-url/...──> Bear
BearCLI <──bearcli-callback://success?...── Bear
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
│   └── bearcli/
│       ├── main.swift      # All application code
│       └── Info.plist      # URL scheme declaration
├── LICENSE
└── README.md
```

## License

MIT
