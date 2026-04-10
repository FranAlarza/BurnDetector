//
//  MenuBarViewModel.swift
//  Asado
//
//  Created by Fran Alarza on 31/3/26.
//

import AppKit
import Foundation
import os

@Observable
final class MenuBarViewModel {

    // MARK: - Published State

    private(set) var cpuUsage: Int?
    private(set) var permissionsError = false
    private(set) var topProcesses: [TopProcess] = []
    private(set) var freeDiskSpaceGB: Double?
    private(set) var isUpdateAvailable = false
    private(set) var batteryInfo: BatteryInfo = BatteryInfo(percentage: nil, chargingState: .unknown, health: nil)
    private(set) var memoryInfo: MemoryInfo?
    var settings: AppSettings

    // MARK: - Private

    private let service: CPUMonitoringServiceProtocol
    private let audioPlayer: AudioPlayerServiceProtocol
    private let storageService: CustomSoundStorageServiceProtocol
    private let processService: ProcessMonitoringServiceProtocol
    private let diskService: DiskMonitoringServiceProtocol
    private let batteryService: BatteryMonitoringServiceProtocol
    private let memoryService: MemoryMonitoringServiceProtocol
    private let updateChecker: UpdateCheckerServiceProtocol
    private let interval: TimeInterval
    private var monitoringTask: Task<Void, Never>?
    private var diskMonitoringTask: Task<Void, Never>?
    private var batteryMonitoringTask: Task<Void, Never>?
    private var memoryMonitoringTask: Task<Void, Never>?
    private var updateCheckTask: Task<Void, Never>?
    private var wakeObserverTask: Task<Void, Never>?
    private var hasExceededThreshold = false
    private var hasDiskExceededThreshold = false
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
        batteryService: BatteryMonitoringServiceProtocol = BatteryMonitoringService(),
        memoryService: MemoryMonitoringServiceProtocol = MemoryMonitoringService(),
        updateChecker: UpdateCheckerServiceProtocol = UpdateCheckerService(),
        updateCheckInterval: TimeInterval = 4 * 3600,
        interval: TimeInterval = 5.0,
        diskInterval: TimeInterval = 60.0,
        batteryInterval: TimeInterval = 30.0,
        memoryInterval: TimeInterval = 10.0
    ) {
        self.service = service
        self.audioPlayer = audioPlayer
        self.settings = settings
        self.storageService = storageService
        self.processService = processService
        self.diskService = diskService
        self.batteryService = batteryService
        self.memoryService = memoryService
        self.updateChecker = updateChecker
        self.interval = interval
        startMonitoring()
        startDiskMonitoring(interval: diskInterval)
        startBatteryMonitoring(interval: batteryInterval)
        startMemoryMonitoring(interval: memoryInterval)
        startUpdateChecking(interval: updateCheckInterval)
        startWakeObserver()
    }

    deinit {
        monitoringTask?.cancel()
        diskMonitoringTask?.cancel()
        batteryMonitoringTask?.cancel()
        memoryMonitoringTask?.cancel()
        updateCheckTask?.cancel()
        wakeObserverTask?.cancel()
    }

    // MARK: - Computed

    var diskValueLabel: String {
        guard let gb = freeDiskSpaceGB else { return "Free: -- GB" }
        return String(format: "Free: %.1f GB", gb)
    }

    var batteryValueLabel: String {
        guard let pct = batteryInfo.percentage else { return "--%"}
        return "\(pct)%"
    }

    var ramValueLabel: String {
        guard let info = memoryInfo else { return "Used: -- GB" }
        return String(format: "Used: %.1f / %.0f GB", info.usedGB, info.totalGB)
    }
}

// MARK: - Private Methods
private extension MenuBarViewModel {
    
    func startMonitoring() {
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
                    self.topProcesses = self.processService.topProcesses(limit: 20)
                    await self.checkThreshold(cpuUsage: rounded)
                case .failure:
                    self.cpuUsage = nil
                    self.permissionsError = true
                }
            }
        }
    }

    func startDiskMonitoring(interval: TimeInterval) {
        freeDiskSpaceGB = diskService.freeDiskSpaceGB()
        diskMonitoringTask = Task { [weak self] in
            guard let self else { return }
            await self.checkDiskThreshold()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                self.freeDiskSpaceGB = self.diskService.freeDiskSpaceGB()
                await self.checkDiskThreshold()
            }
        }
    }

    func startBatteryMonitoring(interval: TimeInterval) {
        batteryInfo = batteryService.batteryInfo()
        batteryMonitoringTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                self.batteryInfo = self.batteryService.batteryInfo()
            }
        }
    }

    func startMemoryMonitoring(interval: TimeInterval) {
        memoryInfo = memoryService.memoryInfo()
        memoryMonitoringTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                self.memoryInfo = self.memoryService.memoryInfo()
            }
        }
    }

    func startUpdateChecking(interval: TimeInterval) {
        updateCheckTask = Task { [weak self] in
            guard let self else { return }
            await self.checkForUpdates()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval), clock: .continuous)
                guard !Task.isCancelled else { break }
                await self.checkForUpdates()
            }
        }
    }

    func startWakeObserver() {
        wakeObserverTask = Task { [weak self] in
            guard let self else { return }
            for await _ in NSWorkspace.shared.notificationCenter.notifications(named: NSWorkspace.didWakeNotification) {
                guard !Task.isCancelled else { break }
                await self.checkForUpdates()
            }
        }
    }

    func checkForUpdates() async {
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

    func isNewer(_ latest: String, than current: String) -> Bool {
        let latestComponents = latest.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        for (latestValue, currentValue) in zip(latestComponents, currentComponents) {
            if latestValue != currentValue { return latestValue > currentValue }
        }
        return latestComponents.count > currentComponents.count
    }

    func checkThreshold(cpuUsage: Int) async {
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

    func checkDiskThreshold() async {
        guard let freeGB = freeDiskSpaceGB else { return }
        if freeGB < Double(settings.diskThresholdGB) {
            if !hasDiskExceededThreshold && settings.diskSoundEnabled {
                hasDiskExceededThreshold = true
                let allSounds = SoundOption.all(using: storageService)
                guard let sound = allSounds.first(where: { $0.id == self.settings.diskSelectedSound }),
                      let url = sound.url else {
                    logger.warning("Could not resolve URL for disk sound '\(self.settings.diskSelectedSound)', skipping playback")
                    return
                }
                await audioPlayer.playSound(url: url)
            }
        } else {
            hasDiskExceededThreshold = false
        }
    }
}
