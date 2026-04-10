//
//  MacInfoService.swift
//  Asado
//
//  Created by Fran Alarza on 11/4/26.
//

import Darwin
import Foundation
import os

// MARK: - Protocol

protocol MacInfoServiceProtocol: Sendable {
    func macInfo() -> MacInfo
}

// MARK: - Implementation

final class MacInfoService: MacInfoServiceProtocol {

    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "MacInfoService")

    func macInfo() -> MacInfo {
        let modelIdentifier = readSysctl("hw.model")
        let (macType, modelName) = resolveModel(from: modelIdentifier)
        let chipName = readSysctl("machdep.cpu.brand_string")
        let totalRAMGB = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824)

        let info = MacInfo(
            modelName: modelName,
            chipName: chipName,
            totalRAMGB: totalRAMGB,
            macType: macType
        )

        logger.info("[MacInfo] - \(info.modelName), \(info.chipName), \(info.totalRAMGB) GB (\(modelIdentifier))")

        return info
    }

    // MARK: - Private

    private func readSysctl(_ key: String) -> String {
        var size = 0
        sysctlbyname(key, nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return "" }
        return String(cString: buffer)
    }

    private func resolveModel(from identifier: String) -> (MacType, String) {
        if identifier.hasPrefix("MacBookPro") { return (.macBook, "MacBook Pro") }
        if identifier.hasPrefix("MacBookAir") { return (.macBook, "MacBook Air") }
        if identifier.hasPrefix("MacBook")    { return (.macBook, "MacBook") }
        if identifier.hasPrefix("Macmini")    { return (.macMini, "Mac mini") }
        if identifier.hasPrefix("iMac")       { return (.iMac, "iMac") }
        if identifier.hasPrefix("MacPro")     { return (.macPro, "Mac Pro") }
        if identifier.hasPrefix("Mac")        { return (.macStudio, "Mac Studio") }
        return (.generic, "Mac")
    }
}
