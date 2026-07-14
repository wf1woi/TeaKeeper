import Foundation
import IOKit

enum LidStateMonitor {
    static func isClosed() -> Bool? {
        if ProcessInfo.processInfo.environment["COFFEETEA_REPLICA_DEBUG"] == "1",
           let override = ProcessInfo.processInfo.environment["TEAKEEPER_LID_STATE_OVERRIDE"] {
            return override.lowercased() == "closed"
        }

        let rootDomain = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPMrootDomain")
        )
        guard rootDomain != MACH_PORT_NULL else { return nil }
        defer { IOObjectRelease(rootDomain) }

        guard let value = IORegistryEntryCreateCFProperty(
            rootDomain,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            return nil
        }

        return value as? Bool
    }
}
