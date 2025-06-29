import Foundation
import CoreMotion
import CoreLocation

struct LogItem {
    let timestamp: TimeInterval
    let phoneAcceleration: CMAccelerometerData?
    let phoneMotionData: CMDeviceMotion?
    let phoneBattery: Float

    let leftFoot: FootSensorData
    let rightFoot: FootSensorData

    let leftCalibrationStatus: String
    let rightCalibrationStatus: String
    let locationData: CLLocation?

    var dictionary: [String: Any] {
        var result: [String: Any] = [
            "timestamp": String(timestamp),
            "phoneBattery": String(phoneBattery),
            "leftCalibrationStatus": leftCalibrationStatus,
            "rightCalibrationStatus": rightCalibrationStatus,
            "acceleration": preparePhoneAcc(),
            "locationData": prepareLocationData(locationData: locationData),
            "unixTimeStamp": String(Date().timeIntervalSince1970)
        ]

        for (prefix, foot) in [("left", leftFoot), ("right", rightFoot)] {
            result["\(prefix)_heel"] = foot.heel
            result["\(prefix)_toe"] = foot.toe
            result["\(prefix)_midLeft"] = foot.midLeft
            result["\(prefix)_midRight"] = foot.midRight

            result["\(prefix)_heel_raw"] = foot.heel_raw
            result["\(prefix)_toe_raw"] = foot.toe_raw
            result["\(prefix)_midLeft_raw"] = foot.midLeft_raw
            result["\(prefix)_midRight_raw"] = foot.midRight_raw

            result["\(prefix)_heel_norm"] = foot.heel_norm
            result["\(prefix)_toe_norm"] = foot.toe_norm
            result["\(prefix)_midLeft_norm"] = foot.midLeft_norm
            result["\(prefix)_midRight_norm"] = foot.midRight_norm

            result["\(prefix)_heel_baseline"] = foot.heel_baseline
            result["\(prefix)_toe_baseline"] = foot.toe_baseline
            result["\(prefix)_midLeft_baseline"] = foot.midLeft_baseline
            result["\(prefix)_midRight_baseline"] = foot.midRight_baseline

            result["\(prefix)_heel_max"] = foot.heel_max
            result["\(prefix)_toe_max"] = foot.toe_max
            result["\(prefix)_midLeft_max"] = foot.midLeft_max
            result["\(prefix)_midRight_max"] = foot.midRight_max
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

