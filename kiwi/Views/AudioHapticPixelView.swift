//
//  AudioHapticPixelView.swift
//  kiwi
//
//  Created by hugo on 2/17/22.
//

import SwiftUI


struct AudioHapticPixelView : View {
    var pixel: AudioHapticPixel
    @EnvironmentObject var haptics: Haptics

    var body: some View {
        GeometryReader{ geo in
            VStack(alignment: .center){
                Spacer()
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .orange]),
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .frame(width: geo.size.width,
                           height: CGFloat(pixel.intensity) * geo.size.height)
                Spacer()
            }
        }
    }
}

struct AudioHapticPixelView_Previews: PreviewProvider {
    static var pixels =  PixelData().pixels
    static var previews: some View {
        AudioHapticPixelView(
            pixel: pixels[0]
        )
    }
}

