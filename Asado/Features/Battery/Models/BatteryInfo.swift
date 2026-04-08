//
//  BatteryInfo.swift
//  Asado
//
//  Created by Fran Alarza on 8/4/26.
//

// MARK: - ChargingState

enum ChargingState: Sendable {
    case charging
    case discharging
    case charged
    case noBattery
    case unknown
}

// MARK: - BatteryHealth

enum BatteryHealth: Sendable {
    case good
    case fair
    case poor
}

// MARK: - BatteryInfo

struct BatteryInfo: Sendable {
    let percentage: Int?
    let chargingState: ChargingState
    let health: BatteryHealth?
}
