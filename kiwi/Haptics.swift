//
//  Haptics.swift
//  kiwi
//
//  Created by hugo on 1/31/22.
//

import Foundation
import CoreHaptics

class Haptics {
    private var engine: CHHapticEngine?
    private var running: Bool = false
    
    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            running = true
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
        
        // handle engine reset
        engine?.resetHandler = {
            do {
                // Try restarting the engine.
                try self.engine?.start()
                        
                // Register any custom resources you had registered, using registerAudioResource.
                // Recreate all haptic pattern players you had created, using createPlayer.

            } catch {
                fatalError("Failed to restart the engine: \(error)")
            }
        }
        
        // The stopped handler alerts engine stoppage.
        engine?.stoppedHandler = { reason in
            print("Haptic engine stopped for reason: \(reason.rawValue)")
            
            switch reason {
            case .audioSessionInterrupt: print("Audio session interrupt")
            case .applicationSuspended: print("Application suspended")
            case .idleTimeout: print("Idle timeout")
            case .systemError: print("System error")
            case .notifyWhenFinished: print("Notify when Finished")
            case .engineDestroyed: print("engine destroyed")
            case .gameControllerDisconnect: print("Game controller disconnect")
            @unknown default:
                print("Unknown error")
            }
            
            self.running = false
        }
    }
    
    func complexSuccess() {
        if (!running) { prepare() }
        
        // make sure that the device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        // create one intense, sharp tap
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        // convert those events into a pattern and play it immediately
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}
