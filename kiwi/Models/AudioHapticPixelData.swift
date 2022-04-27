//
//  AudioHapticPixelData.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import Foundation
import SwiftUI
import SwiftUIOSC
import DequeModule

// safe out-of-bounds indexing
extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}

// a ring buffer-esque collection.
final class PixelCollection: ObservableObject, RandomAccessCollection {
    typealias Element = AudioHapticPixel
    
    private var pixels: Deque<AudioHapticPixel> = []
    var cursorPos: Int {
        willSet (newValue) {
            let newOffset = newValue - cursorPos
            if newOffset == 0 { return }
            
            // if we're moving locally, just query for one pixel
            if abs(newOffset) == 1 {
                if let lastPix = self.pixels.last,
                   let firstPix = self.pixels.first {
                    
                    if newOffset > 0 {
                        loadPixel(id: lastPix.id + 1)
                    } else {
                        loadPixel(id: firstPix.id - 1)
                    }
                }
            // if we're moving in larger steps, query for the entire neighborhooe
            } else {
                print("moved cursor by \(newOffset)")
                print("going to load all pixels")
                loadAllPixels()
            }
        }
        didSet (newValue) {
            objectWillChange.send()
            osc.send(cursorPos, at: "/set_cursor")
        }
    }
    
    private var maxSize: Int = 256

    var startIndex: Int = 0
    var endIndex: Int {
        get {
            return pixels.last?.id ?? 0
        }
    }
    
    var last: AudioHapticPixel? {
        return pixels.last
    }
    
    var osc: OSC = .shared
    
    init() {
        for i in (0..<maxSize) {
            self.pixels.append(AudioHapticPixel(id: i, value: 0.0))
        }
        cursorPos = self.pixels.count / 2
        
        osc.receive(on: "/cursor") { values in
            self.cursorPos = .convert(values: values)
        }
    }
    
    subscript(position: Int) -> AudioHapticPixel {
        get {
            if let firstPix = pixels.first {
                var index = position - firstPix.id
                index = index.clamped(to: (0..<self.pixels.count))
                return pixels[index]
            } else {
                fatalError()
            }
            
        }
        set (newValue) {
            if let firstPix = pixels.first,
               let lastPix = pixels.last {
                if (newValue.id - lastPix.id) == 1 { // pix is directly after
                    pixels.append(newValue)
                    _ = pixels.popFirst()
                } else if (newValue.id - firstPix.id) == -1 { // pix is directly before
                    pixels.prepend(newValue)
                    _ = pixels.popLast()
                } else if ((firstPix.id...lastPix.id).contains(newValue.id)) { // pix is in range
                    let index = position - firstPix.id
                    pixels[index] = newValue
                } else { // pix is not directly before, after, or in range
                    print("attempted to append a pixel that is not in the range of our buffer: \(newValue.id)")
                }
            }
        }
    }
    
    func loadAllPixels() {
        let start = cursorPos - self.pixels.count / 2
        let end = cursorPos + self.pixels.count / 2
        for i in (start...end) {
            loadPixel(id: i) {}
        }
    }
    
    func loadPixel(id: Int, completionHandler: @escaping () -> Void = {}) {
        let id = id.clamped(to: 0...Int.max)
        osc.send(Int.convert(value: id), at: "/pixel")
        osc.receive(on: "pixel", { values in
            let pixelsStr: String = .convert(values: values)
            let newPixel: AudioHapticPixel = loadFromString(pixelsStr)
                                        ?? AudioHapticPixel.init(id: 0, value: 0)
            
            self[newPixel.id] = newPixel
            
            completionHandler()
        })
    }
}

//
//final class PixelData: ObservableObject {
//    @ObservedObject var osc: OSC = .shared
//    @Published var pixels: OrderedDictionary<Int, AudioHapticPixel> = [:]
//
//    // assumes that array of pixels has continously increasing ids
//    // TODO: use an orderedDict instead and just sort after insertion
//    func addPixels(_ newPixels: inout [AudioHapticPixel]) {
//        for pixel in newPixels {
//            self.pixels[pixel.id] = pixel
//        }
//
////        self.pixels.sort() { pix1, pix2 in
////            return pix1.1.id < pix2.1.id
////        }
//    }
//
//    func safeIndex(_ at: Int) -> AudioHapticPixel {
//        let res = self.pixels.elements[safe: at] ?? (at, AudioHapticPixel(id:0, value:0))
//        return res.1
//    }
//
//    func prepare() {
//        let stat: Bool = true
//        osc.send(Bool.convert(values: stat.values), at: "/init") // ??
//
//        osc.receive(on: "/pixel", { values in
//            let pixelsStr: String = .convert(values: values)
//            let newPixel: AudioHapticPixel = loadFromString(pixelsStr) ?? AudioHapticPixel.init(id: 0, value: 0)
//            var newPixels = [newPixel]
//
//            DispatchQueue.main.async {
//                self.addPixels(&newPixels)
//            }
//
//        })
//
//        osc.receive(on: "/pixels", { values in
//            let pixelsStr: String = .convert(values: values)
//            var newPixels: [AudioHapticPixel] = loadFromString(pixelsStr) ?? []
//
//            DispatchQueue.main.async {
//                self.addPixels(&newPixels)
//            }
//        })
//
//        osc.receive(on: "/pixels/clear", {values in
//            DispatchQueue.main.async {
//                self.pixels.removeAll(keepingCapacity: true)
//            }
//        })
//    }
//}

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
