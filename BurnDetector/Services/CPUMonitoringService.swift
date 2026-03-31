import Foundation

// MARK: - Protocol

protocol CPUMonitoringServiceProtocol: Sendable {
    func cpuUsageStream(interval: TimeInterval) -> AsyncStream<Result<Double, Error>>
}

// MARK: - Errors

enum CPUMonitoringError: Error, LocalizedError {
    case permissionDenied
    case readFailed(kern_return_t)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied to read CPU statistics"
        case .readFailed(let status):
            return "Failed to read CPU statistics (kern_return: \(status))"
        }
    }
}

// MARK: - Implementation

final class CPUMonitoringService: CPUMonitoringServiceProtocol {

    func cpuUsageStream(interval: TimeInterval) -> AsyncStream<Result<Double, Error>> {
        AsyncStream { continuation in
            let task = Task {
                var previousTicks = self.readCPUTicks()

                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(interval))
                    guard !Task.isCancelled else { break }

                    let currentTicks = self.readCPUTicks()

                    switch (previousTicks, currentTicks) {
                    case (.success(let previous), .success(let current)):
                        let usage = self.computeUsage(previous: previous, current: current)
                        continuation.yield(.success(usage))
                        previousTicks = currentTicks

                    case (_, .failure(let error)):
                        continuation.yield(.failure(error))

                    case (.failure, .success):
                        // First successful read after a failure — store ticks, wait for next delta
                        previousTicks = currentTicks
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Private

    private struct CPUTicks: Sendable {
        let user: UInt32
        let system: UInt32
        let idle: UInt32
        let nice: UInt32
    }

    private func readCPUTicks() -> Result<CPUTicks, Error> {
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &loadInfo) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPointer in
                host_statistics64(
                    mach_host_self(),
                    HOST_CPU_LOAD_INFO,
                    intPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            if result == KERN_NO_ACCESS || result == KERN_PROTECTION_FAILURE {
                return .failure(CPUMonitoringError.permissionDenied)
            }
            return .failure(CPUMonitoringError.readFailed(result))
        }

        return .success(CPUTicks(
            user: loadInfo.cpu_ticks.0,
            system: loadInfo.cpu_ticks.1,
            idle: loadInfo.cpu_ticks.2,
            nice: loadInfo.cpu_ticks.3
        ))
    }

    private func computeUsage(previous: CPUTicks, current: CPUTicks) -> Double {
        let userDelta = Double(current.user &- previous.user)
        let systemDelta = Double(current.system &- previous.system)
        let idleDelta = Double(current.idle &- previous.idle)
        let niceDelta = Double(current.nice &- previous.nice)

        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta

        guard totalDelta > 0 else { return 0 }

        return ((userDelta + systemDelta + niceDelta) / totalDelta) * 100.0
    }
}
