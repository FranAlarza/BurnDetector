import Foundation
import Testing
@testable import Asado

// MARK: - Mock CPU Service

struct MockCPUMonitoringService: CPUMonitoringServiceProtocol {
    let results: [Result<Double, Error>]

    func cpuUsageStream(interval: TimeInterval) -> AsyncStream<Result<Double, Error>> {
        AsyncStream { continuation in
            for result in results {
                continuation.yield(result)
            }
            continuation.finish()
        }
    }
}

// MARK: - Mock Audio Service

final class MockAudioPlayerService: AudioPlayerServiceProtocol, @unchecked Sendable {
    private(set) var playCount = 0
    private(set) var lastPlayedURL: URL?

    func playSound(url: URL) async {
        playCount += 1
        lastPlayedURL = url
    }
}

// MARK: - Mock Process Service

struct MockProcessMonitoringService: ProcessMonitoringServiceProtocol {
    let processes: [TopProcess]

    func topProcesses(limit: Int) -> [TopProcess] {
        Array(processes.prefix(limit))
    }
}

// MARK: - Mock Disk Service

struct MockDiskMonitoringService: DiskMonitoringServiceProtocol {
    let value: Double?
    func freeDiskSpaceGB() -> Double? { value }
}

// MARK: - Mock Update Checker Service

struct MockUpdateCheckerService: UpdateCheckerServiceProtocol {
    let version: String?
    func fetchLatestVersion() async -> String? { version }
}

// MARK: - Mock Storage Service

struct MockCustomSoundStorageService: CustomSoundStorageServiceProtocol {
    var storageDirectory: URL { URL(fileURLWithPath: "/tmp/test-sounds") }
    var customSounds: [SoundOption] = []

    func importSound(from source: URL) throws -> SoundOption {
        SoundOption(id: source.path, displayName: source.deletingPathExtension().lastPathComponent.capitalized, isCustom: true)
    }
    func deleteSound(_ sound: SoundOption) throws {}
    func allCustomSounds() -> [SoundOption] { customSounds }
}

// MARK: - CPU Usage Tests

struct MenuBarViewModelTests {

    @Test @MainActor
    func successUpdatesUsage() async throws {
        let service = MockCPUMonitoringService(results: [.success(42.3)])
        let viewModel = MenuBarViewModel(service: service, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.cpuUsage == 42)
        #expect(viewModel.permissionsError == false)
    }

    @Test @MainActor
    func failureSetsPermissionsError() async throws {
        let service = MockCPUMonitoringService(results: [.failure(CPUMonitoringError.permissionDenied)])
        let viewModel = MenuBarViewModel(service: service, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.cpuUsage == nil)
        #expect(viewModel.permissionsError == true)
    }

    @Test @MainActor
    func successAfterFailureClearsError() async throws {
        let service = MockCPUMonitoringService(results: [
            .failure(CPUMonitoringError.permissionDenied),
            .success(75.6)
        ])
        let viewModel = MenuBarViewModel(service: service, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.cpuUsage == 76)
        #expect(viewModel.permissionsError == false)
    }

    @Test @MainActor
    func usageRoundsToNearestInt() async throws {
        let service = MockCPUMonitoringService(results: [.success(99.5)])
        let viewModel = MenuBarViewModel(service: service, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.cpuUsage == 100)
    }
}

// MARK: - Threshold Alert Tests

@Suite(.serialized)
struct ThresholdAlertTests {

    init() {
        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: "selectedSound")
    }

    @Test @MainActor
    func soundPlaysWhenCrossingThresholdUpward() async throws {
        let audio = MockAudioPlayerService()
        let service = MockCPUMonitoringService(results: [.success(95.0)])
        let settings = AppSettings()
        settings.threshold = 90
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 1)
        #expect(audio.lastPlayedURL != nil)
        _ = viewModel
    }

    @Test @MainActor
    func soundDoesNotPlayWhenBelowThreshold() async throws {
        let audio = MockAudioPlayerService()
        let service = MockCPUMonitoringService(results: [.success(50.0)])
        let settings = AppSettings()
        settings.threshold = 90
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 0)
        _ = viewModel
    }

    @Test @MainActor
    func soundDoesNotRepeatWhileAboveThreshold() async throws {
        let audio = MockAudioPlayerService()
        let service = MockCPUMonitoringService(results: [.success(95.0), .success(97.0), .success(92.0)])
        let settings = AppSettings()
        settings.threshold = 90
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 1)
        _ = viewModel
    }

    @Test @MainActor
    func soundPlaysAgainAfterDroppingAndRising() async throws {
        let audio = MockAudioPlayerService()
        let service = MockCPUMonitoringService(results: [.success(95.0), .success(80.0), .success(95.0)])
        let settings = AppSettings()
        settings.threshold = 90
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 2)
        _ = viewModel
    }

    @Test @MainActor
    func soundDoesNotPlayWhenDisabled() async throws {
        let audio = MockAudioPlayerService()
        let service = MockCPUMonitoringService(results: [.success(95.0)])
        let settings = AppSettings()
        settings.threshold = 90
        settings.soundEnabled = false
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 0)
        _ = viewModel
    }

    @Test @MainActor
    func soundUsesSelectedSound() async throws {
        let audio = MockAudioPlayerService()
        let service = MockCPUMonitoringService(results: [.success(95.0)])
        let settings = AppSettings()
        settings.threshold = 90
        settings.selectedSound = "sheep"
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings, processService: MockProcessMonitoringService(processes: []), diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 1)
        #expect(audio.lastPlayedURL?.lastPathComponent == "sheep.mp3")
        _ = viewModel
    }
}

// MARK: - Top Process Tests

@Suite(.serialized)
struct TopProcessTests {

    init() {
        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: "selectedSound")
    }

    @Test @MainActor
    func topProcessesPopulatedWhenAboveThreshold() async throws {
        let mockProcesses = [
            TopProcess(id: 1, name: "Safari", cpuUsage: 50.0, icon: nil),
            TopProcess(id: 2, name: "Xcode", cpuUsage: 30.0, icon: nil),
            TopProcess(id: 3, name: "mdworker", cpuUsage: 10.0, icon: nil)
        ]
        let processService = MockProcessMonitoringService(processes: mockProcesses)
        let cpuService = MockCPUMonitoringService(results: [.success(95.0)])
        let settings = AppSettings()
        settings.threshold = 90
        let viewModel = MenuBarViewModel(service: cpuService, audioPlayer: MockAudioPlayerService(), settings: settings, processService: processService, diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.topProcesses.count == 3)
        #expect(viewModel.topProcesses.first?.name == "Safari")
        _ = viewModel
    }

    @Test @MainActor
    func topProcessesAlwaysPopulatedRegardlessOfThreshold() async throws {
        let mockProcesses = [
            TopProcess(id: 1, name: "Safari", cpuUsage: 50.0, icon: nil)
        ]
        let processService = MockProcessMonitoringService(processes: mockProcesses)
        let cpuService = MockCPUMonitoringService(results: [.success(95.0), .success(20.0)])
        let settings = AppSettings()
        settings.threshold = 90
        let viewModel = MenuBarViewModel(service: cpuService, audioPlayer: MockAudioPlayerService(), settings: settings, processService: processService, diskService: MockDiskMonitoringService(value: nil), updateChecker: MockUpdateCheckerService(version: nil))

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.topProcesses.count == 1)
        _ = viewModel
    }
}

// MARK: - Disk Alert Tests

@Suite(.serialized)
struct DiskAlertTests {

    init() {
        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        UserDefaults.standard.removeObject(forKey: "selectedSound")
        UserDefaults.standard.removeObject(forKey: "diskThresholdGB")
        UserDefaults.standard.removeObject(forKey: "diskSoundEnabled")
        UserDefaults.standard.removeObject(forKey: "diskSelectedSound")
    }

    @Test @MainActor
    func diskSoundPlaysWhenFreeBelowThreshold() async throws {
        let audio = MockAudioPlayerService()
        let settings = AppSettings()
        settings.diskThresholdGB = 50
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            audioPlayer: audio,
            settings: settings,
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: 30.0),
            updateChecker: MockUpdateCheckerService(version: nil),
            diskInterval: 3600
        )

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 1)
        _ = viewModel
    }

    @Test @MainActor
    func diskSoundDoesNotPlayWhenFreeAboveThreshold() async throws {
        let audio = MockAudioPlayerService()
        let settings = AppSettings()
        settings.diskThresholdGB = 50
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            audioPlayer: audio,
            settings: settings,
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: 80.0),
            updateChecker: MockUpdateCheckerService(version: nil),
            diskInterval: 3600
        )

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 0)
        _ = viewModel
    }

    @Test @MainActor
    func diskSoundDoesNotPlayWhenDisabled() async throws {
        let audio = MockAudioPlayerService()
        let settings = AppSettings()
        settings.diskThresholdGB = 50
        settings.diskSoundEnabled = false
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            audioPlayer: audio,
            settings: settings,
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: 30.0),
            updateChecker: MockUpdateCheckerService(version: nil),
            diskInterval: 3600
        )

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 0)
        _ = viewModel
    }

    @Test @MainActor
    func diskSoundDoesNotRepeatWhileStillBelow() async throws {
        let audio = MockAudioPlayerService()
        let settings = AppSettings()
        settings.diskThresholdGB = 50
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            audioPlayer: audio,
            settings: settings,
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: 30.0),
            updateChecker: MockUpdateCheckerService(version: nil),
            diskInterval: 0.1
        )

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 1)
        _ = viewModel
    }
}

// MARK: - Disk Label Tests

struct DiskLabelTests {

    @Test @MainActor
    func diskValueLabelShowsFormattedGB() {
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: 128.0),
            updateChecker: MockUpdateCheckerService(version: nil)
        )

        #expect(viewModel.diskValueLabel == "Free: 128.0 GB")
    }

    @Test @MainActor
    func diskValueLabelShowsFallbackWhenNil() {
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: nil),
            updateChecker: MockUpdateCheckerService(version: nil)
        )

        #expect(viewModel.diskValueLabel == "Free: -- GB")
    }
}

// MARK: - Update Checker Tests

struct UpdateCheckerTests {

    @Test @MainActor
    func isUpdateAvailableWhenNewerVersion() async throws {
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: nil),
            updateChecker: MockUpdateCheckerService(version: "99.0.0")
        )

        try await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.isUpdateAvailable == true)
    }

    @Test @MainActor
    func isUpdateNotAvailableWhenSameVersion() async throws {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: nil),
            updateChecker: MockUpdateCheckerService(version: current)
        )

        try await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.isUpdateAvailable == false)
    }

    @Test @MainActor
    func isUpdateNotAvailableWhenNil() async throws {
        let viewModel = MenuBarViewModel(
            service: MockCPUMonitoringService(results: []),
            processService: MockProcessMonitoringService(processes: []),
            diskService: MockDiskMonitoringService(value: nil),
            updateChecker: MockUpdateCheckerService(version: nil)
        )

        try await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.isUpdateAvailable == false)
    }
}
