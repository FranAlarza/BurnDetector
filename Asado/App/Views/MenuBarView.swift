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

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

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
                    value: cpuValueLabel
                )
                MetricCardView(
                    systemImage: "internaldrive",
                    title: "Disk",
                    value: viewModel.diskValueLabel
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
}
