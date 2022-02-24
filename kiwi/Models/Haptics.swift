//
//  Haptics.swift
//  kiwi
//
//  Created by hugo on 1/31/22.
//

import Foundation
import SwiftUI
import CoreHaptics

class Haptics : ObservableObject{
    var engine: CHHapticEngine!
    
    // Tokens to track whether app is in the foreground or the background:
    private var foregroundToken: NSObjectProtocol?
    private var backgroundToken: NSObjectProtocol?
    
    @Published var engineNeedsStart = true
    private lazy var supportsHaptics: Bool = {
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }()
    
    func prepare() {
        guard supportsHaptics else { return }
        guard (engineNeedsStart) else { return }
        
        print("preparing haptic engine")
    
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            print("engine started")
            engineNeedsStart = false
            addObservers()
        } catch {
            fatalError("There was an error creating the engine: \(error.localizedDescription)")
        }
        
        // handle engine reset
        engine?.resetHandler = {
            do {
                print("handling haptic engine reset.")
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
            DispatchQueue.main.async {
                self.engineNeedsStart = true
            }
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
                DispatchQueue.main.async {
                    self.engineNeedsStart = true
                }
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
                    fatalError("Haptic Engine Startup Error: \(error)")
                }
                DispatchQueue.main.async {
                    self.engineNeedsStart = true
                }
            })
        }
    }
}

class ContinuousHapticPlayer : ObservableObject {
    @Published var player: CHHapticAdvancedPatternPlayer! = nil
    private var haptics: Haptics!
    
    private var intensity: Float = 0.0
    private var sharpness: Float = 1.0
    
    func start(with haptics: Haptics) {
        self.haptics = haptics
        
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                    value: self.intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                    value: self.sharpness)
        let event = CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [intensityParam, sharpnessParam],
                                  relativeTime: 0, duration: 86400)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            self.player = try self.haptics.engine.makeAdvancedPlayer(with: pattern)
            self.player.completionHandler = { error in
                print("haptic player stopped.")
                if let error = error {
                    print("error: \(error)")
                }
            }
            try self.player.start(atTime: 0)
        } catch let error {
            print("Pattern Player Creation Error: \(error)")
        }
        
    }
    
    func update(intensity: Float, sharpness: Float){
        self.intensity = intensity
        self.sharpness = sharpness
        if (self.player != nil){
            let intensityParam = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                          value: self.intensity, relativeTime: 0)
            let sharpnessParam = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                          value: self.sharpness, relativeTime: 0)
            
            // Send dynamic parameters to the haptic player.
            do {
                try self.player?.sendParameters([intensityParam, sharpnessParam], atTime: 0)
            } catch let error {
                print("Error updating player parameters: \(error)")
            }
        }
    }
    
    func stop(atTime: TimeInterval) {
        do {
            try self.player?.stop(atTime: atTime)
            self.player = nil
        } catch let error {
            print("Error stopping the continuous haptic player: \(error)")
        }
    }
}
