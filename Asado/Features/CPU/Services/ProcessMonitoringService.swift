//
//  ProcessMonitoringService.swift
//  Asado
//
//  Created by Fran Alarza on 1/4/26.
//

import AppKit
import Darwin
import Foundation
import os

// MARK: - Protocol

protocol ProcessMonitoringServiceProtocol: Sendable {
    func topProcesses(limit: Int) -> [TopProcess]
}

// MARK: - Implementation

final class ProcessMonitoringService: ProcessMonitoringServiceProtocol, @unchecked Sendable {

    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "ProcessMonitoring")

    // MARK: - Private state

    private struct ProcessTicks {
        let user: UInt64
        let system: UInt64
    }

    private var previousSnapshot: [Int32: ProcessTicks] = [:]
    private var lastSampleDate: Date = .distantPast

    // MARK: - Public

    func topProcesses(limit: Int) -> [TopProcess] {
        let now = Date()
        let elapsedNs = now.timeIntervalSince(lastSampleDate) * 1_000_000_000
        logger.debug("topProcesses called — elapsedNs=\(elapsedNs, format: .fixed(precision: 0)), previousSnapshot.count=\(self.previousSnapshot.count)")
        guard elapsedNs > 0 else {
            logger.warning("topProcesses: elapsedNs <= 0, returning empty")
            return []
        }

        let pids = allPIDs()
        logger.debug("topProcesses: found \(pids.count) PIDs")
        guard !pids.isEmpty else {
            logger.error("topProcesses: allPIDs() returned empty")
            return []
        }

        var currentSnapshot: [Int32: ProcessTicks] = [:]
        var results: [TopProcess] = []
        var pidInfoFailures = 0

        for pid in pids {
            var info = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.size)
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size)
            guard ret == size else {
                pidInfoFailures += 1
                continue
            }

            let current = ProcessTicks(user: info.pti_total_user, system: info.pti_total_system)
            currentSnapshot[pid] = current

            guard let previous = previousSnapshot[pid] else { continue }

            let deltaUser = current.user >= previous.user ? current.user - previous.user : 0
            let deltaSystem = current.system >= previous.system ? current.system - previous.system : 0
            let cpuUsage = (Double(deltaUser + deltaSystem) / elapsedNs) * 100.0

            guard cpuUsage > 0 else { continue }

            let (name, icon) = resolveNameAndIcon(for: pid)
            results.append(TopProcess(id: pid, name: name, cpuUsage: cpuUsage, icon: icon))
        }

        logger.debug("topProcesses: pidInfoFailures=\(pidInfoFailures), processes with cpuUsage>0: \(results.count), currentSnapshot.count=\(currentSnapshot.count)")

        previousSnapshot = currentSnapshot
        lastSampleDate = now

        let sorted = Array(results.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(limit))
        logger.info("topProcesses returning \(sorted.count) entries: \(sorted.map { "\($0.name)=\(String(format: "%.1f", $0.cpuUsage))%" }.joined(separator: ", "))")
        return sorted
    }

    // MARK: - Private

    private func allPIDs() -> [Int32] {
        let byteCount = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard byteCount > 0 else {
            logger.error("allPIDs: proc_listpids(nil) returned \(byteCount), errno=\(errno)")
            return []
        }

        var buffer = [Int32](repeating: 0, count: Int(byteCount) / MemoryLayout<Int32>.size)
        let written = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &buffer, byteCount)
        guard written > 0 else {
            logger.error("allPIDs: proc_listpids(buffer) returned \(written), errno=\(errno)")
            return []
        }

        let count = Int(written) / MemoryLayout<Int32>.size
        return buffer.prefix(count).filter { $0 > 0 }
    }

    private func resolveNameAndIcon(for pid: Int32) -> (String, NSImage?) {
        if let app = NSRunningApplication(processIdentifier: pid) {
            let name = app.localizedName ?? app.bundleIdentifier ?? rawName(for: pid)
            return (name, app.icon)
        }
        return (rawName(for: pid), nil)
    }

    private func rawName(for pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 1024)
        proc_name(pid, &buffer, UInt32(buffer.count))
        let name = String(cString: buffer)
        return name.isEmpty ? "Unknown" : name
    }
}
