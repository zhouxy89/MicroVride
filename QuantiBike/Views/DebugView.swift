//  DebugView.swift
//  QuantiBike
//  Updated to ensure continuous background logging with anatomical labels

import SwiftUI
import CoreLocation

struct DebugView: View {
    @Binding var subjectId: String
    @Binding var debug: Bool
    @StateObject var logManager = LogManager()
    @EnvironmentObject var logItemServer: LogItemServer

    var startTime = Date()
    @State var runtime = 0.0

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Image(systemName: "bicycle")
                    Text("QuantiBike").font(.largeTitle)
                }
                Spacer()
                HStack {
                    Image(systemName: "person.circle")
                    Text("Subject ID \(subjectId)").font(.subheadline)
                }
                List {
                    HStack {
                        Image(systemName: "clock")
                        Text(stringFromTime(interval: runtime))
                            .font(.subheadline)
                    }

                    HStack {
                        Image(systemName: "bolt.fill")
                        VStack(alignment: .leading) {
                            Text("Left Status: \(logItemServer.leftStatusMessage)")
                            Text("Right Status: \(logItemServer.rightStatusMessage)")
                        }.font(.subheadline)
                    }

                    Group {
                        Section(header: Text("Left Foot (D32–D35)").font(.headline)) {
                            HStack { Text("Mid Left (D32): \(logItemServer.leftFoot.midLeft)") }
                            HStack { Text("Mid Right (D33): \(logItemServer.leftFoot.midRight)") }
                            HStack { Text("Heel (D34): \(logItemServer.leftFoot.heel)") }
                            HStack { Text("Toe (D35): \(logItemServer.leftFoot.toe)") }
                        }

                        Section(header: Text("Right Foot (D32–D35)").font(.headline)) {
                            HStack { Text("Mid Left (D32): \(logItemServer.rightFoot.midLeft)") }
                            HStack { Text("Mid Right (D33): \(logItemServer.rightFoot.midRight)") }
                            HStack { Text("Heel (D34): \(logItemServer.rightFoot.heel)") }
                            HStack { Text("Toe (D35): \(logItemServer.rightFoot.toe)") }
                        }
                    }.font(.subheadline)

                    HStack {
                        Image(systemName: "iphone")
                        if let motion = logManager.motionManager.deviceMotion {
                            Text("\(motion)").font(.subheadline)
                        } else {
                            Text("No Gyro Data present").font(.subheadline)
                        }
                    }

                    HStack {
                        Image(systemName: "speedometer")
                        if let accel = logManager.motionManager.accelerometerData {
                            Text("\(accel)").font(.subheadline)
                        } else {
                            Text("No Acc Data present").font(.subheadline)
                        }
                    }

                    HStack {
                        Image(systemName: "safari")
                        Text("Longitude: \(logManager.getLongitude()), Latitude: \(logManager.getLatitude()), Altitude: \(logManager.getAltitude())")
                            .font(.subheadline)
                    }
                }

                Spacer()
                Button("Save CSV", role: .destructive, action: {
                    logManager.stopBackgroundLogging()
                    logManager.saveCSV()
                    debug = false
                }).buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            preventSleep()
            logManager.setSubjectId(subjectId: subjectId)
            logManager.setMode(mode: "debug")
            logManager.setStartTime(startTime: startTime)
            logManager.startBackgroundLogging(dataSource: logItemServer)
        }
        .onDisappear {
            logManager.stopBackgroundLogging()
            logManager.stopUpdates()
        }
    }

    func stringFromTime(interval: TimeInterval) -> String {
        let ms = Int(interval.truncatingRemainder(dividingBy: 1) * 1000)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: interval)! + ".\(ms)"
    }

    func preventSleep() {
        if !UIApplication.shared.isIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}
