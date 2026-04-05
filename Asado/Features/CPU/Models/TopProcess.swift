//
//  TopProcess.swift
//  Asado
//
//  Created by Fran Alarza on 1/4/26.
//

import AppKit

struct TopProcess: Identifiable, @unchecked Sendable {
    let id: Int32
    let name: String
    let cpuUsage: Double
    let icon: NSImage?
}
