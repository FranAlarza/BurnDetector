import Foundation

@Observable
@MainActor
final class MenuBarViewModel {

    // MARK: - Published State

    private(set) var cpuUsage: Int?
    private(set) var permissionsError = false

    // MARK: - Private

    private let service: CPUMonitoringServiceProtocol
    private let interval: TimeInterval
    private var monitoringTask: Task<Void, Never>?

    // MARK: - Init

    init(service: CPUMonitoringServiceProtocol = CPUMonitoringService(), interval: TimeInterval = 2.0) {
        self.service = service
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
                    self.cpuUsage = Int(usage.rounded())
                    self.permissionsError = false
                case .failure:
                    self.cpuUsage = nil
                    self.permissionsError = true
                }
            }
        }
    }
}
