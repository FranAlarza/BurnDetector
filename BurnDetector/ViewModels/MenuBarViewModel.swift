import Foundation

@Observable
@MainActor
final class MenuBarViewModel {

    // MARK: - Published State

    private(set) var cpuUsage: Int?
    private(set) var permissionsError = false
    var settings: AppSettings

    // MARK: - Private

    private let service: CPUMonitoringServiceProtocol
    private let audioPlayer: AudioPlayerServiceProtocol
    private let interval: TimeInterval
    private nonisolated(unsafe) var monitoringTask: Task<Void, Never>?
    private var hasExceededThreshold = false

    // MARK: - Init

    init(
        service: CPUMonitoringServiceProtocol = CPUMonitoringService(),
        audioPlayer: AudioPlayerServiceProtocol = AudioPlayerService(),
        settings: AppSettings = AppSettings(),
        interval: TimeInterval = 2.0
    ) {
        self.service = service
        self.audioPlayer = audioPlayer
        self.settings = settings
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
            if !hasExceededThreshold && settings.soundEnabled {
                hasExceededThreshold = true
                await audioPlayer.playScream()
            }
        } else {
            hasExceededThreshold = false
        }
    }
}
