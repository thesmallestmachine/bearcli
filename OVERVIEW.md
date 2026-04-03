# BearCLI Overview

A lightweight Swift CLI tool that reads and searches [Bear](https://bear.app) notes from the command line. It bridges Bear's x-callback-url API with stdout, allowing automation tools (like Claude Code) to programmatically access note content.

## Problem

Bear uses Apple's x-callback-url protocol for inter-app communication. This works great between GUI apps, but CLI tools can't receive callbacks — the response goes nowhere. BearCLI solves this by acting as a minimal macOS app that registers a custom URL scheme, sends requests to Bear, receives the callback, and prints the result to stdout.

## How It Works

```
┌─────────┐    bear://x-callback-url/...    ┌──────┐
│ BearCLI │ ──────────────────────────────▶  │ Bear │
│  (CLI)  │                                  │ App  │
│         │  ◀──────────────────────────────  │      │
└─────────┘  bear-cli-callback://success?... └──────┘
     │
     ▼
   stdout
```

1. BearCLI starts as an accessory app (no dock icon) and registers as the handler for the `bear-cli-callback://` URL scheme
2. It constructs a Bear x-callback-url with `x-success=bear-cli-callback://success` and `x-error=bear-cli-callback://error`
3. Opens the URL via `NSWorkspace`, which launches Bear's handler
4. Bear processes the request and calls back to `bear-cli-callback://success?param=value...`
5. macOS routes the callback to BearCLI via the registered URL scheme
6. BearCLI's `NSApplicationDelegate` receives the Apple Event, parses the URL parameters, prints to stdout, and exits

## App Bundle Requirement

macOS only routes URL scheme callbacks to registered app bundles (not bare executables). That's why BearCLI is packaged as `BearCLI.app/` with an `Info.plist` that declares the `bear-cli-callback` URL scheme. The app bundle must be registered with Launch Services (`lsregister`) for macOS to know about it.

## Project Structure

```
~/Developer/bearcli/              # Source code (development)
├── Package.swift                 # Swift Package Manager manifest
├── build.sh                      # Build + install script
├── OVERVIEW.md                   # This file
├── .claude/
│   └── CLAUDE.md                 # Claude Code project instructions
└── Sources/
    └── BearCLI/
        ├── main.swift            # All application code
        └── Info.plist            # URL scheme registration (bundled into .app)

~/development/bear-cli/           # Installed executable
└── BearCLI.app/
    └── Contents/
        ├── Info.plist            # Copied from source during build
        └── MacOS/
            └── bear-cli          # The compiled binary
```

## Code Structure (main.swift)

The code is in a single file with four sections:

### 1. CallbackHandler (NSApplicationDelegate)
- Registers for Apple Events in `applicationWillFinishLaunching`
- `handleURL` receives the callback, parses parameters, stops the run loop
- `parseQueryParameters` extracts key-value pairs from the callback URL

### 2. BearAPI
- Constructs Bear x-callback-url requests for each action
- `openNote(title:id:)` — read a single note
- `search(term:tag:)` — search notes
- `tags()` — list all tags
- Each method injects the callback scheme, token, and `show_window=no`

### 3. CLI (parseArgs / printUsage)
- Simple argument parser supporting `--key value` and `--flag` patterns
- No external dependencies

### 4. Main
- Parses args, constructs the Bear URL
- Creates an `NSApplication` with `.accessory` activation policy (invisible)
- Opens the Bear URL, runs the app loop
- When the callback arrives, outputs results and exits

## Bear API Reference

All actions require the `--token` parameter (Bear API token).

### open-note
Read a single note's content.

```bash
bear-cli open-note --title "Note Title" --token TOKEN
bear-cli open-note --id NOTE_UUID --token TOKEN
```

**Returns:** The full markdown text of the note.

### search
Search for notes by keyword or tag.

```bash
bear-cli search --term "search query" --token TOKEN
bear-cli search --tag "work/localdev" --token TOKEN
```

**Returns:** JSON array of matching notes with `title`, `identifier`, `tags`, `creationDate`, `modificationDate`, `pin`.

### tags
List all tags in the Bear database.

```bash
bear-cli tags --token TOKEN
```

**Returns:** JSON array of tag objects with `name`.

### Common Options
- `--timeout N` — seconds to wait for callback (default: 10)
- `--json` — output raw JSON key-value pairs from the callback

## Building

```bash
cd ~/Developer/bearcli
./build.sh
```

This compiles the Swift source, copies the binary into the app bundle at `~/development/bear-cli/BearCLI.app/`, and registers the URL scheme with Launch Services.

## Dependencies

- macOS 12+
- Swift 5.9+
- Bear (Pro) with API token enabled
