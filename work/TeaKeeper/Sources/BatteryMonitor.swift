import Foundation
import IOKit.ps

struct BatteryInfo {
    let percent: Int
    let isOnBatteryPower: Bool
}

enum BatteryMonitor {
    static func currentBatteryInfo() -> BatteryInfo? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in list {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  let current = description[kIOPSCurrentCapacityKey] as? Int,
                  let max = description[kIOPSMaxCapacityKey] as? Int,
                  max > 0 else {
                continue
            }

            let percent = Int(round((Double(current) / Double(max)) * 100))
            let powerState = description[kIOPSPowerSourceStateKey] as? String
            return BatteryInfo(percent: percent, isOnBatteryPower: powerState == kIOPSBatteryPowerValue)
        }

        return nil
    }
}
