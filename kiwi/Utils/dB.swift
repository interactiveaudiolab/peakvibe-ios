//
//  dB.swift
//  kiwi
//
//  Created by hugo on 5/17/22.
//

import Foundation


protocol PeakToHapticIntensityMapper {
    // peaklevel should be a value between 0 - 1
    func map(_ level: Float) -> Float
}

func amp2db(_ amp: Float) -> Float {
    return (40 * log (amp) / log(10))
}

class dbSoundMapper : PeakToHapticIntensityMapper {
    
    // 1 is no compression, 2 cuts it by half, and so on.
    let ratio: Float = 5
    
    func map(_ level: Float) -> Float {
        let dbsoundrange: ClosedRange<Float> = (-90...0)
        let dbsound: Float = amp2db(level).clamped(to: dbsoundrange)
        let dbtouch = dbsound / ratio
        let intensity: Float = pow(10, dbtouch / 20)
        return intensity
    }
}
