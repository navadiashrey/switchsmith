import Foundation

/// Minimal file-backed logger for diagnosing menu-bar-app issues that
/// don't surface in a visible console (e.g. permission failures at launch).
enum DebugLog {
    private static let url = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/switchsmith/debug.log")

    static func write(_ message: String) {
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: url)
        }
    }
}
