# BearCLI Overview

## Why This Exists

[Bear](https://bear.app) is a beautiful notes app for macOS and iOS. It supports an [x-callback-url API](https://bear.app/faq/x-callback-url-scheme-documentation/) that lets other apps create, read, and modify notes programmatically. This works brilliantly between GUI apps — one app sends a URL, Bear processes it, and calls back with the result.

The problem is that **CLI tools can't receive callbacks**. The x-callback-url protocol relies on macOS routing a response URL back to a registered app bundle. A plain command-line script has no app bundle, no URL scheme registration, and no way to receive the response. You can *write* to Bear easily (`open "bear://x-callback-url/create?..."` fires and forgets), but *reading* — fetching note content, searching, listing tags — requires receiving Bear's callback.

BearCLI solves this by acting as a minimal, invisible macOS app. It registers a custom URL scheme (`bearcli-callback://`), sends requests to Bear, receives the callback response, prints the result to stdout, and exits. This turns Bear's callback-based API into a straightforward CLI interface.

This makes Bear fully accessible from the command line, shell scripts, and automation tools — read, search, create, and modify notes without ever opening the Bear GUI.

## How It Works

```
┌─────────┐    bear://x-callback-url/...    ┌──────┐
│ BearCLI │ ──────────────────────────────▶  │ Bear │
│  (CLI)  │                                  │ App  │
│         │  ◀──────────────────────────────  │      │
└─────────┘  bearcli-callback://success?... └──────┘
     │
     ▼
   stdout
```

1. BearCLI starts as an accessory app (no dock icon) and registers as the handler for the `bearcli-callback://` URL scheme
2. It constructs a Bear x-callback-url with `x-success=bearcli-callback://success` and `x-error=bearcli-callback://error`
3. Opens the URL via AppKit (Apple's GUI framework), which launches Bear's handler
4. Bear processes the request and calls back to `bearcli-callback://success?param=value...`
5. macOS routes the callback to BearCLI via the registered URL scheme
6. BearCLI's callback handler receives the Apple Event, parses the URL parameters, prints to stdout, and exits

## App Bundle Requirement

macOS only routes URL scheme callbacks to registered app bundles (not bare executables). That's why BearCLI is packaged as `bearcli.app/` with an `Info.plist` that declares the `bearcli-callback` URL scheme. The app bundle must be registered with Launch Services (`lsregister`) for macOS to know about it.

## Project Structure

```
~/Developer/bearcli/              # Source code (development)
├── Package.swift                 # Swift Package Manager manifest
├── build.sh                      # Build + install script
├── OVERVIEW.md                   # This file
├── .claude/
│   └── CLAUDE.md                 # Claude Code project instructions
└── Sources/
    └── bearcli/
        ├── main.swift            # All application code
        └── Info.plist            # URL scheme registration (bundled into .app)

~/development/bearcli/           # Installed executable
└── bearcli.app/
    └── Contents/
        ├── Info.plist            # Copied from source during build
        └── MacOS/
            └── bearcli          # The compiled binary
```

## Code Structure (main.swift)

The code is in a single file with four sections:

### 1. CallbackHandler (NSApplicationDelegate)
- Registers for Apple Events in `applicationWillFinishLaunching`
- `handleURL` receives the callback, parses parameters, stops the run loop
- `parseQueryParameters` extracts key-value pairs from the callback URL

### 2. BearAPI
- Constructs Bear x-callback-url requests for each of the 10 supported actions
- Read commands: `openNote`, `search`, `tags`, `openTag`, `untagged`, `todo`, `today`
- Write commands: `create`, `addText`, `grabURL`
- Each method injects the callback scheme, token, and `show_window=no`

### 3. CLI (parseArgs / printUsage)
- Simple argument parser supporting `--key value` and `--flag` patterns
- No external dependencies

### 4. Main
- Parses args, constructs the Bear URL
- Creates an invisible macOS app (no dock icon) using AppKit's event loop
- Opens the Bear URL, runs the app loop
- When the callback arrives, outputs results and exits

## Bear API Reference

All actions require the `--token` parameter (Bear API token, found in Bear: Help > Advanced > API Token).

### Read Commands

#### open-note
Read a single note's content.

```bash
bearcli open-note --title "Note Title" --token TOKEN
bearcli open-note --id NOTE_UUID --token TOKEN
```

**Returns:** The full markdown text of the note.

#### search
Search for notes by keyword or tag.

```bash
bearcli search --term "search query" --token TOKEN
bearcli search --tag "work/localdev" --token TOKEN
```

**Returns:** JSON array of matching notes with `title`, `identifier`, `tags`, `creationDate`, `modificationDate`, `pin`.

#### tags
List all tags in the Bear database.

```bash
bearcli tags --token TOKEN
```

**Returns:** JSON array of tag objects with `name`.

#### open-tag
List all notes with a specific tag.

```bash
bearcli open-tag --name "work/localdev" --token TOKEN
```

**Returns:** JSON array of matching notes with `title`, `identifier`, `tags`, `creationDate`, `modificationDate`, `pin`.

#### untagged
List notes that have no tags.

```bash
bearcli untagged --token TOKEN
bearcli untagged --search "filter text" --token TOKEN
```

**Returns:** JSON array of untagged notes. Use `--search` to filter results.

#### todo
List notes containing todo items.

```bash
bearcli todo --token TOKEN
bearcli todo --search "filter text" --token TOKEN
```

**Returns:** JSON array of notes with todos. Use `--search` to filter results.

#### today
List notes created or modified today.

```bash
bearcli today --token TOKEN
bearcli today --search "filter text" --token TOKEN
```

**Returns:** JSON array of today's notes. Use `--search` to filter results.

### Write Commands

#### create
Create a new note.

```bash
bearcli create --title "New Note" --text "Note content" --tags "tag1,tag2" --token TOKEN
bearcli create --title "Timestamped" --text "Content" --timestamp yes --token TOKEN
```

**Options:** `--title`, `--text`, `--tags` (comma-separated), `--pin yes`, `--timestamp yes`

**Returns:** `identifier` and `title` of the created note.

#### add-text
Append or prepend text to an existing note.

```bash
bearcli add-text --title "Note Title" --text "Appended text" --token TOKEN
bearcli add-text --id NOTE_ID --text "Prepended text" --mode prepend --token TOKEN
bearcli add-text --title "Note" --text "New line text" --mode append --new-line yes --token TOKEN
```

**Options:** `--title` or `--id` (required), `--text` (required), `--mode` (append/prepend/replace_all/replace), `--new-line yes`, `--tags`, `--exclude-trashed yes`, `--timestamp yes`

**Returns:** The full updated note text.

#### grab-url
Create a note from a web page.

```bash
bearcli grab-url --url "https://example.com" --token TOKEN
bearcli grab-url --url "https://example.com" --tags "reading" --pin yes --token TOKEN
```

**Options:** `--url` (required), `--tags` (comma-separated), `--pin yes`

**Returns:** `identifier` and `title` of the created note.

### Common Options
- `--timeout N` — seconds to wait for callback (default: 10)
- `--json` — output raw JSON key-value pairs from the callback

## Building

```bash
cd ~/Developer/bearcli
./build.sh
```

This compiles the Swift source, copies the binary into the app bundle at `~/development/bearcli/bearcli.app/`, and registers the URL scheme with Launch Services.

## Dependencies

- macOS 12+
- Swift 5.9+
- Bear (Pro) with API token enabled
