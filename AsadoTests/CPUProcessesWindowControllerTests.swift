//
//  CPUProcessesWindowControllerTests.swift
//  Asado
//
//  Created by Fran Alarza on 6/4/26.
//

import AppKit
import Testing
@testable import Asado

@Suite(.serialized)
@MainActor
struct CPUProcessesWindowControllerTests {

    private func makeViewModel() -> MenuBarViewModel {
        MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: nil),
            updateChecker: MockUpdateCheckerService(version: nil)
        )
    }

    @Test
    func showCreatesWindowWhenNoneExists() {
        let controller = CPUProcessesWindowController()
        let viewModel = makeViewModel()

        #expect(controller.window == nil)

        controller.show(viewModel: viewModel)

        #expect(controller.window != nil)
    }

    @Test
    func showReusesExistingWindowOnSecondCall() {
        let controller = CPUProcessesWindowController()
        let viewModel = makeViewModel()

        controller.show(viewModel: viewModel)
        let firstWindow = controller.window

        controller.show(viewModel: viewModel)
        let secondWindow = controller.window

        #expect(firstWindow === secondWindow)
    }

    @Test
    func showCreatesNewWindowAfterClose() {
        let controller = CPUProcessesWindowController()
        let viewModel = makeViewModel()

        controller.show(viewModel: viewModel)
        let firstWindow = controller.window
        #expect(firstWindow != nil)

        controller.windowWillClose(Notification(name: NSWindow.willCloseNotification))
        #expect(controller.window == nil)

        controller.show(viewModel: viewModel)
        let secondWindow = controller.window
        #expect(secondWindow != nil)
        #expect(firstWindow !== secondWindow)
    }
}
