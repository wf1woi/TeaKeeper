import Foundation
import OSLog

enum DebugLog {
    private static let fileQueue = DispatchQueue(label: "local.codex.TeaKeeper.log")
    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        return formatter
    }()
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "local.codex.TeaKeeper",
        category: "runtime"
    )

    static func write(_ message: String) {
        guard ProcessInfo.processInfo.environment["TEAKEEPER_TESTING"] != "1" else { return }

        logger.notice("\(message, privacy: .public)")
        fileQueue.sync {
            appendToFile("[\(formatter.string(from: Date()))] \(message)\n")
        }

        guard ProcessInfo.processInfo.environment["COFFEETEA_REPLICA_DEBUG"] == "1" else { return }

        let line = "[\(Date())] \(message)\n"
        FileHandle.standardError.write(Data(line.utf8))
    }

    private static func appendToFile(_ line: String) {
        let fileManager = FileManager.default
        guard let library = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }

        let directory = library.appendingPathComponent("Logs/TeaKeeper", isDirectory: true)
        let logFile = directory.appendingPathComponent("TeaKeeper.log")
        let oldLogFile = directory.appendingPathComponent("TeaKeeper.old.log")

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

            let size = (try? fileManager.attributesOfItem(atPath: logFile.path)[.size] as? NSNumber)?.intValue ?? 0
            if size >= 512 * 1024 {
                try? fileManager.removeItem(at: oldLogFile)
                try? fileManager.moveItem(at: logFile, to: oldLogFile)
            }

            if !fileManager.fileExists(atPath: logFile.path) {
                fileManager.createFile(atPath: logFile.path, contents: nil)
            }

            let handle = try FileHandle(forWritingTo: logFile)
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
            try handle.close()
        } catch {
            return
        }
    }
}
