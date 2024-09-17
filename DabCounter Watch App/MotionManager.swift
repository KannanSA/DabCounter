//
//  MotionManager.swift
//  DabCounter
//
//  Created by Kannan Sekar Annu Radha on 17/09/2024.
//

import Foundation
import CoreMotion
import WatchKit

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var dabCount: Int = 0
    
    // Threshold values for detecting a dab gesture
    private let accelerationThreshold: Double = 1.5
    private let rotationThreshold: Double = 4.0
    
    // Variables to prevent multiple counts for a single dab
    private var isDabbing: Bool = false
    private var lastDabTime: Date = Date()

    init() {
        startMotionUpdates()
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz
            motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                guard let data = data else { return }
                self.handleDeviceMotion(data)
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func handleDeviceMotion(_ data: CMDeviceMotion) {
        let userAcceleration = data.userAcceleration
        let rotationRate = data.rotationRate
        
        // Check if the acceleration and rotation exceed thresholds
        if !isDabbing &&
            abs(userAcceleration.x) > accelerationThreshold &&
            abs(rotationRate.y) > rotationThreshold {
            
            let now = Date()
            if now.timeIntervalSince(lastDabTime) > 1.0 { // Debouncing: 1 second between dabs
                lastDabTime = now
                isDabbing = true
                dabCount += 1

                // Provide haptic feedback
                WKInterfaceDevice.current().play(.success)
            }
        }
        
        // Reset the isDabbing flag when motion settles
        if isDabbing &&
            abs(userAcceleration.x) < 0.2 &&
            abs(rotationRate.y) < 0.5 {
            isDabbing = false
        }
    }
}
