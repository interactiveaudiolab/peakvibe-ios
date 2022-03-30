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

final class PixelData: ObservableObject {
    @Published var pixels: [AudioHapticPixel] = []
    @ObservedObject var osc: OSC = .shared
    
    
    func prepare() {
        let stat: Bool = true
        osc.send(Bool.convert(values: stat.values), at: "/init") // ??
        
        osc.receive(on: "/pixel", { values in
            let pixelsStr: String = .convert(values: values)
            let newPixel: AudioHapticPixel = loadFromString(pixelsStr) ?? AudioHapticPixel.init(id: 0, value: 0)
            
            while (self.pixels.count <= newPixel.id) {
                self.pixels.append(AudioHapticPixel.init(id: self.pixels.count, value: 0.0))
            }
            
            self.pixels[newPixel.id] = newPixel
        })
        
        osc.receive(on: "/pixels", { values in
            let pixelsStr: String = .convert(values: values)
            let newPixels: [AudioHapticPixel] = loadFromString(pixelsStr) ?? []
            
            if (newPixels.isEmpty) {
                return
            }
                
            // find the start and end indices
            let startIdx = newPixels.first!.id
            let endIdx = newPixels.last!.id
            
            while (self.pixels.count <= endIdx) {
                self.pixels.append(AudioHapticPixel.init(id: self.pixels.count, value: 0.0))
            }
            
            // TODO: validate these start and end bounds
            self.pixels.replaceSubrange(startIdx..<endIdx, with: newPixels)
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
