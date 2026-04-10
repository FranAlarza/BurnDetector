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

    // MARK: - Lookup table for Apple Silicon "MacXX,YY" identifiers
    // Old format identifiers ("MacBookPro18,3") are handled by prefix matching below.

    private static let modelLookup: [String: (MacType, String)] = [
        // M1 generation
        "Mac12,1": (.macStudio, "Mac Studio"),   // placeholder — no Mac Studio M1 in this range
        "Mac13,1": (.macStudio, "Mac Studio"),
        "Mac13,2": (.macStudio, "Mac Studio"),
        // M2 generation
        "Mac14,2":  (.macBook, "MacBook Air"),
        "Mac14,3":  (.macMini, "Mac mini"),
        "Mac14,5":  (.macBook, "MacBook Pro"),
        "Mac14,6":  (.macBook, "MacBook Pro"),
        "Mac14,7":  (.macBook, "MacBook Pro"),
        "Mac14,8":  (.macPro,  "Mac Pro"),
        "Mac14,9":  (.macBook, "MacBook Pro"),
        "Mac14,10": (.macBook, "MacBook Pro"),
        "Mac14,12": (.macMini, "Mac mini"),
        "Mac14,13": (.macStudio, "Mac Studio"),
        "Mac14,14": (.macStudio, "Mac Studio"),
        "Mac14,15": (.macBook, "MacBook Air"),
        // M3 generation
        "Mac15,3":  (.macBook, "MacBook Pro"),
        "Mac15,4":  (.iMac,   "iMac"),
        "Mac15,5":  (.iMac,   "iMac"),
        "Mac15,6":  (.macBook, "MacBook Pro"),
        "Mac15,7":  (.macBook, "MacBook Pro"),
        "Mac15,8":  (.macBook, "MacBook Pro"),
        "Mac15,9":  (.macBook, "MacBook Pro"),
        "Mac15,10": (.macBook, "MacBook Pro"),
        "Mac15,11": (.macBook, "MacBook Pro"),
        "Mac15,12": (.macBook, "MacBook Air"),
        "Mac15,13": (.macBook, "MacBook Air"),
        // M4 generation
        "Mac16,1":  (.macBook, "MacBook Pro"),
        "Mac16,2":  (.macBook, "MacBook Air"),
        "Mac16,3":  (.macBook, "MacBook Air"),
        "Mac16,5":  (.macMini, "Mac mini"),
        "Mac16,6":  (.macMini, "Mac mini"),
        "Mac16,7":  (.macBook, "MacBook Pro"),
        "Mac16,8":  (.macBook, "MacBook Pro"),
        "Mac16,10": (.macBook, "MacBook Pro"),
        "Mac16,11": (.macBook, "MacBook Pro"),
        "Mac16,12": (.iMac,   "iMac"),
        "Mac16,15": (.macStudio, "Mac Studio"),
        "Mac16,16": (.macStudio, "Mac Studio"),
    ]

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

        logger.info("[MacInfo] - \(info.modelName), \(info.chipName), \(info.totalRAMGB) GB (identifier: \(modelIdentifier))")

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
        // 1. Exact lookup — handles new-format Apple Silicon identifiers ("Mac14,10" etc.)
        if let match = MacInfoService.modelLookup[identifier] {
            return match
        }
        // 2. Prefix matching — handles old-format identifiers ("MacBookPro18,3" etc.)
        if identifier.hasPrefix("MacBook Pro") { return (.macBook, "MacBook Pro") }
        if identifier.hasPrefix("MacBook Air") { return (.macBook, "MacBook Air") }
        if identifier.hasPrefix("MacBookPro")  { return (.macBook, "MacBook Pro") }
        if identifier.hasPrefix("MacBookAir")  { return (.macBook, "MacBook Air") }
        if identifier.hasPrefix("MacBook")     { return (.macBook, "MacBook") }
        if identifier.hasPrefix("Mac mini")    { return (.macMini, "Mac mini") }
        if identifier.hasPrefix("Macmini")     { return (.macMini, "Mac mini") }
        if identifier.hasPrefix("iMac")        { return (.iMac,   "iMac") }
        if identifier.hasPrefix("Mac Pro")     { return (.macPro,  "Mac Pro") }
        if identifier.hasPrefix("MacPro")      { return (.macPro,  "Mac Pro") }
        if identifier.hasPrefix("Mac Studio")  { return (.macStudio, "Mac Studio") }
        return (.generic, "Mac")
    }
}
