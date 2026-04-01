import Foundation
import Testing
@testable import Asado

// MARK: - ProcessMonitoringService Tests

struct ProcessMonitoringServiceTests {

    @Test @MainActor
    func topProcessesReturnsAtMostLimit() {
        let sut = ProcessMonitoringService()
        // First call primes the snapshot; second call returns deltas
        _ = sut.topProcesses(limit: 3)
        let results = sut.topProcesses(limit: 3)

        #expect(results.count <= 3)
    }

    @Test @MainActor
    func topProcessesAreSortedDescending() {
        let sut = ProcessMonitoringService()
        _ = sut.topProcesses(limit: 5)
        let results = sut.topProcesses(limit: 5)

        for (a, b) in zip(results, results.dropFirst()) {
            #expect(a.cpuUsage >= b.cpuUsage)
        }
    }
}
