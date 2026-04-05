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
    private(set) var freeDiskSpaceGB: Double?
    private(set) var isUpdateAvailable = false
    var settings: AppSettings

    // MARK: - Private

    private let service: CPUMonitoringServiceProtocol
    private let audioPlayer: AudioPlayerServiceProtocol
    private let storageService: CustomSoundStorageServiceProtocol
    private let processService: ProcessMonitoringServiceProtocol
    private let diskService: DiskMonitoringServiceProtocol
    private let updateChecker: UpdateCheckerServiceProtocol
    private let interval: TimeInterval
    private nonisolated(unsafe) var monitoringTask: Task<Void, Never>?
    private nonisolated(unsafe) var diskMonitoringTask: Task<Void, Never>?
    private var hasExceededThreshold = false
    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "MenuBarViewModel")

    let releasesURL = URL(string: "https://github.com/FranAlarza/Asado/releases/latest")!

    // MARK: - Init

    init(
        service: CPUMonitoringServiceProtocol = CPUMonitoringService(),
        audioPlayer: AudioPlayerServiceProtocol = AudioPlayerService(),
        settings: AppSettings = AppSettings(),
        storageService: CustomSoundStorageServiceProtocol = CustomSoundStorageService(),
        processService: ProcessMonitoringServiceProtocol = ProcessMonitoringService(),
        diskService: DiskMonitoringServiceProtocol = DiskMonitoringService(),
        updateChecker: UpdateCheckerServiceProtocol = UpdateCheckerService(),
        interval: TimeInterval = 5.0,
        diskInterval: TimeInterval = 60.0
    ) {
        self.service = service
        self.audioPlayer = audioPlayer
        self.settings = settings
        self.storageService = storageService
        self.processService = processService
        self.diskService = diskService
        self.updateChecker = updateChecker
        self.interval = interval
        startMonitoring()
        startDiskMonitoring(interval: diskInterval)
        Task { await checkForUpdates() }
    }

    deinit {
        monitoringTask?.cancel()
        diskMonitoringTask?.cancel()
    }

    // MARK: - Computed

    var diskValueLabel: String {
        guard let gb = freeDiskSpaceGB else { return "Free: -- GB" }
        return String(format: "Free: %.1f GB", gb)
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
                    self.topProcesses = self.processService.topProcesses(limit: 5)
                    await self.checkThreshold(cpuUsage: rounded)
                case .failure:
                    self.cpuUsage = nil
                    self.permissionsError = true
                }
            }
        }
    }

    private func startDiskMonitoring(interval: TimeInterval) {
        freeDiskSpaceGB = diskService.freeDiskSpaceGB()
        diskMonitoringTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                self.freeDiskSpaceGB = self.diskService.freeDiskSpaceGB()
            }
        }
    }

    private func checkForUpdates() async {
        logger.info("Checking for updates...")
        guard let latest = await updateChecker.fetchLatestVersion() else {
            logger.warning("Update check failed: could not fetch latest version")
            return
        }
        guard let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            logger.warning("Update check failed: could not read current version from bundle")
            return
        }
        let newer = isNewer(latest, than: current)
        if newer {
            logger.info("Update available: \(current) → \(latest)")
        } else {
            logger.info("App is up to date (current: \(current), latest: \(latest))")
        }
        isUpdateAvailable = newer
    }

    private func isNewer(_ latest: String, than current: String) -> Bool {
        let l = latest.split(separator: ".").compactMap { Int($0) }
        let c = current.split(separator: ".").compactMap { Int($0) }
        for (lv, cv) in zip(l, c) {
            if lv != cv { return lv > cv }
        }
        return l.count > c.count
    }

    private func checkThreshold(cpuUsage: Int) async {
        if cpuUsage >= settings.threshold {
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
        }
    }
}
