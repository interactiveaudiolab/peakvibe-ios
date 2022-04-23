//
//  AudioPixelList.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import SwiftUI
import SwiftUIOSC
import CoreHaptics
import Introspect
import XCTest

let pixelCoordinateSpace: String = "pixelStack"

// unused right now
class HapticScrollController :  UIViewController, UIScrollViewDelegate, ObservableObject {
    var activePixel: AudioHapticPixel = AudioHapticPixel(id: 0, value: 0.0)
    var pixelData: PixelData?
    
    var cursorMsg = 0
    @ObservedObject var osc: OSC = .shared
    
    var player = TransientHapticPlayer()
    var haptics: Haptics?
    
    var isProgramaticallyScrolling = true
    
    func setup(pixels: PixelData, haptics: Haptics) {
        self.pixelData = pixels
        self.haptics = haptics
    }
    
    func updateHapticPlayer(activate pixel: AudioHapticPixel) {
//        print("updating player to value: \(pixel.value)")
        
        // update player params
        self.player.update(intensity: Float(pixel.value),
                           sharpness: 0.5)
        
        // if the player is off, start
        if let haptics: Haptics = self.haptics {
            if (self.player.player == nil) {
                self.player.start(with: haptics)
//                print("started haptic player")
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // bail if we're programatically scrolling
        if (isProgramaticallyScrolling) {
            print("programatically scrolling. no need to send cursor sync yet")
//            isProgramaticallyScrolling = false
            return
        }
        
        updateHapticPlayer(activate: activePixel)
        
        // send the update the cursor on the controller
        // only if it hasn't been sent 
        if (cursorMsg != activePixel.id && !pixelData!.pixels.isEmpty){
            osc.send(Int.convert(value: activePixel.id), at: "/set_cursor")
            cursorMsg = activePixel.id
            
            if (activePixel.id == 0 || activePixel.id == (pixelData!.pixels.values.last?.id ?? 0)) {
                endOfScrollAlert(0.15)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.endOfScrollAlert(0.15)
                }
            }
        }
    }
    
    func endOfScrollAlert(_ dur: TimeInterval) {
        if let haptics: Haptics = self.haptics {
            let player = ContinuousHapticPlayer()
            player.update(intensity: 1.0, sharpness: 0.3)
            player.start(with: haptics)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + dur) {
                player.stop()
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isProgramaticallyScrolling = false
        print("scrollview will begin dragging")
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        print("scrollview did end dragging")
        isProgramaticallyScrolling = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("scrollview did end decelerating")
        isProgramaticallyScrolling = true
    }
    
    
}

// keeps track of scroll offset
private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct AudioHapticPixelListView : View {
    // data
    @EnvironmentObject var pixelData: PixelData
    private var pixelSpacing: CGFloat = 0 // need to stop
    
    // haptics
    @EnvironmentObject var haptics: Haptics
    
    // scroll control
    var scrollControl = HapticScrollController()
    
    // zoom
    // zoom gesture
    @OSCState(name: "/zoom") var zoomMsg: CGFloat = 1.0
    private var lastZoomAmt: CGFloat = 1.0
    var zoomPlayer = PulseFMHapticPlayer()
    var zoom: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                print("zoomed by \(value)")
                var zoomVal = value
                if (zoomVal < 1){
                    zoomVal = 1 / zoomVal
                }
                self.zoomPlayer.update(frequency: Float(4 * zoomVal), intensity: 1.0, sharpness: 1.0)
                self.zoomPlayer.start(with: self.haptics)
            }
            .onEnded { value in
                print("zoom gesture ended")
                self.zoomPlayer.stop()
                DispatchQueue.main.async {
                    // TODO: need to clear the pixels somehow?
                    self.zoomMsg = value
                    print("zoomed by \(value)")
                }
            }
    }
    
    // osc stuff
    @ObservedObject var osc: OSC = .shared

    func isPixelActive(globalGeo: GeometryProxy, pixelGeo: GeometryProxy) -> Bool {
        let pixFrame: CGRect = pixelGeo.frame(in: .named(pixelCoordinateSpace)) // frame for this one pixel
        let scrollViewCenter: CGPoint = globalGeo.frame(in: .named(pixelCoordinateSpace)).center // center of the scroll view
        return pixFrame.contains(scrollViewCenter)
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
                                                print("pixel with index \(pixel.id) is at scroll view center")
                                                scrollControl.activePixel = pixel
                                            }
                                        }
                                }
                            }
                        }
                        // add padding so we can have the 0th and last pixel at the center
                        .padding(.horizontal, geo.frame(in: .named(pixelCoordinateSpace)).width / 2)
                    }
                    .introspectScrollView { scrollview in
                        scrollview.decelerationRate = .init(rawValue: -1.0)
                        scrollview.delegate = scrollControl
                    }
                    .accessibilityElement()
                    .accessibilityLabel("audio scroller")
                    .accessibility(addTraits: .allowsDirectInteraction)
                    .onAppear {
                        osc.receive(on: "/cursor") { values in
                            let pos: Int = .convert(values: values)
                                            .clamped(to: -1...pixelData.pixels.count-1)
                            
                            // if the pixels are currently empty,
                            // wait for a little bit before you programatically scroll
                            let delay = pixelData.pixels.isEmpty ? 1.0 : 0.5
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay){
                                scrollControl.isProgramaticallyScrolling = true
                                proxy.scrollTo(pos, anchor: .center)
//                                scrollControl.isProgramaticallyScrolling = false
                            }
                        }
                    }
                    .coordinateSpace(name: pixelCoordinateSpace)
                    .simultaneousGesture(zoom)
                    .onAppear{
                        pixelData.prepare()
                        scrollControl.setup(pixels: pixelData,
                                            haptics: haptics)
                    }
                }
                
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
            .environmentObject(TransientHapticPlayer())
    }
}
