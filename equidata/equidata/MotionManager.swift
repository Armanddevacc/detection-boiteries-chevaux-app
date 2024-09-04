import Foundation
import CoreMotion

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var zAcceleration: Double = 0.0
    @Published var accelerationData: [(time: Date, value: Double)] = []
    @Published var isMeasuring = false
    private var startTime: Date?

    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion, self.isMeasuring else { return }
                
                self.zAcceleration = motion.userAcceleration.z
                self.addDataPoint(zAcceleration: self.zAcceleration)
            }
            startTime = Date()
        }
    }

    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isMeasuring = false
    }

    func toggleMotionUpdates() {
        isMeasuring.toggle()
        if isMeasuring {
            startMotionUpdates()
        } else {
            stopMotionUpdates()
        }
    }

    func resetMeasurements() {
        accelerationData.removeAll()
        startTime = nil
    }

    func generateCSV() -> String {
        var csvText = "Time,Acceleration\n"
        
        for data in accelerationData {
            let timeInterval = data.time.timeIntervalSince(startTime ?? data.time)
            let milliseconds = Int((timeInterval * 1000).truncatingRemainder(dividingBy: 1000))
            let seconds = Int(timeInterval) % 60
            let minutes = (Int(timeInterval) / 60) % 60
            let hours = Int(timeInterval) / 3600
            let timeString = String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
            let newLine = "\(timeString),\(data.value)\n"
            csvText.append(newLine)
        }
        
        return csvText
    }

    private func addDataPoint(zAcceleration: Double) {
        let now = Date()
        let zAccelerationInG = zAcceleration / 9.81  // Convertir en g
        accelerationData.append((time: now, value: zAccelerationInG))
        // Limiter les données affichées à 20 secondes
        let twentySecondsAgo = now.addingTimeInterval(-20)
        accelerationData = accelerationData.filter { $0.time >= twentySecondsAgo }
    }
}
