//
//  ContentView.swift
//  kiwi
//
//  Created by hugo on 1/31/22.
//


import SwiftUI

struct ContentView: View {
    
    @State private var haptics = Haptics()
    
    var body: some View {
        Text("Welcome to kiwi :)")
            .onAppear(perform: haptics.prepare)
            .onTapGesture(perform: haptics.complexSuccess)
            .padding()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
