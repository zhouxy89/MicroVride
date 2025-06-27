//  LogItem.swift
//  QuantiBike
//  Updated for dual foot FSR data logging

import Foundation
import CoreMotion
import CoreLocation

struct FootSensorData {
    var fsr1: Int = 0
    var fsr2: Int = 0
    var fsr3: Int = 0
    var fsr4: Int = 0
    var fsr1_raw: Int = 0
    var fsr2_raw: Int = 0
    var fsr3_raw: Int = 0
    var fsr4_raw: Int = 0
    var fsr1_norm: Float = 0
    var fsr2_norm: Float = 0
    var fsr3_norm: Float = 0
    var fsr4_norm: Float = 0
    var fsr1_baseline: Int = 0
    var fsr2_baseline: Int = 0
    var fsr3_baseline: Int = 0
    var fsr4_baseline: Int = 0
    var fsr1_max: Int = 1
    var fsr2_max: Int = 1
    var fsr3_max: Int = 1
    var fsr4_max: Int = 1
}

struct LogItem {
    let timestamp: TimeInterval
    let phoneBattery: Float
    let left: FootSensorData
    let right: FootSensorData
    let calibrationStatus: String
    let phoneAcceleration: CMAccelerometerData?
    let phoneMotionData: CMDeviceMotion?
    let locationData: CLLocation?

    var dictionary: [String: Any] {
        var result: [String: Any] = [
            "timestamp": String(timestamp),
            "phoneBattery": String(phoneBattery),
            "calibrationStatus": calibrationStatus,
            "left": sensorDataDict(foot: left),
            "right": sensorDataDict(foot: right),
            "acceleration": preparePhoneAcc(),
            "locationData": prepareLocationData(locationData: locationData),
            "unixTimeStamp": String(Date().timeIntervalSince1970)
        ]

        let motionData = prepareMotionData(motionData: phoneMotionData)
        for (key, value) in motionData {
            result[key] = value
        }

        return result
    }

    var data: Data {
        return (try? JSONSerialization.data(withJSONObject: dictionary)) ?? Data()
    }

    var json: String {
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func sensorDataDict(foot: FootSensorData) -> [String: Any] {
        return [
            "fsr1": foot.fsr1, "fsr2": foot.fsr2, "fsr3": foot.fsr3, "fsr4": foot.fsr4,
            "fsr1_raw": foot.fsr1_raw, "fsr2_raw": foot.fsr2_raw, "fsr3_raw": foot.fsr3_raw, "fsr4_raw": foot.fsr4_raw,
            "fsr1_norm": foot.fsr1_norm, "fsr2_norm": foot.fsr2_norm, "fsr3_norm": foot.fsr3_norm, "fsr4_norm": foot.fsr4_norm,
            "fsr1_baseline": foot.fsr1_baseline, "fsr2_baseline": foot.fsr2_baseline, "fsr3_baseline": foot.fsr3_baseline, "fsr4_baseline": foot.fsr4_baseline,
            "fsr1_max": foot.fsr1_max, "fsr2_max": foot.fsr2_max, "fsr3_max": foot.fsr3_max, "fsr4_max": foot.fsr4_max
        ]
    }

    func preparePhoneAcc() -> [String: String] {
        return [
            "x": phoneAcceleration?.acceleration.x.description ?? "",
            "y": phoneAcceleration?.acceleration.y.description ?? "",
            "z": phoneAcceleration?.acceleration.z.description ?? "",
            "timestamp": phoneAcceleration?.timestamp.description ?? ""
        ]
    }

    func prepareMotionData(motionData: CMDeviceMotion?) -> [String: Any] {
        guard let motion = motionData else { return [:] }
        return [
            "quaternion": [
                "x": motion.attitude.quaternion.x.description,
                "y": motion.attitude.quaternion.y.description,
                "z": motion.attitude.quaternion.z.description,
                "w": motion.attitude.quaternion.w.description
            ],
            "pitch": motion.attitude.pitch.description,
            "yaw": motion.attitude.yaw.description,
            "roll": motion.attitude.roll.description,
            "timestamp": motion.timestamp.description,
            "rotationMatrix": [
                "m11": motion.attitude.rotationMatrix.m11.description,
                "m12": motion.attitude.rotationMatrix.m12.description,
                "m13": motion.attitude.rotationMatrix.m13.description,
                "m21": motion.attitude.rotationMatrix.m21.description,
                "m22": motion.attitude.rotationMatrix.m22.description,
                "m23": motion.attitude.rotationMatrix.m23.description,
                "m31": motion.attitude.rotationMatrix.m31.description,
                "m32": motion.attitude.rotationMatrix.m32.description,
                "m33": motion.attitude.rotationMatrix.m33.description
            ],
            "userAccel": [
                "x": motion.userAcceleration.x.description,
                "y": motion.userAcceleration.y.description,
                "z": motion.userAcceleration.z.description
            ],
            "rotationRate": [
                "x": motion.rotationRate.x.description,
                "y": motion.rotationRate.y.description,
                "z": motion.rotationRate.z.description
            ],
            "magneticField": [
                "x": motion.magneticField.field.x.description,
                "y": motion.magneticField.field.y.description,
                "z": motion.magneticField.field.z.description,
                "accuracy": motion.magneticField.accuracy.rawValue.description
            ]
        ]
    }

    func prepareLocationData(locationData: CLLocation?) -> [String: String] {
        return [
            "longitude": locationData?.coordinate.longitude.description ?? "",
            "latitude": locationData?.coordinate.latitude.description ?? "",
            "altitude": locationData?.altitude.description ?? "",
            "velocity": locationData?.speed.description ?? "",
            "timestamp": locationData?.timestamp.description ?? ""
        ]
    }
}
