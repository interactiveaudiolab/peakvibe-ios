//
//  AudioPixelList.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import SwiftUI
import SwiftUIOSC
import CoreHaptics

let pixelCoordinateSpace: String = "pixelStack"

// keeps track of scroll offset
private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct AudioHapticPixelListView : View {
    // data
    @EnvironmentObject var pixelData: PixelData
    private var pixelSpacing: CGFloat = 0 // need to stop
    @OSCState(name: "/set_cursor") var cursorMsg = 0
    
    // haptics
    @EnvironmentObject var haptics: Haptics
    @StateObject var player = ContinuousHapticPlayer()
    
    
    // osc stuff
    @ObservedObject var osc: OSC = .shared
    
    // zoom gesture
    @OSCState(name: "/zoom") var zoomMsg: CGFloat = 1.0
    var zoom: some Gesture {
        MagnificationGesture()
            .onEnded{ value in
                DispatchQueue.main.async {
                    // TODO: need to clear the pixels somehow?
                    zoomMsg = value
                    print("zoomed by \(value)")
                }
            }
    }

    func isPixelActive(globalGeo: GeometryProxy, pixelGeo: GeometryProxy) -> Bool {
        let pixFrame: CGRect = pixelGeo.frame(in: .named(pixelCoordinateSpace)) // frame for this one pixel
        let scrollViewCenter: CGPoint = globalGeo.frame(in: .named(pixelCoordinateSpace)).center // center of the scroll view
        return pixFrame.contains(scrollViewCenter)
    }
    
    func updateHapticPlayer(activate pixel: AudioHapticPixel) {
        print("updating player to value: \(pixel.value)")
        
        // update player params
        self.player.update(value: Float(pixel.value))
        
        // if the player is off, start it
        if (self.player.player == nil) {
            self.player.start(with: self.haptics)
            print("started haptic player")
        }
    }
    
    var body: some View {
        // the view itself
        GeometryReader { geo in
            ZStack{
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: pixelSpacing) {
                            ForEach(0..<pixelData.pixels.count, id: \.self) { idx in
                                GeometryReader { pixelGeo in
                                    let pixel = pixelData.safeIndex(idx)
                                    AudioHapticPixelView(pixel: pixel)
                                        // set an ID so we can programatically scroll to it later
                                        .id(pixel.id)
                                        // update scroll offset
                                        .preference(key: OffsetPreferenceKey.self,
                                                    value: pixelGeo.frame(in: .named(pixelCoordinateSpace)).minX)
                                        // update active pixel
                                        .onPreferenceChange(OffsetPreferenceKey.self) {offset in // user has scrolled
                                            if isPixelActive(globalGeo: geo, pixelGeo: pixelGeo) {
                                                print("pixel with index \(idx) is at scroll view center")
                                                updateHapticPlayer(activate: pixel)
                                                // send the update the cursor on the controller
                                                // only if it hasn't been sent yet
                                                if (cursorMsg != idx){
                                                    cursorMsg = idx
                                                }
                                            }
                                        }
                                }
                            }
                        }
                        // add padding so we can have the 0th and last pixel at the center
                        .padding(.horizontal, geo.frame(in: .named(pixelCoordinateSpace)).width / 2)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("audio scroller")
                    .accessibility(addTraits: .allowsDirectInteraction)
                    .onAppear {
                        osc.receive(on: "/cursor") { values in
                            let pos: Int = .convert(values: values)
                            proxy.scrollTo(pos)
                        }
                    }
                }
                .coordinateSpace(name: pixelCoordinateSpace)
                .simultaneousGesture(zoom)
                .onAppear(perform: pixelData.prepare)
                
                // add a cursor for visual guidance
                Circle()
                    .fill(.red)
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
