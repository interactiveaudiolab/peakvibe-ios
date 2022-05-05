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

struct OSCStatusBar : View {
    
    var body: some View {
        HStack{
            NavigationLink(destination: OSCSettingsView()) {
                Label("Network Settings", systemImage: "gear")
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var haptics: Haptics

    var body: some View {
        NavigationView{
            VStack {
                OSCStatusBar()
                Divider()
                AudioHapticPixelListView()
                NavigationLink(destination: PeakMeterView()) {
                    Text("Peak Meter")
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .padding()
                }
                SyncButton()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            ContentView()
                .previewInterfaceOrientation(.landscapeRight)
                .environmentObject(PixelCollection())
                .environmentObject(Haptics())
        } else {
            // Fallback on earlier versions
        }
    }
}
