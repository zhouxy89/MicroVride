//  LogItem.swift
//  QuantiBike
//  Updated for two-foot FSR logging (raw, norm, baseline, max, and status)

import Foundation
import CoreMotion
import CoreLocation

struct FootSensorData {
    let fsr1: Int
    let fsr2: Int
    let fsr3: Int
    let fsr4: Int

    let fsr1_raw: Int
    let fsr2_raw: Int
    let fsr3_raw: Int
    let fsr4_raw: Int

    let fsr1_norm: Float
    let fsr2_norm: Float
    let fsr3_norm: Float
    let fsr4_norm: Float

    let fsr1_baseline: Int
    let fsr2_baseline: Int
    let fsr3_baseline: Int
    let fsr4_baseline: Int

    let fsr1_max: Int
    let fsr2_max: Int
    let fsr3_max: Int
    let fsr4_max: Int
}

struct LogItem {
    let timestamp: TimeInterval
    let phoneAcceleration: CMAccelerometerData?
    let phoneMotionData: CMDeviceMotion?
    let phoneBattery: Float

    let leftFoot: FootSensorData
    let rightFoot: FootSensorData

    let calibrationStatus: String
    let locationData: CLLocation?

    var dictionary: [String: Any] {
        var result: [String: Any] = [
            "timestamp": String(timestamp),
            "phoneBattery": String(phoneBattery),
            "calibrationStatus": calibrationStatus,
            "acceleration": preparePhoneAcc(),
            "locationData": prepareLocationData(locationData: locationData),
            "unixTimeStamp": String(Date().timeIntervalSince1970)
        ]

        for (prefix, foot) in [("left", leftFoot), ("right", rightFoot)] {
            result["\(prefix)FSR1"] = foot.fsr1
            result["\(prefix)FSR2"] = foot.fsr2
            result["\(prefix)FSR3"] = foot.fsr3
            result["\(prefix)FSR4"] = foot.fsr4
            result["\(prefix)FSR1_raw"] = foot.fsr1_raw
            result["\(prefix)FSR2_raw"] = foot.fsr2_raw
            result["\(prefix)FSR3_raw"] = foot.fsr3_raw
            result["\(prefix)FSR4_raw"] = foot.fsr4_raw
            result["\(prefix)FSR1_norm"] = foot.fsr1_norm
            result["\(prefix)FSR2_norm"] = foot.fsr2_norm
            result["\(prefix)FSR3_norm"] = foot.fsr3_norm
            result["\(prefix)FSR4_norm"] = foot.fsr4_norm
            result["\(prefix)FSR1_baseline"] = foot.fsr1_baseline
            result["\(prefix)FSR2_baseline"] = foot.fsr2_baseline
            result["\(prefix)FSR3_baseline"] = foot.fsr3_baseline
            result["\(prefix)FSR4_baseline"] = foot.fsr4_baseline
            result["\(prefix)FSR1_max"] = foot.fsr1_max
            result["\(prefix)FSR2_max"] = foot.fsr2_max
            result["\(prefix)FSR3_max"] = foot.fsr3_max
            result["\(prefix)FSR4_max"] = foot.fsr4_max
        }

        for (key, value) in prepareMotionData(motionData: phoneMotionData) {
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

    func preparePhoneAcc() -> [String: String] {
        return [
            "x": phoneAcceleration?.acceleration.x.description ?? "",
            "y": phoneAcceleration?.acceleration.y.description ?? "",
            "z": phoneAcceleration?.acceleration.z.description ?? "",
            "timestamp": phoneAcceleration?.timestamp.description ?? ""
        ]
    }

    func prepareMotionData(motionData: CMDeviceMotion?) -> [String: Any] {
        var motionArr: [String: Any] = [:]
        motionArr["quaternion"] = [
            "x": motionData?.attitude.quaternion.x.description ?? "",
            "y": motionData?.attitude.quaternion.y.description ?? "",
            "z": motionData?.attitude.quaternion.z.description ?? "",
            "w": motionData?.attitude.quaternion.w.description ?? ""
        ]
        motionArr["pitch"] = motionData?.attitude.pitch.description ?? ""
        motionArr["yaw"] = motionData?.attitude.yaw.description ?? ""
        motionArr["roll"] = motionData?.attitude.roll.description ?? ""
        motionArr["timestamp"] = motionData?.timestamp.description ?? ""
        motionArr["rotationMatrix"] = prepareRotationMatrix(motionData: motionData)
        motionArr["userAccel"] = [
            "x": motionData?.userAcceleration.x.description ?? "",
            "y": motionData?.userAcceleration.y.description ?? "",
            "z": motionData?.userAcceleration.z.description ?? ""
        ]
        motionArr["rotationRate"] = [
            "x": motionData?.rotationRate.x.description ?? "",
            "y": motionData?.rotationRate.y.description ?? "",
            "z": motionData?.rotationRate.z.description ?? ""
        ]
        motionArr["magneticField"] = [
            "x": motionData?.magneticField.field.x.description ?? "",
            "y": motionData?.magneticField.field.y.description ?? "",
            "z": motionData?.magneticField.field.z.description ?? "",
            "accuracy": motionData?.magneticField.accuracy.rawValue.description ?? ""
        ]
        return motionArr
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

    func prepareRotationMatrix(motionData: CMDeviceMotion?) -> [String: String] {
        return [
            "m1.1": motionData?.attitude.rotationMatrix.m11.description ?? "",
            "m1.2": motionData?.attitude.rotationMatrix.m12.description ?? "",
            "m1.3": motionData?.attitude.rotationMatrix.m13.description ?? "",
            "m2.1": motionData?.attitude.rotationMatrix.m21.description ?? "",
            "m2.2": motionData?.attitude.rotationMatrix.m22.description ?? "",
            "m2.3": motionData?.attitude.rotationMatrix.m23.description ?? "",
            "m3.1": motionData?.attitude.rotationMatrix.m31.description ?? "",
            "m3.2": motionData?.attitude.rotationMatrix.m32.description ?? "",
            "m3.3": motionData?.attitude.rotationMatrix.m33.description ?? ""
        ]
    }
}
