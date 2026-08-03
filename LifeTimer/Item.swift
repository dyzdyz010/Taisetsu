//
//  Item.swift
//  LifeTimer
//
//  Created by 杜艺卓 on 2026/8/3.
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
