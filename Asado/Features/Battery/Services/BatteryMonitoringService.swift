//
//  BatteryMonitoringService.swift
//  Asado
//
//  Created by Fran Alarza on 8/4/26.
//

import IOKit
import IOKit.ps
import os

// MARK: - Protocol

protocol BatteryMonitoringServiceProtocol: Sendable {
    func batteryInfo() -> BatteryInfo
}

// MARK: - Implementation

struct BatteryMonitoringService: BatteryMonitoringServiceProtocol {

    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "BatteryMonitoring")

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
        let dictDump = desc.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")
        logger.info("[Battery] - Power source dict: { \(dictDump) }")

        // kIOPSBatteryHealthKey = "BatteryHealth", values: "Good" / "Fair" / "Poor"
        guard let healthString = desc[kIOPSBatteryHealthKey] as? String else {
            logger.warning("[Battery] - BatteryHealth key not found in power source description.")
            return nil
        }
        logger.info("[Battery] - BatteryHealth raw value: '\(healthString)'")
        switch healthString {
        case "Good":  return .good
        case "Fair":  return .fair
        case "Poor":  return .poor
        default:
            // Fallback: check kIOPSBatteryHealthConditionKey used on some hardware
            logger.warning("[Battery] - Unrecognised BatteryHealth value '\(healthString)', checking BatteryHealthCondition")
            return resolveHealthCondition(from: desc)
        }
    }

    private func resolveHealthCondition(from desc: [String: Any]) -> BatteryHealth? {
        // kIOPSBatteryHealthConditionKey = "BatteryHealthCondition"
        // values: "Check Battery" / "Replace Soon" / "Replace Now"
        guard let condition = desc[kIOPSBatteryHealthConditionKey] as? String else { return nil }
        logger.info("[Battery] - BatteryHealthCondition raw value: '\(condition)'")
        switch condition {
        case "Check Battery": return .fair
        case "Replace Soon":  return .fair
        case "Replace Now":   return .poor
        default:              return nil
        }
    }
}
