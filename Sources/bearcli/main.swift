import AppKit
import Foundation

// MARK: - App Delegate for URL Scheme Handling

class CallbackHandler: NSObject, NSApplicationDelegate {
    var result: [String: String]?
    var error: String?
    var didReceiveCallback = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            error = "Failed to parse callback URL"
            didReceiveCallback = true
            return
        }

        let host = url.host ?? ""

        if host == "error" {
            let params = parseQueryParameters(url: url)
            error = params["errorMessage"] ?? params["error"] ?? "Unknown error from Bear"
        } else {
            result = parseQueryParameters(url: url)
        }

        didReceiveCallback = true
        NSApp.stop(nil)
        // Post a dummy event to unblock the run loop
        let dummyEvent = NSEvent.otherEvent(
            with: .applicationDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 0,
            data1: 0,
            data2: 0
        )
        if let event = dummyEvent {
            NSApp.postEvent(event, atStart: true)
        }
    }

    func parseQueryParameters(url: URL) -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }

        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value
        }
        return params
    }
}

// MARK: - Bear API

struct BearAPI {
    let token: String
    let callbackScheme = "bearcli-callback"

    func openNote(title: String? = nil, id: String? = nil) -> URL? {
        var params: [String: String] = [:]
        if let title = title { params["title"] = title }
        if let id = id { params["id"] = id }
        params["token"] = token
        params["show_window"] = "no"
        params["open_note"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "open-note", params: params)
    }

    func search(term: String? = nil, tag: String? = nil) -> URL? {
        var params: [String: String] = [:]
        if let term = term { params["term"] = term }
        if let tag = tag { params["tag"] = tag }
        params["token"] = token
        params["show_window"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "search", params: params)
    }

    func tags() -> URL? {
        var params: [String: String] = [:]
        params["token"] = token
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "tags", params: params)
    }

    func openTag(name: String) -> URL? {
        var params: [String: String] = [:]
        params["name"] = name
        params["token"] = token
        params["show_window"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "open-tag", params: params)
    }

    func untagged(search: String? = nil) -> URL? {
        var params: [String: String] = [:]
        if let search = search { params["search"] = search }
        params["token"] = token
        params["show_window"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "untagged", params: params)
    }

    func todo(search: String? = nil) -> URL? {
        var params: [String: String] = [:]
        if let search = search { params["search"] = search }
        params["token"] = token
        params["show_window"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "todo", params: params)
    }

    func today(search: String? = nil) -> URL? {
        var params: [String: String] = [:]
        if let search = search { params["search"] = search }
        params["token"] = token
        params["show_window"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "today", params: params)
    }

    func addText(id: String? = nil, title: String? = nil, text: String, mode: String? = nil, newLine: String? = nil, tags: String? = nil, excludeTrashed: String? = nil, timestamp: String? = nil) -> URL? {
        var params: [String: String] = [:]
        if let id = id { params["id"] = id }
        if let title = title { params["title"] = title }
        params["text"] = text
        if let mode = mode { params["mode"] = mode }
        if let newLine = newLine { params["new_line"] = newLine }
        if let tags = tags { params["tags"] = tags }
        if let excludeTrashed = excludeTrashed { params["exclude_trashed"] = excludeTrashed }
        if let timestamp = timestamp { params["timestamp"] = timestamp }
        params["token"] = token
        params["show_window"] = "no"
        params["open_note"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "add-text", params: params)
    }

    func grabURL(url: String, tags: String? = nil, pin: String? = nil) -> URL? {
        var params: [String: String] = [:]
        params["url"] = url
        if let tags = tags { params["tags"] = tags }
        if let pin = pin { params["pin"] = pin }
        params["show_window"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "grab-url", params: params)
    }

    func create(title: String? = nil, text: String? = nil, tags: String? = nil, pin: String? = nil, timestamp: String? = nil) -> URL? {
        var params: [String: String] = [:]
        if let title = title { params["title"] = title }
        if let text = text { params["text"] = text }
        if let tags = tags { params["tags"] = tags }
        if let pin = pin { params["pin"] = pin }
        if let timestamp = timestamp { params["timestamp"] = timestamp }
        params["show_window"] = "no"
        params["open_note"] = "no"
        params["x-success"] = "\(callbackScheme)://success"
        params["x-error"] = "\(callbackScheme)://error"
        return buildBearURL(action: "create", params: params)
    }

    private func buildBearURL(action: String, params: [String: String]) -> URL? {
        var components = URLComponents()
        components.scheme = "bear"
        components.host = "x-callback-url"
        components.path = "/\(action)"
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url
    }
}

// MARK: - CLI

func printUsage() {
    let usage = """
    bearcli: Read, search, and write Bear notes from the command line

    Usage:
      bearcli open-note --title "Note Title" --token TOKEN
      bearcli open-note --id NOTE_ID --token TOKEN
      bearcli search --term "search query" --token TOKEN
      bearcli search --tag "tag/name" --token TOKEN
      bearcli tags --token TOKEN
      bearcli open-tag --name "tag/name" --token TOKEN
      bearcli untagged --token TOKEN
      bearcli untagged --search "filter" --token TOKEN
      bearcli todo --token TOKEN
      bearcli today --token TOKEN
      bearcli add-text --title "Note Title" --text "New text" --token TOKEN
      bearcli add-text --id NOTE_ID --text "New text" --mode prepend --token TOKEN
      bearcli grab-url --url "https://example.com" --token TOKEN
      bearcli create --title "New Note" --text "Content" --tags "tag1,tag2" --token TOKEN

    Commands:
      open-note  Read a note by title or ID
      search     Search notes by term or tag
      tags       List all tags
      open-tag   List notes with a specific tag
      untagged   List notes without tags
      todo       List notes containing todo items
      today      List notes created or modified today
      add-text   Append or prepend text to an existing note
      grab-url   Create a note from a web page URL
      create     Create a new note

    Options:
      --title           Note title (for open-note, add-text)
      --id              Note unique identifier (for open-note, add-text)
      --term            Search term (for search)
      --tag             Tag name (for search)
      --name            Tag name (for open-tag)
      --search          Filter string (for untagged, todo, today)
      --text            Text content (for add-text, create)
      --mode            Insert mode: append, prepend, replace_all, replace (for add-text)
      --new-line        If "yes", adds text on a new line in append mode (for add-text)
      --tags            Comma-separated tags (for add-text, grab-url, create)
      --url             Web page URL (for grab-url)
      --pin             If "yes", pin the note (for grab-url, create)
      --timestamp       If "yes", prepend date/time (for add-text, create)
      --exclude-trashed If "yes", exclude trashed notes (for add-text)
      --token           Bear API token (required)
      --timeout         Timeout in seconds (default: 10)
      --json            Output raw JSON response
      --help            Show this help message
    """
    print(usage)
}

func parseArgs() -> [String: String] {
    let args = CommandLine.arguments
    var parsed: [String: String] = [:]

    if args.count < 2 {
        return parsed
    }

    if args[1] == "--help" || args[1] == "-h" {
        parsed["help"] = "true"
        return parsed
    }

    parsed["command"] = args[1]

    // Flags that carry no value — presence alone means "true"
    let booleanFlags: Set<String> = ["json"]

    var i = 2
    while i < args.count {
        let arg = args[i]
        if arg.hasPrefix("--") {
            let key = String(arg.dropFirst(2))
            if booleanFlags.contains(key) {
                parsed[key] = "true"
                i += 1
            } else if i + 1 < args.count, !args[i + 1].hasPrefix("--") {
                parsed[key] = args[i + 1]
                i += 2
            } else {
                // Non-boolean flag with no following value.
                // --new-line can be used without "yes" and means "yes".
                // All other flags are left unset so existing guards surface a
                // clear "required" error instead of silently using "true".
                if key == "new-line" {
                    parsed[key] = "yes"
                }
                i += 1
            }
        } else {
            i += 1
        }
    }

    return parsed
}

// MARK: - Main

let parsedArgs = parseArgs()

if parsedArgs["command"] == nil || parsedArgs["help"] == "true" {
    printUsage()
    exit(0)
}

guard let token = parsedArgs["token"] else {
    fputs("Error: --token is required\n", stderr)
    exit(1)
}

let command = parsedArgs["command"]!
let api = BearAPI(token: token)
let timeout = Double(parsedArgs["timeout"] ?? "10") ?? 10.0
let jsonOutput = parsedArgs["json"] == "true"

var bearURL: URL?

switch command {
case "open-note":
    if parsedArgs["title"] == nil && parsedArgs["id"] == nil {
        fputs("Error: --title or --id is required for open-note\n", stderr)
        exit(1)
    }
    bearURL = api.openNote(title: parsedArgs["title"], id: parsedArgs["id"])

case "search":
    if parsedArgs["term"] == nil && parsedArgs["tag"] == nil {
        fputs("Error: --term or --tag is required for search\n", stderr)
        exit(1)
    }
    bearURL = api.search(term: parsedArgs["term"], tag: parsedArgs["tag"])

case "tags":
    bearURL = api.tags()

case "open-tag":
    guard let name = parsedArgs["name"] else {
        fputs("Error: --name is required for open-tag\n", stderr)
        exit(1)
    }
    bearURL = api.openTag(name: name)

case "untagged":
    bearURL = api.untagged(search: parsedArgs["search"])

case "todo":
    bearURL = api.todo(search: parsedArgs["search"])

case "today":
    bearURL = api.today(search: parsedArgs["search"])

case "add-text":
    if parsedArgs["title"] == nil && parsedArgs["id"] == nil {
        fputs("Error: --title or --id is required for add-text\n", stderr)
        exit(1)
    }
    guard let text = parsedArgs["text"] else {
        fputs("Error: --text is required for add-text\n", stderr)
        exit(1)
    }
    bearURL = api.addText(
        id: parsedArgs["id"],
        title: parsedArgs["title"],
        text: text,
        mode: parsedArgs["mode"],
        newLine: parsedArgs["new-line"],
        tags: parsedArgs["tags"],
        excludeTrashed: parsedArgs["exclude-trashed"],
        timestamp: parsedArgs["timestamp"]
    )

case "grab-url":
    guard let url = parsedArgs["url"] else {
        fputs("Error: --url is required for grab-url\n", stderr)
        exit(1)
    }
    bearURL = api.grabURL(url: url, tags: parsedArgs["tags"], pin: parsedArgs["pin"])

case "create":
    bearURL = api.create(
        title: parsedArgs["title"],
        text: parsedArgs["text"],
        tags: parsedArgs["tags"],
        pin: parsedArgs["pin"],
        timestamp: parsedArgs["timestamp"]
    )

default:
    fputs("Error: Unknown command '\(command)'. Use open-note, search, tags, open-tag, untagged, todo, today, add-text, grab-url, or create.\n", stderr)
    exit(1)
}

guard let url = bearURL else {
    fputs("Error: Failed to construct Bear URL\n", stderr)
    exit(1)
}

// Check if Bear is running, start it if needed
let bearBundleID = "net.shinyfrog.bear"
let bearWasRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bearBundleID }

if !bearWasRunning {
    fputs("Bear is not running. Starting Bear...\n", stderr)
    guard let bearURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bearBundleID) else {
        fputs("Error: Bear is not installed\n", stderr)
        exit(1)
    }
    let config = NSWorkspace.OpenConfiguration()
    config.activates = false
    config.hides = true
    let semaphore = DispatchSemaphore(value: 0)
    var launchError: Error?
    NSWorkspace.shared.openApplication(at: bearURL, configuration: config) { _, error in
        launchError = error
        semaphore.signal()
    }
    semaphore.wait()
    if let error = launchError {
        fputs("Error: Failed to start Bear: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
    // Give Bear time to initialize and register its URL handler
    Thread.sleep(forTimeInterval: 2.0)
}

// Set up app with URL handler
let app = NSApplication.shared
let handler = CallbackHandler()
app.delegate = handler
app.setActivationPolicy(.accessory)

// Schedule URL open after app starts
DispatchQueue.main.async {
    NSWorkspace.shared.open(url)
}

// Schedule timeout
DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
    if !handler.didReceiveCallback {
        fputs("Error: Timed out waiting for Bear callback after \(Int(timeout))s\n", stderr)
        exit(1)
    }
}

// Run the app (blocks until NSApp.stop is called from callback handler)
app.run()

// Output results
if let error = handler.error {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}

if let result = handler.result {
    if jsonOutput {
        if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    } else {
        if command == "open-note" {
            if let noteText = result["note"] {
                print(noteText)
            } else {
                for (key, value) in result.sorted(by: { $0.key < $1.key }) {
                    print("\(key): \(value)")
                }
            }
        } else if command == "search" {
            if let notes = result["notes"] {
                print(notes)
            } else {
                for (key, value) in result.sorted(by: { $0.key < $1.key }) {
                    print("\(key): \(value)")
                }
            }
        } else if command == "tags" {
            if let tags = result["tags"] {
                print(tags)
            } else {
                for (key, value) in result.sorted(by: { $0.key < $1.key }) {
                    print("\(key): \(value)")
                }
            }
        } else if command == "open-tag" || command == "untagged" || command == "todo" || command == "today" {
            if let notes = result["notes"] {
                print(notes)
            } else {
                for (key, value) in result.sorted(by: { $0.key < $1.key }) {
                    print("\(key): \(value)")
                }
            }
        } else if command == "add-text" {
            if let noteText = result["note"] {
                print(noteText)
            } else {
                for (key, value) in result.sorted(by: { $0.key < $1.key }) {
                    print("\(key): \(value)")
                }
            }
        } else if command == "grab-url" || command == "create" {
            if let identifier = result["identifier"] {
                print("identifier: \(identifier)")
            }
            if let title = result["title"] {
                print("title: \(title)")
            }
            if result["identifier"] == nil && result["title"] == nil {
                for (key, value) in result.sorted(by: { $0.key < $1.key }) {
                    print("\(key): \(value)")
                }
            }
        }
    }
}

// If we started Bear, quit it
if !bearWasRunning {
    if let bearApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bearBundleID }) {
        fputs("Done, closing Bear...\n", stderr)
        bearApp.terminate()
    }
}

exit(0)
