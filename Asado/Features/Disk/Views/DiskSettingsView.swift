//
//  DiskSettingsView.swift
//  Asado
//
//  Created by Fran Alarza
//

import SwiftUI
import UniformTypeIdentifiers

struct DiskSettingsView: View {
    @Bindable var settings: AppSettings
    private let audioPlayer: AudioPlayerServiceProtocol
    private let storageService: CustomSoundStorageServiceProtocol

    @State private var soundOptions: [SoundOption] = []
    @State private var isImporting = false
    @State private var importError: String?
    @State private var thresholdInput: String
    @State private var thresholdError: String?

    // MARK: - Init

    init(
        settings: AppSettings,
        audioPlayer: AudioPlayerServiceProtocol = AudioPlayerService(),
        storageService: CustomSoundStorageServiceProtocol = CustomSoundStorageService()
    ) {
        self.settings = settings
        self.audioPlayer = audioPlayer
        self.storageService = storageService
        self._thresholdInput = State(initialValue: String(settings.diskThresholdGB))
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section("Alerts") {
                Toggle("Sound alerts", isOn: $settings.diskSoundEnabled)

                soundListSection

                if let error = importError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Limits") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Free disk threshold (GB)")
                        Spacer()
                        TextField("GB", text: $thresholdInput)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .onSubmit { commitThreshold() }
                            .onChange(of: thresholdInput) { _, _ in commitThreshold() }
                    }
                    if let error = thresholdError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .formStyle(.grouped)
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
                    Image(systemName: settings.diskSelectedSound == option.id ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(settings.diskSelectedSound == option.id ? Color.accentColor : Color.secondary)

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
                    settings.diskSelectedSound = option.id
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

    private func commitThreshold() {
        guard let value = Int(thresholdInput), value > 0 else {
            thresholdError = "Enter a number greater than 0."
            return
        }
        thresholdError = nil
        settings.diskThresholdGB = value
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
                settings.diskSelectedSound = newSound.id
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
            if settings.diskSelectedSound == sound.id {
                settings.diskSelectedSound = AppSettings.defaultDiskSelectedSound
            }
            soundOptions = SoundOption.all(using: storageService)
            importError = nil
        } catch {
            importError = error.localizedDescription
        }
    }

    private func previewSelectedSound() {
        guard let sound = soundOptions.first(where: { $0.id == settings.diskSelectedSound }),
              let url = sound.url else { return }
        Task {
            await audioPlayer.playSound(url: url)
        }
    }
}
