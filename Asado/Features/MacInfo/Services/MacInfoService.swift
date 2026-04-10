//
//  MacInfoService.swift
//  Asado
//
//  Created by Fran Alarza on 11/4/26.
//

import Darwin
import Foundation
import IOKit
import os

// MARK: - Protocol

protocol MacInfoServiceProtocol: Sendable {
    func macInfo() -> MacInfo
}

// MARK: - Implementation

final class MacInfoService: MacInfoServiceProtocol {

    private let logger = Logger(subsystem: "com.aweapps.Asado", category: "MacInfoService")

    func macInfo() -> MacInfo {
        // IOKit product-name gives the marketing name (e.g. "MacBook Pro") even on
        // new Apple Silicon Macs whose hw.model identifier is "Mac14,7" style.
        let productName = readIOKitProductName()
        let modelIdentifier = readSysctl("hw.model")

        // Use productName if available, otherwise fall back to parsing the identifier
        let (macType, modelName) = resolveModel(from: productName.isEmpty ? modelIdentifier : productName)

        let chipName = readSysctl("machdep.cpu.brand_string")
        let totalRAMGB = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824)

        let info = MacInfo(
            modelName: modelName,
            chipName: chipName,
            totalRAMGB: totalRAMGB,
            macType: macType
        )

        logger.info("[MacInfo] - \(info.modelName), \(info.chipName), \(info.totalRAMGB) GB (identifier: \(modelIdentifier), product-name: \(productName))")

        return info
    }

    // MARK: - Private

    private func readIOKitProductName() -> String {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != IO_OBJECT_NULL else { return "" }
        defer { IOObjectRelease(service) }

        guard let data = IORegistryEntryCreateCFProperty(
            service,
            "product-name" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Data else { return "" }

        // Data contains a null-terminated UTF-8 string
        return String(bytes: data.filter { $0 != 0 }, encoding: .utf8) ?? ""
    }

    private func readSysctl(_ key: String) -> String {
        var size = 0
        sysctlbyname(key, nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return "" }
        return String(cString: buffer)
    }

    private func resolveModel(from name: String) -> (MacType, String) {
        if name.hasPrefix("MacBook Pro") { return (.macBook, "MacBook Pro") }
        if name.hasPrefix("MacBook Air") { return (.macBook, "MacBook Air") }
        if name.hasPrefix("MacBookPro")  { return (.macBook, "MacBook Pro") }
        if name.hasPrefix("MacBookAir")  { return (.macBook, "MacBook Air") }
        if name.hasPrefix("MacBook")     { return (.macBook, "MacBook") }
        if name.hasPrefix("Mac mini")    { return (.macMini, "Mac mini") }
        if name.hasPrefix("Macmini")     { return (.macMini, "Mac mini") }
        if name.hasPrefix("iMac")        { return (.iMac, "iMac") }
        if name.hasPrefix("Mac Pro")     { return (.macPro, "Mac Pro") }
        if name.hasPrefix("MacPro")      { return (.macPro, "Mac Pro") }
        if name.hasPrefix("Mac Studio")  { return (.macStudio, "Mac Studio") }
        if name.hasPrefix("Mac")         { return (.generic, "Mac") }
        return (.generic, "Mac")
    }
}
