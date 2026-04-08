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
                    tintColor: batteryTintColor,
                    infoMessage: batteryInfoMessage
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
        .frame(width: 360)
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
        guard let usage = viewModel.cpuUsage else {
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

    private var diskInfoMessage: String {
        guard let freeGB = viewModel.freeDiskSpaceGB else {
            return "Disk data is not available yet."
        }
        let threshold = Double(viewModel.settings.diskThresholdGB)
        let formatted = String(format: "%.1f", freeGB)
        if freeGB < threshold {
            return "Low disk space! Only \(formatted) GB free. Free up space soon."
        } else if freeGB < threshold * 2 {
            return "Disk space is getting lower. \(formatted) GB free — consider cleaning up."
        } else {
            return "Disk space looks healthy. You have \(formatted) GB free."
        }
    }

    private var batteryInfoMessage: String {
        let info = viewModel.batteryInfo
        guard info.chargingState != .noBattery, info.percentage != nil else {
            return "No battery detected on this Mac."
        }
        switch info.health {
        case .good: return "Your battery is in great shape. No action needed."
        case .fair: return "Your battery health is declining. Consider a check-up soon."
        case .poor: return "Battery health is poor. It's time to replace your battery."
        case nil:   return "Battery health data is not available."
        }
    }
}
