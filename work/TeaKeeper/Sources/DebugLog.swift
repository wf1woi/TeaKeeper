import Foundation

enum DebugLog {
    static func write(_ message: String) {
        guard ProcessInfo.processInfo.environment["COFFEETEA_REPLICA_DEBUG"] == "1" else { return }

        let line = "[\(Date())] \(message)\n"
        FileHandle.standardError.write(Data(line.utf8))
    }
}
