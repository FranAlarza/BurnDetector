//
//  AsadoApp.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import SwiftUI

@main
struct AsadoApp: App {
    @State private var viewModel = MenuBarViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                Text(cpuLabel)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: viewModel.settings)
        }
    }

    // MARK: - Private

    private var cpuLabel: String {
        guard let usage = viewModel.cpuUsage else { return "--%"}
        return "\(usage)%"
    }
}
