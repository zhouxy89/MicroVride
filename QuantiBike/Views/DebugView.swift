//  DebugView.swift
//  QuantiBike
//  Updated to reflect two-foot FSR data logging and calibration status

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
                                leftFoot: logItemServer.leftFoot,
                                rightFoot: logItemServer.rightFoot,
                                calibrationStatus: logItemServer.statusMessage
                            )
                        }.font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "bolt")
                        Text("Status: \(logItemServer.statusMessage)").font(.subheadline)
                    }
                    Group {
                        HStack { Image(systemName: "1.circle"); Text("Left FSR1: \(logItemServer.leftFoot.fsr1)").font(.subheadline) }
                        HStack { Image(systemName: "2.circle"); Text("Left FSR2: \(logItemServer.leftFoot.fsr2)").font(.subheadline) }
                        HStack { Image(systemName: "3.circle"); Text("Left FSR3: \(logItemServer.leftFoot.fsr3)").font(.subheadline) }
                        HStack { Image(systemName: "4.circle"); Text("Left FSR4: \(logItemServer.leftFoot.fsr4)").font(.subheadline) }
                        HStack { Image(systemName: "1.circle.fill"); Text("Right FSR1: \(logItemServer.rightFoot.fsr1)").font(.subheadline) }
                        HStack { Image(systemName: "2.circle.fill"); Text("Right FSR2: \(logItemServer.rightFoot.fsr2)").font(.subheadline) }
                        HStack { Image(systemName: "3.circle.fill"); Text("Right FSR3: \(logItemServer.rightFoot.fsr3)").font(.subheadline) }
                        HStack { Image(systemName: "4.circle.fill"); Text("Right FSR4: \(logItemServer.rightFoot.fsr4)").font(.subheadline) }
                    }
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
