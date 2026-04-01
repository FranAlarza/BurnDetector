//
//  MenuBarViewModel.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import Foundation
import os

@Observable
@MainActor
final class MenuBarViewModel {

    // MARK: - Published State

    private(set) var cpuUsage: Int?
    private(set) var permissionsError = false
    private(set) var topProcesses: [TopProcess] = []
    var settings: AppSettings

    // MARK: - Private

    private let service: CPUMonitoringServiceProtocol
    private let audioPlayer: AudioPlayerServiceProtocol
    private let storageService: CustomSoundStorageServiceProtocol
    private let processService: ProcessMonitoringServiceProtocol
    private let interval: TimeInterval
    private nonisolated(unsafe) var monitoringTask: Task<Void, Never>?
    private var hasExceededThreshold = false
    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "MenuBarViewModel")

    // MARK: - Init

    init(
        service: CPUMonitoringServiceProtocol = CPUMonitoringService(),
        audioPlayer: AudioPlayerServiceProtocol = AudioPlayerService(),
        settings: AppSettings = AppSettings(),
        storageService: CustomSoundStorageServiceProtocol = CustomSoundStorageService(),
        processService: ProcessMonitoringServiceProtocol = ProcessMonitoringService(),
        interval: TimeInterval = 2.0
    ) {
        self.service = service
        self.audioPlayer = audioPlayer
        self.settings = settings
        self.storageService = storageService
        self.processService = processService
        self.interval = interval
        startMonitoring()
    }

    deinit {
        monitoringTask?.cancel()
    }

    // MARK: - Private Methods

    private func startMonitoring() {
        monitoringTask = Task { [weak self] in
            guard let self else { return }
            let stream = service.cpuUsageStream(interval: interval)

            for await result in stream {
                guard !Task.isCancelled else { break }
                switch result {
                case .success(let usage):
                    let rounded = Int(usage.rounded())
                    self.cpuUsage = rounded
                    self.permissionsError = false
                    await self.checkThreshold(cpuUsage: rounded)
                case .failure:
                    self.cpuUsage = nil
                    self.permissionsError = true
                }
            }
        }
    }

    private func checkThreshold(cpuUsage: Int) async {
        if cpuUsage >= settings.threshold {
            topProcesses = processService.topProcesses(limit: 5)
            if !hasExceededThreshold && settings.soundEnabled {
                hasExceededThreshold = true
                let allSounds = SoundOption.all(using: storageService)
                guard let sound = allSounds.first(where: { $0.id == self.settings.selectedSound }),
                      let url = sound.url else {
                    logger.warning("Could not resolve URL for sound '\(self.settings.selectedSound)', skipping playback")
                    return
                }
                await audioPlayer.playSound(url: url)
            }
        } else {
            hasExceededThreshold = false
            topProcesses = []
        }
    }
}
