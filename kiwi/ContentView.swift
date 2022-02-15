//
//  ContentView.swift
//  kiwi
//
//  Created by hugo on 1/31/22.
//

import SwiftUI
import SwiftUITrackableScrollView
import NetUtils

extension CGRect {
    var center: CGPoint { .init(x: midX, y: midY) }
}

struct HapticPixelView : View {
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
    
        VStack(alignment: .center){
            Spacer()
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                                     startPoint: .top,
                                     endPoint: .bottom))
                .frame(width: width, height: height)
            Spacer()
        }
    }
}

class HapticPixel : Identifiable {
    let intensity: Float
    let sharpness: Float
    var globalPos: CGRect?
    var id: UUID?

    init(_intensity: Float, _sharpness: Float){
        id = UUID()
        intensity = _intensity
        sharpness = _sharpness
    }
    
    func getCoords(geo: GeometryProxy) -> CGPoint {
        globalPos = geo.frame(in: .global)
        let width = geo.size.width
        let height = CGFloat(intensity * 500)
        
        return CGPoint(x: width, y: height)
    }
}

class HapticPixelContainer : ObservableObject {
    @Published var pixels = [HapticPixel]()
    var globalGeo: GeometryProxy!

    func getHapticPixelOverScrubArea(point: CGPoint) -> HapticPixel? {
        var retPixel: HapticPixel?
        pixels.forEach{ pixel in
            if let pos = pixel.globalPos{
                if (pos.contains(point))
                    { retPixel = pixel }
            } else {
                print("pixel does not have global position")
            }
        }
        return retPixel
    }
}

import PositionScrollView

struct HapticPixelScrubber : View, PositionScrollViewDelegate {
    @State private var haptics = Haptics()
    private var pixelSpacing: CGFloat = 1
    @ObservedObject var pixels = HapticPixelContainer()
    
    /// Page size of Scroll
    var pageSize = CGSize(width: 200, height: 300)
        
    // Create PositionScrollViewModel
    // (Need to create in parent view to bind the state between this view and PositionScrollView)
    @ObservedObject var psViewModel = PositionScrollViewModel(
        pageSize: CGSize(width: 200, height: 300),
        horizontalScroll: Scroll(
            scrollSetting: ScrollSetting(pageCount: 5, afterMoveType: .fitToNearestUnit),
            pageLength: 200
        )
    )
    
    // Delegate methods of PositionScrollView
    public func onScrollStart() {
        // if we just started scrubbing, start a continuous event
        if let pixel = pixels.getHapticPixelOverScrubArea(point: pixels.globalGeo.frame(in: .local).center){
            if (scrubPlayer.player == nil) {
                scrubPlayer.start(with: haptics, intensity: pixel.intensity,
                                  sharpness: pixel.sharpness)
                print("started continuous player")
            }
        }
    }
    public func onChangePage(page: Int) {
        print("onChangePage to page: \(page)")
    }
    
    public func onChangePosition(position: CGFloat) {
        print("position: \(position)")
        // if we just started scrubbing, start a continuous event
        if let pixel = pixels.getHapticPixelOverScrubArea(point: pixels.globalGeo.frame(in: .local).center){
            if (scrubPlayer.player == nil) {
                scrubPlayer.start(with: haptics, intensity: pixel.intensity,
                                  sharpness: pixel.sharpness)
                print("started continuous player")
            } else {
                scrubPlayer.update(intensity: pixel.intensity, sharpness: pixel.sharpness)
                print("updating continuous player")
            }
        }
    }
    
    public func onScrollEnd() {
        print("onScrollEnd")
        print("stopping continuous player")
        scrubPlayer.stop(atTime: 0)
        scrubPlayer.player = nil
    }
    
    @State private var scrubPlayer = ContinuousHapticPlayer()
    
    func constructHapticPixelView(for pixel: HapticPixel, with geo: GeometryProxy,
                                  globalGeo: GeometryProxy) -> some View {
        pixels.globalGeo = globalGeo
        let coords = pixel.getCoords(geo: geo)
        return HapticPixelView(width: coords.x ,
                              height: coords.y)
    }
    
    var body : some View {
        GeometryReader{ globalGeo in
            PositionScrollView(viewModel: self.psViewModel,
                               delegate: self) {
                LazyHStack(spacing: pixelSpacing) {
                    ForEach(pixels.pixels) { _pixel in
                        GeometryReader  { geo in
                            constructHapticPixelView(for: _pixel, with: geo, globalGeo: globalGeo)
                        }
                    }
                }
                .onAppear(perform: {
                    haptics.prepare()
                    (0...256).forEach({idx in
                        pixels.pixels.append(
                            HapticPixel(_intensity: Float.random(in: 0.01...1.0),
                                        _sharpness: 1.0))
                    })
                }).padding()
            }
            Circle()
                .cornerRadius(5)
                .foregroundColor(.yellow)
                .position(globalGeo.frame(in: .local).center)
                .frame(width: 20, height: 20)
        }
    }
}

struct ContentView: View {
    
    var body: some View {
        VStack {
            Text("welcome to kiwi :) yee haw")
                .padding()
            HapticPixelScrubber()
        }
    }
}
