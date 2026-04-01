import Foundation
import Testing
@testable import BurnDetector

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
        let viewModel = MenuBarViewModel(service: service)

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.cpuUsage == 42)
        #expect(viewModel.permissionsError == false)
    }

    @Test @MainActor
    func failureSetsPermissionsError() async throws {
        let service = MockCPUMonitoringService(results: [.failure(CPUMonitoringError.permissionDenied)])
        let viewModel = MenuBarViewModel(service: service)

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
        let viewModel = MenuBarViewModel(service: service)

        try await Task.sleep(for: .milliseconds(500))

        #expect(viewModel.cpuUsage == 76)
        #expect(viewModel.permissionsError == false)
    }

    @Test @MainActor
    func usageRoundsToNearestInt() async throws {
        let service = MockCPUMonitoringService(results: [.success(99.5)])
        let viewModel = MenuBarViewModel(service: service)

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
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings)

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
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings)

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
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings)

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
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings)

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
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings)

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
        let viewModel = MenuBarViewModel(service: service, audioPlayer: audio, settings: settings)

        try await Task.sleep(for: .milliseconds(500))

        #expect(audio.playCount == 1)
        #expect(audio.lastPlayedURL?.lastPathComponent == "sheep.mp3")
        _ = viewModel
    }
}
