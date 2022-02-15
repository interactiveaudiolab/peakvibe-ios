//
//  Haptics.swift
//  kiwi
//
//  Created by hugo on 1/31/22.
//

import Foundation
import SwiftUI
import CoreHaptics

class Haptics {
    var engine: CHHapticEngine!
    
    // Tokens to track whether app is in the foreground or the background:
    private var foregroundToken: NSObjectProtocol?
    private var backgroundToken: NSObjectProtocol?
    
    private var engineNeedsStart = true
    private lazy var supportsHaptics: Bool = {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }()
    
    func prepare() {
        guard supportsHaptics else { return }
        guard (engineNeedsStart) else { return }
    
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engineNeedsStart = false
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
        
        // handle engine reset
        engine?.resetHandler = {
            do {
                // Try restarting the engine.
                try self.engine?.start()
                self.engineNeedsStart = false
                        
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
            self.engineNeedsStart = true
        }
    }
    
    func complexSuccess() {
        if (engineNeedsStart) { prepare() }
        
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

    private func addObservers() {
        backgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                 object: nil,
                                                                 queue: nil)
        { _ in
            guard self.supportsHaptics else {
                return
            }
            // Stop the haptic engine.
            self.engine.stop(completionHandler: { error in
                if let error = error {
                    print("Haptic Engine Shutdown Error: \(error)")
                    return
                }
                self.engineNeedsStart = true
            })
        }
        foregroundToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                 object: nil,
                                                                 queue: nil)
        { _ in
            guard self.supportsHaptics else {
                return
            }
            // Restart the haptic engine.
            self.engine.start(completionHandler: { error in
                if let error = error {
                    print("Haptic Engine Startup Error: \(error)")
                    return
                }
                self.engineNeedsStart = false
            })
        }
    }
}

class ContinuousHapticPlayer {
    var player: CHHapticAdvancedPatternPlayer!
    private var haptics: Haptics!
    
    func start(with haptics: Haptics, intensity: Float, sharpness: Float) {
        self.haptics = haptics
        
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                    value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                    value: sharpness)
        let event = CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [intensityParam, sharpnessParam],
                                  relativeTime: 0, duration: 640)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            self.player = try self.haptics.engine.makeAdvancedPlayer(with: pattern)
            try self.player.start(atTime: 0)
        } catch let error {
            print("Pattern Player Creation Error: \(error)")
        }
        
    }
    
    func update(intensity: Float, sharpness: Float){
        let intensityParam = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                    value: intensity, relativeTime: 0)
        let sharpnessParam = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                      value: sharpness, relativeTime: 0)
        
        // Send dynamic parameters to the haptic player.
        do {
            try player?.sendParameters([intensityParam, sharpnessParam], atTime: 0)
        } catch let error {
            print("Error updating player parameters: \(error)")
        }
    }
    
    func stop(atTime: TimeInterval) {
        do {
            try player?.stop(atTime: atTime)
        } catch let error {
            print("Error stopping the continuous haptic player: \(error)")
        }
    }
}
