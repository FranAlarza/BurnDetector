//
//  MenuBarView.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import SwiftUI

struct MenuBarView: View {
    @Bindable var viewModel: MenuBarViewModel
    @Environment(\.openSettings) private var openSettings
    @State private var cpuWindowController = CPUProcessesWindowController()

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private let storagePrefsURL = URL(string: "x-apple.systempreferences:com.apple.settings.Storage")!

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // MARK: Header
            HStack {
                Text("Asado")
                    .font(.headline)

                Spacer()

                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }

            // MARK: Grid
            LazyVGrid(columns: columns, spacing: 12) {
                MetricCardView(
                    systemImage: "cpu",
                    title: "CPU",
                    value: cpuValueLabel,
                    action: { cpuWindowController.show(viewModel: viewModel) }
                )
                MetricCardView(
                    systemImage: "internaldrive",
                    title: "Disk",
                    value: viewModel.diskValueLabel,
                    action: { NSWorkspace.shared.open(storagePrefsURL) }
                )
                MetricCardView(
                    systemImage: "battery.100",
                    title: "Battery",
                    value: batteryValueLabel,
                    tintColor: batteryTintColor
                )
            }

            // MARK: Footer
            Divider()

            HStack {
                if viewModel.isUpdateAvailable {
                    Button {
                        NSWorkspace.shared.open(viewModel.releasesURL)
                    } label: {
                        Label("Update available", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer(minLength: 16)
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            
        }
        .padding()
        .frame(width: 320)
    }

    // MARK: - Private

    private var cpuValueLabel: String {
        if let usage = viewModel.cpuUsage {
            return "Usage: \(usage)%"
        }
        return "Usage: --%"
    }

    private var batteryValueLabel: String {
        let pct = viewModel.batteryValueLabel
        switch viewModel.batteryInfo.chargingState {
        case .charging:    return "\(pct) · Charging"
        case .charged:     return "\(pct) · Charged"
        case .discharging: return "\(pct) · Discharging"
        case .noBattery:   return "No Battery"
        case .unknown:     return pct
        }
    }

    private var batteryTintColor: Color? {
        switch viewModel.batteryInfo.health {
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        case nil:   return nil
        }
    }
}
