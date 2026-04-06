//
//  CPUProcessesView.swift
//  Asado
//
//  Created by Fran Alarza on 6/4/26.
//

import SwiftUI

private enum ProcessFilter: String, CaseIterable {
    case all = "All"
    case apps = "Apps"
    case system = "System"
}

struct CPUProcessesView: View {
    let viewModel: MenuBarViewModel

    @State private var filter: ProcessFilter = .all

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $filter) {
                ForEach(ProcessFilter.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            let filtered = filteredProcesses
            if filtered.isEmpty {
                Text("No data yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filtered) { process in
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

    private var filteredProcesses: [TopProcess] {
        switch filter {
        case .all:    return viewModel.topProcesses
        case .apps:   return viewModel.topProcesses.filter { $0.isApp }
        case .system: return viewModel.topProcesses.filter { !$0.isApp }
        }
    }

    @ViewBuilder
    private func processIcon(_ process: TopProcess) -> some View {
        if let nsImage = process.icon {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: 28, height: 28)
        } else {
            Image(systemName: "terminal")
                .font(.system(size: 18))
                .frame(width: 28, height: 28)
        }
    }
}
