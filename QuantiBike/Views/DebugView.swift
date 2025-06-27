//  DebugView.swift
//  QuantiBike
//  Updated to reflect new full FSR data logging and calibration status

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
                                fsr1: logItemServer.latestFSR1,
                                fsr2: logItemServer.latestFSR2,
                                fsr3: logItemServer.latestFSR3,
                                fsr4: logItemServer.latestFSR4,
                                fsr1_raw: logItemServer.latestFSR1_raw,
                                fsr2_raw: logItemServer.latestFSR2_raw,
                                fsr3_raw: logItemServer.latestFSR3_raw,
                                fsr4_raw: logItemServer.latestFSR4_raw,
                                fsr1_norm: logItemServer.latestFSR1_norm,
                                fsr2_norm: logItemServer.latestFSR2_norm,
                                fsr3_norm: logItemServer.latestFSR3_norm,
                                fsr4_norm: logItemServer.latestFSR4_norm,
                                fsr1_baseline: logItemServer.latestFSR1_baseline,
                                fsr2_baseline: logItemServer.latestFSR2_baseline,
                                fsr3_baseline: logItemServer.latestFSR3_baseline,
                                fsr4_baseline: logItemServer.latestFSR4_baseline,
                                fsr1_max: logItemServer.latestFSR1_max,
                                fsr2_max: logItemServer.latestFSR2_max,
                                fsr3_max: logItemServer.latestFSR3_max,
                                fsr4_max: logItemServer.latestFSR4_max,
                                calibrationStatus: logItemServer.statusMessage
                            )
                        }.font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "bolt")
                        Text("Status: \(logItemServer.statusMessage)").font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "1.circle")
                        Text("FSR1: \(logItemServer.latestFSR1)").font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "2.circle")
                        Text("FSR2: \(logItemServer.latestFSR2)").font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "3.circle")
                        Text("FSR3: \(logItemServer.latestFSR3)").font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "4.circle")
                        Text("FSR4: \(logItemServer.latestFSR4)").font(.subheadline)
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

