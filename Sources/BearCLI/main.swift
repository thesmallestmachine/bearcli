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
    let callbackScheme = "bear-cli-callback"

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
    bear-cli: Read and search Bear notes from the command line

    Usage:
      bear-cli open-note --title "Note Title" --token TOKEN
      bear-cli open-note --id NOTE_ID --token TOKEN
      bear-cli search --term "search query" --token TOKEN
      bear-cli search --tag "tag/name" --token TOKEN
      bear-cli tags --token TOKEN

    Options:
      --title    Note title (for open-note)
      --id       Note unique identifier (for open-note)
      --term     Search term (for search)
      --tag      Tag name (for search)
      --token    Bear API token
      --timeout  Timeout in seconds (default: 10)
      --json     Output raw JSON response
      --help     Show this help message
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

    var i = 2
    while i < args.count {
        let arg = args[i]
        if arg.hasPrefix("--") {
            let key = String(arg.dropFirst(2))
            if i + 1 < args.count, !args[i + 1].hasPrefix("--") {
                parsed[key] = args[i + 1]
                i += 2
            } else {
                parsed[key] = "true"
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

default:
    fputs("Error: Unknown command '\(command)'. Use open-note, search, or tags.\n", stderr)
    exit(1)
}

guard let url = bearURL else {
    fputs("Error: Failed to construct Bear URL\n", stderr)
    exit(1)
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
        }
    }
}

exit(0)
