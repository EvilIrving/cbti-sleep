//
//  Item.swift
//  cbti-sleep
//
//  Created by Actor on 2026/3/6.
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
