//
//  DiskMonitoringService.swift
//  Asado
//
//  Created by Fran Alarza on 5/4/26.
//

import Foundation

// MARK: - Protocol

protocol DiskMonitoringServiceProtocol: Sendable {
    func freeDiskSpaceGB() -> Double?
}

// MARK: - Implementation

struct DiskMonitoringService: DiskMonitoringServiceProtocol {

    func freeDiskSpaceGB() -> Double? {
        let url = URL(fileURLWithPath: "/")
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let bytes = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }
        return Double(bytes) / 1_073_741_824
    }
}
