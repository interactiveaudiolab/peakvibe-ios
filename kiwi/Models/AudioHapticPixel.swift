//
//  AudioPixel.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import Foundation
import SwiftUI

struct AudioHapticPixel: Hashable, Codable, Identifiable {
    var id: Int
    var intensity: Float
    var sharpness: Float
}
