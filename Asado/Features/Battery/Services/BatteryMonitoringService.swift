//
//  BatteryMonitoringService.swift
//  Asado
//
//  Created by Fran Alarza on 8/4/26.
//

import IOKit
import IOKit.ps

// MARK: - Protocol

protocol BatteryMonitoringServiceProtocol: Sendable {
    func batteryInfo() -> BatteryInfo
}

// MARK: - Implementation

struct BatteryMonitoringService: BatteryMonitoringServiceProtocol {

    func batteryInfo() -> BatteryInfo {
        guard let rawInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let rawList = IOPSCopyPowerSourcesList(rawInfo)?.takeRetainedValue() as? [CFTypeRef] else {
            return BatteryInfo(percentage: nil, chargingState: .unknown, health: nil)
        }

        for source in rawList {
            guard let desc = IOPSGetPowerSourceDescription(rawInfo, source)?
                    .takeUnretainedValue() as? [String: Any],
                  let type = desc[kIOPSTypeKey] as? String,
                  type == kIOPSInternalBatteryType else { continue }

            let current = desc[kIOPSCurrentCapacityKey] as? Int
            let max = desc[kIOPSMaxCapacityKey] as? Int
            let isCharging = desc[kIOPSIsChargingKey] as? Bool ?? false

            let chargingState: ChargingState
            if isCharging {
                chargingState = .charging
            } else if let c = current, let m = max, m > 0, c >= m {
                chargingState = .charged
            } else {
                chargingState = .discharging
            }

            let health = resolveHealth(from: desc)

            return BatteryInfo(percentage: current, chargingState: chargingState, health: health)
        }

        return BatteryInfo(percentage: nil, chargingState: .noBattery, health: nil)
    }

    // MARK: - Private

    private func resolveHealth(from desc: [String: Any]) -> BatteryHealth? {
        guard let healthString = desc[kIOPSBatteryHealthKey] as? String else { return nil }
        switch healthString {
        case kIOPSGoodValue: return .good
        case kIOPSFairValue: return .fair
        case kIOPSPoorValue: return .poor
        default: return nil
        }
    }
}
