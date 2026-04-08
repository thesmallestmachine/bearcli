# Plan: Bear Notes CLI Helper

## Context
Bear notes uses x-callback-url for inter-app communication. Claude can create notes via `open "bear://..."` but can't **read** note content back because the response is sent to a callback URL, not stdout. We need a small Swift CLI tool that sends an x-callback-url to Bear, waits for the response, and outputs the note content to stdout.

## Approach: Build on xcall pattern
Rather than reinventing the wheel, we'll build a lightweight Swift CLI tool called `bear-cli` that:

1. Registers a temporary custom URL scheme to receive callbacks
2. Sends x-callback-url requests to Bear (with x-success pointing to our scheme)
3. Waits (with timeout) for Bear to call back
4. Parses the callback parameters and outputs note content to stdout

This follows the same pattern as the open-source [xcall](https://github.com/martinfinke/xcall) tool but purpose-built for Bear.

## Implementation

### Structure
- Single Swift file as a macOS command-line tool with an embedded app bundle
- Needs an `Info.plist` to register a custom URL scheme (e.g. `bear-cli-callback`)
- Location: `~/development/bear-cli/`

### How it works
1. CLI receives arguments like `bear-cli open-note --title "My Note" --token TOKEN`
2. Constructs Bear x-callback-url: `bear://x-callback-url/open-note?title=...&x-success=bear-cli-callback://success&x-error=bear-cli-callback://error`
3. Opens the URL via NSWorkspace
4. Runs an NSApplication run loop to receive the URL callback
5. macOS routes `bear-cli-callback://success?note=...&title=...` back to our app
6. Parses parameters, prints note content to stdout, exits

### Supported Bear actions
- `open-note` — read a note by title or ID
- `search` — search notes
- `tags` — list all tags

### Files to create
1. `~/development/bear-cli/Package.swift` — Swift package manifest
2. `~/development/bear-cli/Sources/BearCLI/main.swift` — main app logic
3. `~/development/bear-cli/Sources/BearCLI/Info.plist` — URL scheme registration
4. Build script / Makefile for easy compilation

### Integration with Claude
After building, add to `~/.claude/CLAUDE.md`:
- Path to `bear-cli` binary
- Usage examples for reading notes

## Verification
1. Build with `swift build`
2. Run `bear-cli open-note --title "test note" --token TOKEN`
3. Verify note content prints to stdout
4. Test from Claude Code session to confirm it works in this context
