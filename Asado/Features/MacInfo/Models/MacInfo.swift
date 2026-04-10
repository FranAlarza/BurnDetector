//
//  MacInfo.swift
//  Asado
//
//  Created by Fran Alarza on 11/4/26.
//

import Foundation

// MARK: - MacType

enum MacType: Sendable {
    case macBook
    case macMini
    case iMac
    case macPro
    case macStudio
    case generic

    var symbolName: String {
        switch self {
        case .macBook:   return "laptopcomputer"
        case .macMini:   return "macmini"
        case .iMac:      return "desktopcomputer"
        case .macPro:    return "macpro.gen3"
        case .macStudio: return "macstudio"
        case .generic:   return "desktopcomputer"
        }
    }
}

// MARK: - MacInfo

struct MacInfo: Sendable {
    let modelName: String
    let chipName: String
    let totalRAMGB: Int
    let macType: MacType

    var subtitleLabel: String {
        if chipName.isEmpty {
            return "\(totalRAMGB) GB"
        }
        return "\(chipName) · \(totalRAMGB) GB"
    }

    static var fallback: MacInfo {
        MacInfo(modelName: "Mac", chipName: "", totalRAMGB: 0, macType: .generic)
    }
}
