//
//  AudioHapticPixelData.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import Foundation
import SwiftUI
import SwiftUIOSC
import OrderedCollections

// safe out-of-bounds indexing
extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


final class PixelData: ObservableObject {
    @ObservedObject var osc: OSC = .shared
    @Published var pixels: OrderedDictionary<Int, AudioHapticPixel> = [:]
    
    // assumes that array of pixels has continously increasing ids
    // TODO: use an orderedDict instead and just sort after insertion
    func addPixels(_ newPixels: inout [AudioHapticPixel]) {
        for pixel in newPixels {
            self.pixels[pixel.id] = pixel
        }
        
//        self.pixels.sort() { pix1, pix2 in
//            return pix1.1.id < pix2.1.id
//        }
    }
    
    func safeIndex(_ at: Int) -> AudioHapticPixel {
        let res = self.pixels.elements[safe: at] ?? (at, AudioHapticPixel(id:0, value:0))
        return res.1
    }
    
    func prepare() {
        let stat: Bool = true
        osc.send(Bool.convert(values: stat.values), at: "/init") // ??
        
        osc.receive(on: "/pixel", { values in
            let pixelsStr: String = .convert(values: values)
            let newPixel: AudioHapticPixel = loadFromString(pixelsStr) ?? AudioHapticPixel.init(id: 0, value: 0)
            var newPixels = [newPixel]
            
            DispatchQueue.main.async {
                self.addPixels(&newPixels)
            }
            
        })
        
        osc.receive(on: "/pixels", { values in
            let pixelsStr: String = .convert(values: values)
            var newPixels: [AudioHapticPixel] = loadFromString(pixelsStr) ?? []
            
            DispatchQueue.main.async {
                self.addPixels(&newPixels)
            }
        })
        
        osc.receive(on: "/pixels/clear", {values in
            DispatchQueue.main.async {
                self.pixels.removeAll(keepingCapacity: true)
            }
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
