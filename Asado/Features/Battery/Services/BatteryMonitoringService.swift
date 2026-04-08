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
            } else if let currentCapacity = current, let maxCapacity = max, maxCapacity > 0, currentCapacity >= maxCapacity {
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
        guard let healthString = desc[kIOPSBatteryHealthKey] as? String else {
            logger.warning("[Battery] - BatteryHealth key not found in power source description.")
            return nil
        }
        logger.info("[Battery] - BatteryHealth raw value: '\(healthString)'")
        
        switch healthString {
        case "Good":                       return .good
        case "Fair", "Check Battery",
             "Replace Soon":               return .fair
        case "Poor", "Replace Now",
             "Service Battery":            return .poor
        default:
            logger.warning("[Battery] - Unrecognised BatteryHealth value: '\(healthString)'")
            return nil
        }
    }
}
