import Foundation

/// Peak-and-settle detector for a dab: a sharp wrist acceleration plus rotation,
/// with a cooldown so one gesture cannot register twice.
struct DabDetector: Equatable {
    var accelerationThreshold: Double = 1.5
    var rotationThreshold: Double = 4.0
    var magnitudeAccelerationThreshold: Double = 2.2
    var magnitudeRotationThreshold: Double = 4.5
    var settleAcceleration: Double = 0.25
    var settleRotation: Double = 0.6
    var cooldown: TimeInterval = 1.0

    private var isDabbing = false
    private var lastDabTime: TimeInterval = -.infinity

    mutating func resetCycle() {
        isDabbing = false
    }

    /// Returns `true` when this sample completes a new dab.
    mutating func process(
        timestamp: TimeInterval,
        userAcceleration: (x: Double, y: Double, z: Double),
        rotationRate: (x: Double, y: Double, z: Double)
    ) -> Bool {
        let accelMag = hypot3(userAcceleration.x, userAcceleration.y, userAcceleration.z)
        let rotMag = hypot3(rotationRate.x, rotationRate.y, rotationRate.z)

        // Classic heuristic (watch on either wrist): lateral accel + yaw-ish rotation.
        let axisSpike =
            abs(userAcceleration.x) > accelerationThreshold &&
            abs(rotationRate.y) > rotationThreshold

        // Orientation-agnostic fallback for the opposite arm / different wear.
        let magnitudeSpike =
            accelMag > magnitudeAccelerationThreshold &&
            rotMag > magnitudeRotationThreshold

        if !isDabbing && (axisSpike || magnitudeSpike) && timestamp - lastDabTime > cooldown {
            isDabbing = true
            lastDabTime = timestamp
            return true
        }

        if isDabbing && accelMag < settleAcceleration && rotMag < settleRotation {
            isDabbing = false
        }

        return false
    }

    private func hypot3(_ x: Double, _ y: Double, _ z: Double) -> Double {
        sqrt(x * x + y * y + z * z)
    }
}
