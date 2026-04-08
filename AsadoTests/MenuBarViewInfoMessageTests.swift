//
//  MenuBarViewInfoMessageTests.swift
//  Asado
//
//  Created by Fran Alarza on 8/4/26.
//

import Testing
@testable import Asado

struct MenuBarViewInfoMessageTests {

    // MARK: - CPU

    @Test
    func cpuNilReturnsNotAvailable() {
        #expect(MenuBarInfoMessages.cpuMessage(usage: nil) == "CPU data is not available yet.")
    }

    @Test
    func cpuLowUsageReturnsSmoothMessage() {
        let message = MenuBarInfoMessages.cpuMessage(usage: 30)
        #expect(message.contains("smoothly"))
        #expect(message.contains("30%"))
    }

    @Test
    func cpuModerateUsageReturnsModerateMessage() {
        let message = MenuBarInfoMessages.cpuMessage(usage: 65)
        #expect(message.contains("moderate"))
        #expect(message.contains("65%"))
    }

    @Test
    func cpuHighUsageReturnsHeavyLoadMessage() {
        let message = MenuBarInfoMessages.cpuMessage(usage: 95)
        #expect(message.contains("heavy load"))
        #expect(message.contains("95%"))
    }

    // MARK: - Disk

    @Test
    func diskNilReturnsNotAvailable() {
        #expect(MenuBarInfoMessages.diskMessage(freeGB: nil, thresholdGB: 50) == "Disk data is not available yet.")
    }

    @Test
    func diskBelowThresholdReturnsLowSpaceMessage() {
        let message = MenuBarInfoMessages.diskMessage(freeGB: 20.0, thresholdGB: 50)
        #expect(message.contains("Low disk space"))
        #expect(message.contains("20.0 GB"))
    }

    @Test
    func diskBetweenThresholdAndDoubleReturnsGettingLowerMessage() {
        let message = MenuBarInfoMessages.diskMessage(freeGB: 75.0, thresholdGB: 50)
        #expect(message.contains("getting lower"))
        #expect(message.contains("75.0 GB"))
    }

    @Test
    func diskAboveDoubleThresholdReturnsHealthyMessage() {
        let message = MenuBarInfoMessages.diskMessage(freeGB: 200.0, thresholdGB: 50)
        #expect(message.contains("healthy"))
        #expect(message.contains("200.0 GB"))
    }

    // MARK: - Battery

    @Test
    func batteryNoBatteryStateReturnsNoBatteryMessage() {
        let info = BatteryInfo(percentage: nil, chargingState: .noBattery, health: nil)
        #expect(MenuBarInfoMessages.batteryMessage(info: info) == "No battery detected on this Mac.")
    }

    @Test
    func batteryGoodHealthReturnsGreatShapeMessage() {
        let info = BatteryInfo(percentage: 85, chargingState: .discharging, health: .good)
        let message = MenuBarInfoMessages.batteryMessage(info: info)
        #expect(message.contains("great shape"))
    }

    @Test
    func batteryFairHealthReturnsCheckUpMessage() {
        let info = BatteryInfo(percentage: 72, chargingState: .discharging, health: .fair)
        let message = MenuBarInfoMessages.batteryMessage(info: info)
        #expect(message.contains("not at full capacity"))
        #expect(message.contains("System Settings"))
    }

    @Test
    func batteryPoorHealthReturnsReplaceMessage() {
        let info = BatteryInfo(percentage: 60, chargingState: .discharging, health: .poor)
        let message = MenuBarInfoMessages.batteryMessage(info: info)
        #expect(message.contains("replace"))
    }
}
