//
//  SettingsView.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import SwiftUI

// MARK: - SettingsSection

enum SettingsSection: String, CaseIterable, Identifiable {
    case cpu
    case disk

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cpu: return "CPU"
        case .disk: return "Disk"
        }
    }

    var systemImage: String {
        switch self {
        case .cpu: return "cpu"
        case .disk: return "internaldrive"
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @Bindable var settings: AppSettings
    private let audioPlayer: AudioPlayerServiceProtocol
    private let storageService: CustomSoundStorageServiceProtocol

    @State private var selectedSection: SettingsSection? = .cpu

    // MARK: - Init

    init(
        settings: AppSettings,
        audioPlayer: AudioPlayerServiceProtocol = AudioPlayerService(),
        storageService: CustomSoundStorageServiceProtocol = CustomSoundStorageService()
    ) {
        self.settings = settings
        self.audioPlayer = audioPlayer
        self.storageService = storageService
    }

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.label, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(150)
        } detail: {
            switch selectedSection {
            case .cpu, nil:
                CPUSettingsView(
                    settings: settings,
                    audioPlayer: audioPlayer,
                    storageService: storageService
                )
            case .disk:
                DiskSettingsView(settings: settings, audioPlayer: audioPlayer, storageService: storageService)
            }
        }
        .frame(width: 560, height: 380)
    }
}
