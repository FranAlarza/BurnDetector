//
//  MemoryMonitoringService.swift
//  Asado
//
//  Created by Fran Alarza on 10/4/26.
//

import Darwin
import Foundation
import os

// MARK: - Protocol

protocol MemoryMonitoringServiceProtocol: Sendable {
    func memoryInfo() -> MemoryInfo?
}

// MARK: - Implementation

final class MemoryMonitoringService: MemoryMonitoringServiceProtocol {

    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "MemoryMonitoringService")

    func memoryInfo() -> MemoryInfo? {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let pageSize = UInt64(vm_kernel_page_size)

        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &vmStats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPointer in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    intPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            logger.error("[Memory] - Failed to read VM statistics (kern_return: \(result))")
            return nil
        }

        let usedPages = UInt64(vmStats.active_count) + UInt64(vmStats.wire_count) + UInt64(vmStats.compressor_page_count)
        let usedBytes = usedPages * pageSize
        let bytesPerGB = 1_073_741_824.0
        let usedGB = Double(usedBytes) / bytesPerGB
        let totalGB = Double(totalBytes) / bytesPerGB
        let percentageUsed = Int((usedGB / totalGB) * 100)

        logger.debug("[Memory] - Used: \(String(format: "%.1f", usedGB)) GB / \(String(format: "%.0f", totalGB)) GB (\(percentageUsed)%)")

        return MemoryInfo(usedGB: usedGB, totalGB: totalGB, percentageUsed: percentageUsed)
    }
}
