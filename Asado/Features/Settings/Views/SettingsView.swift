//
//  SettingsView.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var settings: AppSettings
    private let audioPlayer: AudioPlayerServiceProtocol
    private let storageService: CustomSoundStorageServiceProtocol

    @State private var soundOptions: [SoundOption] = []
    @State private var isImporting = false
    @State private var importError: String?

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
        Form {
            Section("Alerts") {
                Toggle("Sound alerts", isOn: $settings.soundEnabled)

                soundListSection

                if let error = importError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("CPU Threshold: \(settings.threshold)%")
                    Slider(
                        value: thresholdBinding,
                        in: 50...100,
                        step: 1
                    )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 300)
        .onAppear { soundOptions = SoundOption.all(using: storageService) }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.mp3, .wav, .aiff, UTType("public.mpeg-4-audio") ?? .audio]
        ) { result in
            handleImport(result: result)
        }
    }

    // MARK: - Sound List

    private var soundListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Alert sound")
                    .font(.body)
                Spacer()
                Button {
                    importError = nil
                    isImporting = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 6)

            ForEach(soundOptions) { option in
                HStack {
                    Image(systemName: settings.selectedSound == option.id ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(settings.selectedSound == option.id ? Color.accentColor : Color.secondary)

                    Text(option.displayName)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if option.isCustom {
                        Button {
                            deleteSound(option)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.selectedSound = option.id
                }
                .padding(.vertical, 4)

                Divider()
            }

            // Preview button
            HStack {
                Spacer()
                Button {
                    previewSelectedSound()
                } label: {
                    Label("Preview", systemImage: "speaker.wave.2")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Private

    private var thresholdBinding: Binding<Double> {
        Binding(
            get: { Double(settings.threshold) },
            set: { settings.threshold = Int($0) }
        )
    }

    private func handleImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let newSound = try storageService.importSound(from: url)
                soundOptions = SoundOption.all(using: storageService)
                settings.selectedSound = newSound.id
                importError = nil
            } catch {
                importError = error.localizedDescription
            }

        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    private func deleteSound(_ sound: SoundOption) {
        do {
            try storageService.deleteSound(sound)
            if settings.selectedSound == sound.id {
                settings.selectedSound = AppSettings.defaultSelectedSound
            }
            soundOptions = SoundOption.all(using: storageService)
            importError = nil
        } catch {
            importError = error.localizedDescription
        }
    }

    private func previewSelectedSound() {
        guard let sound = soundOptions.first(where: { $0.id == settings.selectedSound }),
              let url = sound.url else { return }
        Task {
            await audioPlayer.playSound(url: url)
        }
    }
}
