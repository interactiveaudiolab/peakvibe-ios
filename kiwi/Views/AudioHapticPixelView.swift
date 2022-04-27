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
                Text("\(pixel.id)")
                Spacer()
                RoundedRectangle(cornerRadius: 40)
                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .orange]),
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .frame(width: geo.size.width,
                           height: CGFloat(pixel.value) * geo.size.height)
                Spacer()
            }
        }
    }
}
