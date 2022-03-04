//
//  kiwiApp.swift
//  kiwi
//
//  Created by hugo on 1/31/22.
//

import SwiftUI

@main
struct kiwiApp: App {
    @StateObject var pixelData = PixelData()
    @StateObject var haptics = Haptics()
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environmentObject(pixelData)
                .environmentObject(haptics)
                .onAppear(perform: {
                    haptics.prepare()
                })
                
        }
    }
}

