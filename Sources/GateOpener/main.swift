import AppKit
import Darwin
import SwiftUI
import UniformTypeIdentifiers

@main
struct GateOpenerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(model: AppDelegate.model)
                .frame(minWidth: 520, minHeight: 340)
        }
        .windowResizability(.contentMinSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor static let model = GateOpenerModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            Self.model.unlock(urls)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        Task { @MainActor in
            Self.model.unlock([URL(fileURLWithPath: filename)])
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        Task { @MainActor in
            let urls = filenames.map(URL.init(fileURLWithPath:))
            Self.model.unlock(urls)
            NSApp.reply(toOpenOrPrint: .success)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func openInGateOpener(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let urls = pasteboard
            .readObjects(forClasses: [NSURL.self])?
            .compactMap { ($0 as? NSURL)?.absoluteURL }
            ?? []

        guard !urls.isEmpty else {
            error.pointee = "No application was selected." as NSString
            return
        }

        Task { @MainActor in
            Self.model.unlock(urls)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@MainActor
final class GateOpenerModel: ObservableObject {
    @Published var status: DropStatus = .idle

    func unlock(_ urls: [URL]) {
        guard let url = urls.first else {
            status = .failure("Choose a macOS .app bundle.")
            return
        }

        status = DropStatus(removeQuarantineAttribute(from: url))
    }
}

struct ContentView: View {
    @ObservedObject var model: GateOpenerModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: model.status.symbolName)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(model.status.symbolColor)
                .frame(width: 72, height: 72)

            Text("Open an app with GateOpener")
                .font(.system(size: 28, weight: .semibold))

            Text(model.status.message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3, reservesSpace: true)
                .frame(maxWidth: 420)
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(dropBackground)
        .overlay(dropBorder)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted, perform: handleDrop)
    }

    private var dropBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(isTargeted ? Color.accentColor.opacity(0.14) : Color(nsColor: .windowBackgroundColor))
            .animation(.easeOut(duration: 0.12), value: isTargeted)
    }

    private var dropBorder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(
                isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                style: StrokeStyle(lineWidth: 2, dash: [8, 6])
            )
            .padding(18)
            .animation(.easeOut(duration: 0.12), value: isTargeted)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            model.status = .failure("Drop a macOS .app bundle.")
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            let result = resolveDroppedURL(from: item, error: error).flatMap(removeQuarantineAttribute)

            DispatchQueue.main.async {
                model.status = DropStatus(result)
            }
        }

        return true
    }
}

enum DropStatus: Equatable {
    case idle
    case success(String)
    case failure(String)

    fileprivate init(_ result: Result<UnlockOutcome, GateOpenerError>) {
        switch result {
        case .success(.removed(let appName)):
            self = .success("Gatekeeper quarantine removed from \(appName).")
        case .success(.alreadyUnlocked(let appName)):
            self = .success("\(appName) was already unlocked.")
        case .failure(let error):
            self = .failure(error.localizedDescription)
        }
    }

    var message: String {
        switch self {
        case .idle:
            return "Drag a .app bundle here, or right-click one in Finder and choose Open With > GateOpener."
        case .success(let message), .failure(let message):
            return message
        }
    }

    var symbolName: String {
        switch self {
        case .idle:
            return "app.dashed"
        case .success:
            return "checkmark.seal"
        case .failure:
            return "xmark.octagon"
        }
    }

    var symbolColor: Color {
        switch self {
        case .idle:
            return .accentColor
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
}

enum GateOpenerError: LocalizedError {
    case unreadableDrop
    case notAnApplication(URL)
    case xattrFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadableDrop:
            return "The dropped item could not be read."
        case .notAnApplication:
            return "Only .app bundles can be unlocked."
        case .xattrFailed(let message):
            return message
        }
    }
}

fileprivate enum UnlockOutcome: Equatable {
    case removed(String)
    case alreadyUnlocked(String)
}

private func resolveDroppedURL(from item: NSSecureCoding?, error: Error?) -> Result<URL, GateOpenerError> {
    guard error == nil else {
        return .failure(.unreadableDrop)
    }

    if let url = item as? URL {
        return .success(url)
    }

    if let data = item as? Data,
       let url = URL(dataRepresentation: data, relativeTo: nil) {
        return .success(url)
    }

    if let string = item as? String,
       let url = URL(string: string) {
        return .success(url)
    }

    return .failure(.unreadableDrop)
}

private func removeQuarantineAttribute(from url: URL) -> Result<UnlockOutcome, GateOpenerError> {
    let standardizedURL = url.standardizedFileURL
    guard isApplicationBundle(standardizedURL) else {
        return .failure(.notAnApplication(standardizedURL))
    }

    let appName = standardizedURL.lastPathComponent
    switch appBundleContainsQuarantineAttribute(standardizedURL) {
    case .success(true):
        break
    case .success(false):
        return .success(.alreadyUnlocked(appName))
    case .failure(let error):
        return .failure(error)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
    process.arguments = ["-dr", "com.apple.quarantine", standardizedURL.path]

    let errorPipe = Pipe()
    process.standardError = errorPipe

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return .failure(.xattrFailed("Could not run xattr: \(error.localizedDescription)"))
    }

    if process.terminationStatus == 0 {
        return .success(.removed(appName))
    }

    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let errorMessage = String(data: errorData, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)

    return .failure(.xattrFailed(errorMessage?.isEmpty == false ? errorMessage! : "xattr failed."))
}

private func isApplicationBundle(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue && url.pathExtension.lowercased() == "app"
}

private func appBundleContainsQuarantineAttribute(_ rootURL: URL) -> Result<Bool, GateOpenerError> {
    switch urlHasQuarantineAttribute(rootURL) {
    case .success(true):
        return .success(true)
    case .success(false):
        break
    case .failure(let error):
        return .failure(error)
    }

    var enumerationError: Error?
    let enumerator = FileManager.default.enumerator(
        at: rootURL,
        includingPropertiesForKeys: nil,
        options: [],
        errorHandler: { _, error in
            enumerationError = error
            return false
        }
    )

    guard let enumerator else {
        return .failure(.xattrFailed("Could not inspect the app bundle."))
    }

    for case let childURL as URL in enumerator {
        switch urlHasQuarantineAttribute(childURL) {
        case .success(true):
            return .success(true)
        case .success(false):
            continue
        case .failure(let error):
            return .failure(error)
        }
    }

    if let enumerationError {
        return .failure(.xattrFailed("Could not inspect the app bundle: \(enumerationError.localizedDescription)"))
    }

    return .success(false)
}

private func urlHasQuarantineAttribute(_ url: URL) -> Result<Bool, GateOpenerError> {
    let status = url.withUnsafeFileSystemRepresentation { filePath -> Int32 in
        guard let filePath else {
            return -EINVAL
        }

        errno = 0
        let result = getxattr(filePath, "com.apple.quarantine", nil, 0, 0, 0)

        if result >= 0 {
            return 1
        }

        if errno == ENOATTR || errno == ENOENT {
            return 0
        }

        return -errno
    }

    switch status {
    case 1:
        return .success(true)
    case 0:
        return .success(false)
    default:
        return .failure(.xattrFailed("Could not inspect quarantine status for \(url.lastPathComponent)."))
    }
}
