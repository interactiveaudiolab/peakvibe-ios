//
//  PeakMeterView.swift
//  kiwi
//
//  Created by hugo on 5/4/22.
//

import Foundation
import SwiftUI
import SwiftUIOSC

struct PeakMeterView : View {
    var osc: OSC = .shared
    @State var level: Double = 0.1
    
    @EnvironmentObject var haptics: Haptics
    var player = TransientHapticPlayer()

    var body: some View {
        AudioHapticPixelView(pixel:
            AudioHapticPixel(id: 0, value: CGFloat(level))
        ).onAppear {
            // let the controller know what out new mode is
            osc.send("meter", at: "/set_mode")
            
            // handle receive any peaks
            osc.receive(on: "/peak") { values in
//                var leveldict: String = .convert(values: values)
                level = .convert(values: values)
                
                self.player.update(intensity: Float(sqrt(level)),
                                   sharpness: 0.5)
                
                if (self.player.player == nil) {
                    self.player.start(with: haptics)
                }
                
            }
        }
        
    }
}
