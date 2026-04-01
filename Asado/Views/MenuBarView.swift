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

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            Text(cpuLabel)
                .font(.body)
                .foregroundStyle(.secondary)

            if viewModel.permissionsError {
                Text("Permissions required to read CPU usage")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !viewModel.topProcesses.isEmpty {
                Divider()
                processListSection
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 260)
    }

    // MARK: - Process List

    private var processListSection: some View {
        VStack(spacing: 4) {
            ForEach(viewModel.topProcesses) { process in
                HStack(spacing: 8) {
                    processIcon(for: process)
                        .frame(width: 16, height: 16)

                    Text(process.name)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(String(format: "%.1f%%", process.cpuUsage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func processIcon(for process: TopProcess) -> some View {
        if let icon = process.icon {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "gearshape.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }

    private var cpuLabel: String {
        if let usage = viewModel.cpuUsage {
            return "CPU: \(usage)%"
        }
        return "CPU: --%"
    }
}
