//
//  MemoryInfo.swift
//  Asado
//
//  Created by Fran Alarza on 10/4/26.
//

import Foundation

struct MemoryInfo: Sendable {
    let usedGB: Double
    let totalGB: Double
    let percentageUsed: Int
}
