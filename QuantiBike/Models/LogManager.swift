//  LogManager.swift
//  QuantiBike
//  Updated for 4 FSR sensor logging and extended calibration values on 2025-06-27

import Foundation
import CoreMotion
import UIKit
import CoreLocation
import MapKit

class LogManager: NSObject, ObservableObject {
    private var csvData: [LogItem] = []
    @Published var motionManager = CMMotionManager()
    @Published var headPhoneMotionManager = CMHeadphoneMotionManager()
    private var subjectId: String = ""
    private var startTime: Date = Date()
    private var mode: String = "not_defined"

    @Published var runtime = 0.0
    
    // Calibration data storage (latest known)
    var latestFSR1_raw: Int = 0
    var latestFSR2_raw: Int = 0
    var latestFSR3_raw: Int = 0
    var latestFSR4_raw: Int = 0
    var latestFSR1_norm: Float = 0
    var latestFSR2_norm: Float = 0
    var latestFSR3_norm: Float = 0
    var latestFSR4_norm: Float = 0
    var latestFSR1_baseline: Int = 0
    var latestFSR2_baseline: Int = 0
    var latestFSR3_baseline: Int = 0
    var latestFSR4_baseline: Int = 0
    var latestFSR1_max: Int = 1
    var latestFSR2_max: Int = 1
    var latestFSR3_max: Int = 1
    var latestFSR4_max: Int = 1
    var latestStatus: String = ""

    var latitude: String {
        return "\(LocationManager.shared.lastLocation?.coordinate.latitude ?? 0)"
    }
    var longitude: String{
        return "\(LocationManager.shared.lastLocation?.coordinate.longitude ?? 0)"
    }
    var userAltitude: String{
        return "\(LocationManager.shared.lastLocation?.altitude ?? 0)"
    }

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

    private func dateAsString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HHmmss"
        return dateFormatter.string(from: date)
    }

    func triggerUpdate(runtime: TimeInterval, fsr1: Int, fsr2: Int, fsr3: Int, fsr4: Int) {
        csvData.append(LogItem(
            timestamp: runtime,
            phoneBattery: UIDevice.current.batteryLevel,
            fsr1: fsr1,
            fsr2: fsr2,
            fsr3: fsr3,
            fsr4: fsr4,
            fsr1_raw: latestFSR1_raw,
            fsr2_raw: latestFSR2_raw,
            fsr3_raw: latestFSR3_raw,
            fsr4_raw: latestFSR4_raw,
            fsr1_norm: latestFSR1_norm,
            fsr2_norm: latestFSR2_norm,
            fsr3_norm: latestFSR3_norm,
            fsr4_norm: latestFSR4_norm,
            fsr1_baseline: latestFSR1_baseline,
            fsr2_baseline: latestFSR2_baseline,
            fsr3_baseline: latestFSR3_baseline,
            fsr4_baseline: latestFSR4_baseline,
            fsr1_max: latestFSR1_max,
            fsr2_max: latestFSR2_max,
            fsr3_max: latestFSR3_max,
            fsr4_max: latestFSR4_max,
            calibrationStatus: latestStatus,
            phoneAcceleration: motionManager.accelerometerData,
            phoneMotionData: motionManager.deviceMotion,
            locationData: LocationManager.shared.lastLocation
        ))
    }

    func stopUpdates() {
        motionManager.stopGyroUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        headPhoneMotionManager.stopDeviceMotionUpdates()
    }

    func setSubjectId(subjectId: String) {
        self.subjectId = subjectId
    }

    func setMode(mode: String) {
        self.mode = mode
    }

    func setStartTime(startTime: Date) {
        self.startTime = startTime
    }

    func getLongitude() -> String {
        return self.longitude
    }

    func getLatitude() -> String {
        return self.latitude
    }

    func getAltitude() -> String {
        return self.userAltitude
    }

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

            print("csv created!")
        } catch {
            print("error while creating log")
        }
    }
}
