//
//  MenuBarInfoMessages.swift
//  Asado
//
//  Created by Fran Alarza on 8/4/26.
//

import Foundation

// MARK: - MenuBarInfoMessages

/// Pure static functions that produce the contextual info message for each metric card.
/// Extracted from `MenuBarView` to allow unit testing without a SwiftUI host.
enum MenuBarInfoMessages {

    static func cpuMessage(usage: Int?) -> String {
        guard let usage else {
            return "CPU data is not available yet."
        }
        switch usage {
        case 0...50:
            return "Your CPU is running smoothly at \(usage)%. No action needed."
        case 51...80:
            return "CPU usage is moderate at \(usage)%. Keep an eye on background processes."
        default:
            return "CPU is under heavy load at \(usage)%. Consider closing demanding apps."
        }
    }

    static func diskMessage(freeGB: Double?, thresholdGB: Int) -> String {
        guard let freeGB else {
            return "Disk data is not available yet."
        }
        let threshold = Double(thresholdGB)
        let formatted = String(format: "%.1f", freeGB)
        if freeGB < threshold {
            return "Low disk space! Only \(formatted) GB free. Free up space soon."
        } else if freeGB < threshold * 2 {
            return "Disk space is getting lower. \(formatted) GB free — consider cleaning up."
        } else {
            return "Disk space looks healthy. You have \(formatted) GB free."
        }
    }

    static func ramMessage(info: MemoryInfo?) -> String {
        guard let info else {
            return "RAM data is not available yet."
        }
        switch info.percentageUsed {
        case 0...70:
            return "Memory usage is low. Your Mac is running smoothly."
        case 71...85:
            return "Memory usage is moderate at \(String(format: "%.1f", info.usedGB)) GB. Keep an eye on open apps."
        default:
            return "Memory is running low at \(String(format: "%.1f", info.usedGB)) GB. Consider closing unused apps."
        }
    }

    static func batteryMessage(info: BatteryInfo) -> String {
        guard info.chargingState != .noBattery, info.percentage != nil else {
            return "No battery detected on this Mac."
        }
        switch info.health {
        case .good: return "Your battery is in great shape. No action needed."
        case .fair: return "Your battery is not at full capacity. macOS recommends a check-up — you can verify it in System Settings › Battery."
        case .poor: return "Battery health is poor. It's time to replace your battery."
        case nil:   return "Battery health data is not available."
        }
    }
}
