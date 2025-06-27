//  DebugView.swift
//  QuantiBike
//  Updated to handle both left and right foot FSR data and calibration

import SwiftUI
import CoreLocation

struct DebugView: View {
    @Binding var subjectId: String
    @Binding var debug: Bool
    @StateObject var logManager = LogManager()
    @EnvironmentObject var logItemServer: LogItemServer

    var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
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
                    Text("Subject ID " + subjectId).font(.subheadline)
                }
                List {
                    HStack {
                        Image(systemName: "clock")
                        Text(stringFromTime(interval: runtime)).onReceive(timer) { _ in
                            runtime = Date().timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
                            logManager.triggerUpdate(
                                runtime: runtime,
                                left: logItemServer.leftFoot,
                                right: logItemServer.rightFoot,
                                calibrationStatus: logItemServer.statusMessage
                            )
                        }.font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "bolt")
                        Text("Status: \(logItemServer.statusMessage)").font(.subheadline)
                    }
                    Group {
                        HStack { Text("LEFT FSR1: \(logItemServer.leftFoot.fsr1)") }
                        HStack { Text("LEFT FSR2: \(logItemServer.leftFoot.fsr2)") }
                        HStack { Text("LEFT FSR3: \(logItemServer.leftFoot.fsr3)") }
                        HStack { Text("LEFT FSR4: \(logItemServer.leftFoot.fsr4)") }
                        HStack { Text("RIGHT FSR1: \(logItemServer.rightFoot.fsr1)") }
                        HStack { Text("RIGHT FSR2: \(logItemServer.rightFoot.fsr2)") }
                        HStack { Text("RIGHT FSR3: \(logItemServer.rightFoot.fsr3)") }
                        HStack { Text("RIGHT FSR4: \(logItemServer.rightFoot.fsr4)") }
                    }.font(.subheadline)
                    HStack {
                        Image(systemName: "iphone")
                        if logManager.motionManager.deviceMotion != nil {
                            Text("\(logManager.motionManager.deviceMotion!)").font(.subheadline)
                        } else {
                            Text("No Gyro Data present").font(.subheadline)
                        }
                    }
                    HStack {
                        Image(systemName: "speedometer")
                        if logManager.motionManager.accelerometerData != nil {
                            Text("\(logManager.motionManager.accelerometerData!)").font(.subheadline)
                        } else {
                            Text("No Acc Data present").font(.subheadline)
                        }
                    }
                    HStack {
                        Image(systemName: "safari")
                        Text("Longitude: \(logManager.getLongitude()), Latitude: \(logManager.getLatitude()), Altitude: \(logManager.getAltitude())").font(.subheadline)
                    }
                }
                Spacer()
                Button("Save CSV", role: .destructive, action: {
                    logManager.saveCSV()
                    debug = false
                }).buttonStyle(.borderedProminent)
            }
        }.onAppear(perform: {
            preventSleep()
            logManager.setSubjectId(subjectId: subjectId)
            logManager.setMode(mode: "debug")
            logManager.setStartTime(startTime: startTime)
        }).onDisappear(perform: {
            logManager.stopUpdates()
        })
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

