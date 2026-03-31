//
//  Item.swift
//  BurnDetector
//
//  Created by Fran Alarza on 31/3/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
