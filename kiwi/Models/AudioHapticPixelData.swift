//
//  AudioHapticPixelData.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import Foundation
import Combine
import SwiftUI
import SwiftUIOSC
import XCTest
import CoreHaptics

final class PixelData: ObservableObject {
    @Published var pixels: [AudioHapticPixel] = []
    @ObservedObject var osc: OSC = .shared
    
    // assumes that array of pixels has continously increasing ids
    func addPixels(_ newPixels: inout [AudioHapticPixel]) {
        if (self.pixels.isEmpty) {
            self.pixels = newPixels
            return
        }
        
        if (newPixels.isEmpty) {
            return
        }
        
        var startOffset = newPixels.first!.id - self.pixels.first!.id
        var endOffset = newPixels.last!.id - self.pixels.last!.id
        
        // if the startOffset is negative,
        // it means we need to insert pixels at the beginning
        while (startOffset < 0) {
            self.pixels.insert(newPixels.removeFirst(), at: 0)
            startOffset += 1
        }
        
        // if the endOffset is positive
        // it means we need to insert pixels at the end
        while (endOffset > 0) {
            self.pixels.insert(newPixels.popLast()!, at: self.pixels.count)
            endOffset -= 1
        }
        
        // now that bounds have been adjusted, just replace the subrange
        let localStartIdx = newPixels.first!.id - self.pixels.first!.id
        let localEndIdx = localStartIdx + newPixels.count
        self.pixels.replaceSubrange(localStartIdx...localEndIdx, with: newPixels)
    }
    
    
    func prepare() {
        let stat: Bool = true
        osc.send(Bool.convert(values: stat.values), at: "/init") // ??
        
        osc.receive(on: "/pixel", { values in
            let pixelsStr: String = .convert(values: values)
            let newPixel: AudioHapticPixel = loadFromString(pixelsStr) ?? AudioHapticPixel.init(id: 0, value: 0)
            var newPixels = [newPixel]
            
            self.addPixels(&newPixels)
        })
        
        osc.receive(on: "/pixels", { values in
            let pixelsStr: String = .convert(values: values)
            var newPixels: [AudioHapticPixel] = loadFromString(pixelsStr) ?? []
            
            self.addPixels(&newPixels)
        })
    }
}

func loadFromFile<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}


func loadFromString<T: Decodable>(_ json: String) -> T? {
    let data = Data(json.utf8)
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        print("Couldn't parse json string as \(T.self):\n\(error)")
        return nil
    }
}
