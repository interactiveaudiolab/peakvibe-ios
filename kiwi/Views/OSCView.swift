//
//  OSCView.swift
//  kiwi
//
//  Created by hugo on 2/23/22.
//

import SwiftUI
import SwiftUIOSC

struct OSCStatus: View {
    @ObservedObject var osc: OSC = .shared
    
    var body: some View {
        // Connection
        HStack {
            if osc.connection.isConnected {
                Text("Connected on")
            } else {
                Text("Connection is")
            }
            switch osc.connection {
            case .unknown:
                Label("Unknown", systemImage: "wifi.exclamationmark")
            case .offline:
                Label("Offline", systemImage: "wifi.slash")
            case .wifi:
                Label("Wi-Fi", systemImage: "wifi")
            case .cellular:
                Label("Cellular", systemImage: "antenna.radiowaves.left.and.right")
            }
        }
    }
}

struct OSCTestView: View {
    @ObservedObject var osc: OSC = .shared
    
    @OSCState(name: "test/float") var testFloat: CGFloat = 0.0
    @OSCState(name: "test/int") var testInt: Int = 0
    @OSCState(name: "test/string") var testString: String = ""
    
    var body: some View {
        // Test Float
        HStack {
            
            Text("Float")
                .fontWeight(.bold)
                .frame(width: 75, alignment: .trailing)
            
            Button {
                testFloat = 0.0
            } label: {
                Text("Zero")
            }
            .disabled(testFloat == 0.0)
            
            Slider(value: $testFloat)
            
            Text("\(testFloat, specifier: "%.2f")")
            
        }
        
        // Test Int
        HStack {
        
            Text("Int")
                .fontWeight(.bold)
                .frame(width: 75, alignment: .trailing)
            
            Picker("", selection: $testInt) {
                Text("First").tag(0)
                Text("Second").tag(1)
                Text("Third").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())

        }
        
        // Test String
        HStack {
        
            Text("String")
                .fontWeight(.bold)
                .frame(width: 75, alignment: .trailing)
            
            TextField("Text", text: $testString)
            
        }
        
    }
}

struct OSCSettingsView: View {
    @ObservedObject var osc: OSC = .shared
    
    var body: some View {
        VStack {
            // status
            Group {
                Divider()
                Text("Connection Status")
                    .background(Color.blue)
                OSCStatus()
                HStack {
                    Text("Local IP Address:")
                        .frame(width: 200, alignment: .trailing)
                    Text(UIDevice.current.getIP() ?? "No Wi-fi")
                }
                
            }
            
            // port and address controls
            Group {
                Divider()
                Text("Port and Address Settings")
                    .background(Color.blue)
                HStack {
                    Text("IP Address:")
                        .frame(width: 200, alignment: .trailing)
                    TextField("Address", text: $osc.clientAddress)
                        .border(Color.blue, width: 1.5)
                }
                
                HStack {
                    Text("Send Port:")
                        .frame(width: 200, alignment: .trailing)
                    
                    TextField("Send Port", text: Binding<String>(get: {
                        "\(osc.clientPort)"
                    }, set: { text in
                        guard let port = Int(text) else { return }
                        osc.clientPort = port
                    }))
                        .border(Color.blue, width: 1.5)
                }
                
                HStack {
                    Text("Receive Port:")
                        .frame(width: 200, alignment: .trailing)
                    
                    TextField("Receive Port", text: Binding<String>(get: {
                        "\(osc.serverPort)"
                    }, set: { text in
                        guard let port = Int(text) else { return }
                        osc.serverPort = port
                    }))
                        .border(Color.blue, width: 1.5)
                }
            }
            
            
            // test
            Group {
                Divider()
                Text("Message Tester")
                    .background(Color.blue)
                OSCTestView()
            }
            Divider()
        }
        .font(.system(.body, design: .monospaced))
        .frame(minWidth: 300, maxWidth: 400)
        .padding()
        .onAppear {
            osc.clientAddress = "localhost"
            osc.clientPort = 8000
            osc.serverPort = 7000
        }
    }
}


