//
//  CPUProcessesView.swift
//  Asado
//
//  Created by Fran Alarza on 6/4/26.
//

import SwiftUI

struct CPUProcessesView: View {
    let viewModel: MenuBarViewModel

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.topProcesses.isEmpty {
                Text("No data yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.topProcesses) { process in
                    HStack(spacing: 10) {
                        processIcon(process)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(process.name)
                                .font(.headline)
                                .lineLimit(1)

                            Text(String(format: "%.1f%%", process.cpuUsage))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 380, height: 480)
    }

    // MARK: - Private

    @ViewBuilder
    private func processIcon(_ process: TopProcess) -> some View {
        if let nsImage = process.icon {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: 28, height: 28)
        } else {
            Image(systemName: "questionmark.app")
                .font(.system(size: 24))
                .frame(width: 28, height: 28)
        }
    }
}
