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
    var pixelData: PixelCollection?
    
    var cursorMsg = 0
    @ObservedObject var osc: OSC = .shared
    
    var player = TransientHapticPlayer()
    var haptics: Haptics?
    
    var isProgramaticallyScrolling = true
    
    func setup(pixels: PixelCollection, haptics: Haptics) {
        self.pixelData = pixels
        self.haptics = haptics
    }
    
    func updateHapticPlayer(activate pixel: AudioHapticPixel) {
        // update player params
        self.player.update(intensity: sqrt(Float(pixel.value)),
                           sharpness: 0.5)
        
        // if the player is off, start
        if let haptics: Haptics = self.haptics {
            if (self.player.player == nil) {
                self.player.start(with: haptics)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let pixelData = self.pixelData else { return }
        updateHapticPlayer(activate: activePixel)
        pixelData.cursorPos = activePixel.id
        
        // send the update the cursor on the controller
        // only if it hasn't been sent
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
//        print("scrollview will begin dragging")
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView) {
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
//        print("scrollview did end dragging")
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated:false)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        print("scrollview did end decelerating")
    }
    
    
}

// keeps track of scroll offset
private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}

struct AudioHapticPixelListView : View {
    // data
    @EnvironmentObject var pixelData: PixelCollection
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
                            ForEach(0..<pixelData.count, id: \.self) { idx in
                                GeometryReader { pixelGeo in
                                    let pixel = pixelData[idx]
                                    AudioHapticPixelView(pixel: pixel)
                                        // update scroll offset
                                        .preference(key: OffsetPreferenceKey.self,
                                                    value: pixelGeo.frame(in: .named(pixelCoordinateSpace)).minX)
                                        // update active pixel
                                        .onPreferenceChange(OffsetPreferenceKey.self) {offset in // user has scrolled
                                            if isPixelActive(globalGeo: geo, pixelGeo: pixelGeo) {
//                                                print("pixel with index \(pixel.id) is at scroll view center")
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
                        scrollview.decelerationRate = .init(rawValue: 100.0)
                        scrollview.delegate = scrollControl
                    }
                    .onAppear{
                        pixelData.loadAllPixels()
                        scrollControl.setup(pixels: pixelData,
                                            haptics: haptics)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("audio scroller")
                    .accessibility(addTraits: .allowsDirectInteraction)
                    .coordinateSpace(name: pixelCoordinateSpace)
                    .simultaneousGesture(zoom)
                }
                
                // add a cursor for visual guidance
                Circle()
                    .fill(.red)
                    .frame(width: 25)
            }
            Button(action: {
                osc.send(Bool.convert(value: true), at: "/sync")
            }) {
                Text("sync")
                    .background(Color.green)
                    .foregroundColor(Color.white)
                    .padding()
            }
            
        }
    }
}

struct AudioHapticPixelListView_Previews: PreviewProvider {
    static var previews: some View {
        AudioHapticPixelListView()
            .environmentObject(PixelCollection())
            .environmentObject(Haptics())
            .environmentObject(TransientHapticPlayer())
    }
}
