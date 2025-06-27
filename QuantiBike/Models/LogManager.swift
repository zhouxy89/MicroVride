//  LogManager.swift
//  QuantiBike
//  Handles logging for both left and right foot FSR sensors

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

    @Published var runtime = 0.0

    var latitude: String { "\(LocationManager.shared.lastLocation?.coordinate.latitude ?? 0)" }
    var longitude: String { "\(LocationManager.shared.lastLocation?.coordinate.longitude ?? 0)" }
    var userAltitude: String { "\(LocationManager.shared.lastLocation?.altitude ?? 0)" }

    override init() {
        super.init()
        UIDevice.current.isBatteryMonitoringEnabled = true
        if motionManager.isAccelerometerAvailable {
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
            motionManager.startGyroUpdates()
            motionManager.startAccelerometerUpdates()
        }
        if headPhoneMotionManager.isDeviceMotionAvailable {
            headPhoneMotionManager.startDeviceMotionUpdates()
        }
    }

    private func dateAsString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HHmmss"
        return dateFormatter.string(from: date)
    }

    func triggerUpdate(runtime: TimeInterval, left: FootSensorData, right: FootSensorData, calibrationStatus: String) {
        csvData.append(LogItem(
            timestamp: runtime,
            phoneAcceleration: motionManager.accelerometerData,
            phoneMotionData: motionManager.deviceMotion,
            phoneBattery: UIDevice.current.batteryLevel,
            leftFoot: left,
            rightFoot: right,
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
    func setMode(mode: String) { self.mode = mode }
    func setStartTime(startTime: Date) { self.startTime = startTime }

    func getLongitude() -> String { longitude }
    func getLatitude() -> String { latitude }
    func getAltitude() -> String { userAltitude }

    func getSingleInfos() -> String {
        var infos = "{\"infos\":{"
        infos.append("\"subject\":\"\(subjectId)\",")
        infos.append("\"mode\":\"\(mode)\",")
        infos.append("\"starttime\":\"\(dateAsString(date: startTime))\"")
        infos.append("},")
        return infos
    }

    func saveCSV() {
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileUrl = path.appendingPathComponent("\(dateAsString(date: startTime))-logfile-subject-\(self.subjectId).json")

            for (index, element) in csvData.enumerated() {
                if let fileUpdate = try? FileHandle(forUpdating: fileUrl) {
                    if index != csvData.endIndex {
                        fileUpdate.seekToEndOfFile()
                        try fileUpdate.write(contentsOf: ",".data(using: .utf8)!)
                    }
                    fileUpdate.seekToEndOfFile()
                    try fileUpdate.write(contentsOf: element.json.data(using: .utf8)!)
                    fileUpdate.closeFile()
                } else {
                    var firstJson = getSingleInfos()
                    firstJson.append("\"timestamps\":[" + element.json)
                    try firstJson.write(to: fileUrl, atomically: true, encoding: .utf8)
                }
            }

            if let fileUpdate = try? FileHandle(forUpdating: fileUrl) {
                fileUpdate.seekToEndOfFile()
                try fileUpdate.write(contentsOf: "]}".data(using: .utf8)!)
            }

            print("✅ CSV created!")
        } catch {
            print("❌ Error while creating log: \(error.localizedDescription)")
        }
    }
}
