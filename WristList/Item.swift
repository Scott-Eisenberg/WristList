//
//  Item.swift
//  WristList
//
//  Created by Scott Eisenberg on 9/7/26.
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
