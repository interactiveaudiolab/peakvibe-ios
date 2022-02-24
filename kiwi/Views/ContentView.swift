//
//  ContentView.swift
//  kiwi
//
//  Created by hugo on 1/31/22.
//

import SwiftUI
import SwiftUIOSC

extension CGRect {
    var center: CGPoint { .init(x: midX, y: midY) }
}

struct HapticStatusView : View {
    @EnvironmentObject var haptics: Haptics
    
    var body: some View {
        HStack {
            Text("Haptic Motor is ")
            Text(haptics.engineNeedsStart ? "Not ready" : "ready")
        }
    }
}

struct OSCStatusBar : View {
    
    var body: some View {
        HStack{
            NavigationLink(destination: OSCSettingsView()) {
                Label("Network Settings", systemImage: "gear")
            }
            Spacer()
            OSCStatus()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var haptics: Haptics
    @EnvironmentObject var player: ContinuousHapticPlayer

    var body: some View {
        NavigationView{
            VStack {
                OSCStatusBar()
                Divider()
                AudioHapticPixelListView()
                HapticStatusView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            ContentView()
                .previewInterfaceOrientation(.landscapeRight)
                .environmentObject(PixelData())
                .environmentObject(Haptics())
                .environmentObject(ContinuousHapticPlayer())
        } else {
            // Fallback on earlier versions
        }
    }
}
