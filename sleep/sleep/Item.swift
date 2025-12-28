//
//  Item.swift
//  sleep
//
//  Created by Actor on 2025/12/28.
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
