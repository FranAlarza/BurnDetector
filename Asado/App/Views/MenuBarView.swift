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
            HStack(spacing: 12) {
                Image(systemName: viewModel.macInfo.macType.symbolName)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.macInfo.modelName)
                        .font(.headline)

                    if !viewModel.macInfo.subtitleLabel.isEmpty {
                        Text(viewModel.macInfo.subtitleLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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
                    action: { cpuWindowController.show(viewModel: viewModel) },
                    tintColor: cpuTintColor,
                    infoMessage: cpuInfoMessage
                )
                MetricCardView(
                    systemImage: "internaldrive",
                    title: "Disk",
                    value: viewModel.diskValueLabel,
                    action: { NSWorkspace.shared.open(storagePrefsURL) },
                    tintColor: diskTintColor,
                    infoMessage: diskInfoMessage
                )
                MetricCardView(
                    systemImage: "battery.100",
                    title: "Battery",
                    value: batteryValueLabel,
                    action: {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!)
                    },
                    tintColor: batteryTintColor,
                    infoMessage: batteryInfoMessage
                )
                MetricCardView(
                    systemImage: "memorychip",
                    title: "RAM",
                    value: viewModel.ramValueLabel,
                    action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                    },
                    tintColor: ramTintColor,
                    infoMessage: ramInfoMessage
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
        .frame(width: 400)
        .background(backgroundGradient)
        .preferredColorScheme(.dark)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .asadoEmber.opacity(0.35), location: 0.0),
                .init(color: .asadoSmoke,               location: 0.4),
                .init(color: .asadoCoal,                location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

    private var cpuTintColor: Color? {
        guard let usage = viewModel.cpuUsage else { return nil }
        switch usage {
        case 0...50:  return .green
        case 51...80: return .yellow
        default:      return .red
        }
    }

    private var diskTintColor: Color? {
        guard let freeGB = viewModel.freeDiskSpaceGB else { return nil }
        let threshold = Double(viewModel.settings.diskThresholdGB)
        switch freeGB {
        case ..<threshold:            return .red
        case threshold..<(threshold * 2): return .yellow
        default:                      return .green
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

    // MARK: - Info Messages

    private var cpuInfoMessage: String {
        MenuBarInfoMessages.cpuMessage(usage: viewModel.cpuUsage)
    }

    private var diskInfoMessage: String {
        MenuBarInfoMessages.diskMessage(
            freeGB: viewModel.freeDiskSpaceGB,
            thresholdGB: viewModel.settings.diskThresholdGB
        )
    }

    private var batteryInfoMessage: String {
        MenuBarInfoMessages.batteryMessage(info: viewModel.batteryInfo)
    }

    private var ramTintColor: Color? {
        guard let info = viewModel.memoryInfo else { return nil }
        switch info.percentageUsed {
        case 0...70:  return .asadoFlame
        case 71...85: return .yellow
        default:      return .red
        }
    }

    private var ramInfoMessage: String {
        MenuBarInfoMessages.ramMessage(info: viewModel.memoryInfo)
    }
}
