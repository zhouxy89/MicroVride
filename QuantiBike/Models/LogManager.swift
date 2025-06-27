import Foundation
import CoreMotion
import UIKit
import CoreLocation

class LogManager: NSObject, ObservableObject {
    private var csvData: [LogItem] = []
    @Published var motionManager = CMMotionManager()
    @Published var headPhoneMotionManager = CMHeadphoneMotionManager()
    private var subjectId: String = ""
    private var startTime: Date = Date()
    private var mode: String = "not_defined"

    override init() {
        super.init()
        if !UIDevice.current.isBatteryMonitoringEnabled {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        if motionManager.isAccelerometerAvailable {
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
            motionManager.startGyroUpdates()
            motionManager.startAccelerometerUpdates()
        }
        if headPhoneMotionManager.isDeviceMotionAvailable {
            headPhoneMotionManager.startDeviceMotionUpdates()
        }
    }

    func triggerUpdate(runtime: TimeInterval, leftFoot: FSRFootData, rightFoot: FSRFootData, calibrationStatus: String) {
        csvData.append(LogItem(
            timestamp: runtime,
            phoneAcceleration: motionManager.accelerometerData,
            phoneMotionData: motionManager.deviceMotion,
            phoneBattery: UIDevice.current.batteryLevel,
            leftFoot: leftFoot,
            rightFoot: rightFoot,
            calibrationStatus: calibrationStatus,
            locationData: LocationManager.shared.lastLocation
        ))
    }

    func stopUpdates() {
        motionManager.stopGyroUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        headPhoneMotionManager.stopDeviceMotionUpdates()
    }

    func setSubjectId(subjectId: String) { self.subjectId = subjectId }
    func setStartTime(startTime: Date) { self.startTime = startTime }
    func setMode(mode: String) { self.mode = mode }

    func getLongitude() -> String { "\(LocationManager.shared.lastLocation?.coordinate.longitude ?? 0)" }
    func getLatitude() -> String { "\(LocationManager.shared.lastLocation?.coordinate.latitude ?? 0)" }
    func getAltitude() -> String { "\(LocationManager.shared.lastLocation?.altitude ?? 0)" }

    func saveCSV() {
        do {
            let path = try FileManager.default.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileUrl = path.appendingPathComponent("\(dateAsString(date: startTime))-logfile-subject-\(subjectId).json")

            if FileManager.default.fileExists(atPath: fileUrl.path) {
                let fileHandle = try FileHandle(forWritingTo: fileUrl)
                fileHandle.seekToEndOfFile()
                for log in csvData {
                    fileHandle.write(",".data(using: .utf8)!)
                    fileHandle.write(log.json.data(using: .utf8)!)
                }
                fileHandle.write("]}".data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                var header = "{\"infos\":{\"subject\":\"\(subjectId)\",\"mode\":\"\(mode)\",\"starttime\":\"\(dateAsString(date: startTime))\"},\"timestamps\":["
                header += csvData.first?.json ?? "{}"
                try header.write(to: fileUrl, atomically: true, encoding: .utf8)
                if csvData.count == 1 {
                    let fileHandle = try FileHandle(forWritingTo: fileUrl)
                    fileHandle.write("]}".data(using: .utf8)!)
                    fileHandle.closeFile()
                }
            }

            print("✅ Log file saved.")
        } catch {
            print("❌ Failed to save: \(error)")
        }
    }

    private func dateAsString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HHmmss"
        return formatter.string(from: date)
    }
}
