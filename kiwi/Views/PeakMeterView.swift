//
//  PeakMeterView.swift
//  kiwi
//
//  Created by hugo on 5/4/22.
//

import Foundation
import SwiftUI
import SwiftUIOSC

func mapRanges(_ r1: ClosedRange<Float>, _ r2: ClosedRange<Float>, to: Float) -> Float {
  let num = (to - r1.lowerBound) * (r2.upperBound - r2.lowerBound)
  let denom = r1.upperBound - r1.lowerBound
 
  return r2.lowerBound + num / denom
}

protocol PeakToHapticIntensityMapper {
    // peaklevel should be a value between 0 - 1
    func map(_ level: Float) -> Float
}


class SigmoidMapper : PeakToHapticIntensityMapper {
    func map(_ level: Float) -> Float {
        return 1 / (1 + exp(-7*Float(level+0.35) + 5))
    }
}

class dbSoundMapper : PeakToHapticIntensityMapper {
    
    // 1 is no compression, 2 cuts it by half, and so on.
    let ratio: Float = 4.25
    
    func map(_ level: Float) -> Float {
        let dbsoundrange: ClosedRange<Float> = (-90...3)
        let dbsound: Float = (20 * log (level * sqrt(2)) / log(10)).clamped(to: dbsoundrange)
        let dbtouch = dbsound / ratio
        let intensity: Float = pow(10, dbtouch / 20)
        return intensity
    }
}

// TODO: mute transient player while clip alert is playing

struct PeakMeterView : View {
    var osc: OSC = .shared
    @State var level: Double = 0.1
    
    @EnvironmentObject var haptics: Haptics
    var hapMapper = dbSoundMapper()
    var player = TransientHapticPlayer()
    @State var isClipping: Bool = false

    var body: some View {
        AudioHapticPixelView(pixel:
            AudioHapticPixel(id: 0, value: CGFloat(level))
        ).onAppear {
            // let the controller know what out new mode is
            osc.send("meter", at: "/set_mode")
            
            // handle receive any peaks
            osc.receive(on: "/peak") { values in
                // get the level from the read values
                level = .convert(values: values)
                
                guard !isClipping else {
                    print("will not play peak, clipping.")
                    return
                }
            
                // if we're clipping, play the clip alert
                if (level > 0.97) {
                    clipAlert(1)
                    return
                }
                
                // map level to intensity
                let intensity: Float = hapMapper.map(Float(level))
                print("intensity is \(intensity)")
                level = Double(intensity)
                
                // update player params
                self.player.update(intensity: intensity,
                                   sharpness: 0.6)
                
                // start player if needed
                if (self.player.player == nil) {
                    self.player.start(with: haptics)
                }
                
            }
        }
    }
    
    func clipAlert(_ dur: TimeInterval) {
        isClipping = true
        let player = ContinuousHapticPlayer()
        player.update(intensity: 1.0, sharpness: 1.0)
        player.start(with: haptics)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + dur) {
            player.stop()
            isClipping = false
        }
    }
}
