//
//  BatteryMonitoringServiceTests.swift
//  Asado
//
//  Created by Fran Alarza on 8/4/26.
//

import Testing
@testable import Asado

// MARK: - Mock Battery Service

struct MockBatteryMonitoringService: BatteryMonitoringServiceProtocol {
    let info: BatteryInfo

    func batteryInfo() -> BatteryInfo { info }
}

// MARK: - Tests

@Suite(.serialized)
@MainActor
struct BatteryMonitoringServiceTests {

    private func makeViewModel(battery: BatteryInfo) -> MenuBarViewModel {
        MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: nil),
            batteryService: MockBatteryMonitoringService(info: battery),
            updateChecker: MockUpdateCheckerService(version: nil)
        )
    }

    @Test
    func goodHealthReflectedInViewModel() {
        let info = BatteryInfo(percentage: 80, chargingState: .discharging, health: .good)
        let viewModel = makeViewModel(battery: info)

        #expect(viewModel.batteryInfo.health == .good)
    }

    @Test
    func nilPercentageProducesFallbackLabel() {
        let info = BatteryInfo(percentage: nil, chargingState: .unknown, health: nil)
        let viewModel = makeViewModel(battery: info)

        #expect(viewModel.batteryValueLabel == "--%")
    }

    @Test
    func noBatteryChargingStateReflected() {
        let info = BatteryInfo(percentage: nil, chargingState: .noBattery, health: nil)
        let viewModel = makeViewModel(battery: info)

        #expect(viewModel.batteryInfo.chargingState == .noBattery)
    }

    @Test
    func percentageFormattedCorrectly() {
        let info = BatteryInfo(percentage: 72, chargingState: .discharging, health: .good)
        let viewModel = makeViewModel(battery: info)

        #expect(viewModel.batteryValueLabel == "72%")
    }
}
