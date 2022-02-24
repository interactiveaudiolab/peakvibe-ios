//
//  AudioPixelList.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import SwiftUI

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct AudioHapticPixelListView : View {
    @EnvironmentObject var pixelData: PixelData
    @EnvironmentObject var haptics: Haptics
    private var pixelSpacing: CGFloat = 0 // need to stop checking against a point 
    
//    @State private var activePixelIdx: Int = 0
//    @State private var pixelBounds: [CGRect] = []
    
    @EnvironmentObject var player: ContinuousHapticPlayer
    
    var body: some View {
        let tap = DragGesture(minimumDistance: 0)
            .onChanged { value in
                if (self.player.player == nil) {
                    self.player.start(with: self.haptics)
                    print("started continuous player")
                }
            }
            .onEnded({ _ in
                self.player.stop(atTime: 0)
                print("stopped continuous player")
            })
        // the view itself
        GeometryReader { geo in
            ZStack{
                ScrollView(.horizontal) {
                    LazyHStack(spacing: pixelSpacing) {
                        ForEach(0..<pixelData.pixels.count, id: \.self) { idx in
                            GeometryReader { pixelGeo in
                                let pixel = pixelData.pixels[idx]
                                AudioHapticPixelView(pixel: pixel)
                                    .preference(key: OffsetPreferenceKey.self,
                                                value: pixelGeo.frame(in: .named("pixelStack")).minX)
                                    .onPreferenceChange(OffsetPreferenceKey.self) {offset in
                                        // user has scrolled
                                        let pixFrame: CGRect = pixelGeo.frame(in: .named("pixelStack"))
                                        let scrollViewCenter: CGPoint = geo.frame(in: .named("pixelStack")).center
                                        if pixFrame.contains(scrollViewCenter) {
                                            print("pixel with index \(idx) is at scroll view center")
                                            print("updating player to i: \(pixel.intensity) s: \(pixel.sharpness)")
                                            self.player.update(intensity: pixel.intensity,
                                                               sharpness: pixel.sharpness)
                                            
                                            if (self.player.player == nil) {
                                                self.player.start(with: self.haptics)
                                                print("started continuous player")
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, geo.frame(in: .named("pixelStack")).width / 2)
                }
                .coordinateSpace(name: "pixelStack")
                Circle()
                    .fill(.red)
//                    .position(x: geo.frame(in:.local).midX,
//                              y: geo.frame(in: .local).midY)
                    .frame(width: 25)
            }
            
        }
    }
}

struct AudioHapticPixelListView_Previews: PreviewProvider {
    static var previews: some View {
        AudioHapticPixelListView()
            .environmentObject(PixelData())
            .environmentObject(Haptics())
            .environmentObject(ContinuousHapticPlayer())
    }
}
