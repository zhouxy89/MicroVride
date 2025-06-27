// === Updated DebugView.swift ===
// Displays FSR values and live calibration status in field study

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
                    Section(header: Text("Runtime")) {
                        HStack {
                            Image(systemName: "clock")
                            Text(stringFromTime(interval: runtime)).onReceive(timer) { _ in
                                runtime = Date().timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
                                logManager.triggerUpdate(
                                    runtime: runtime,
                                    fsr1: logItemServer.latestFSR1,
                                    fsr2: logItemServer.latestFSR2,
                                    fsr3: logItemServer.latestFSR3,
                                    fsr4: logItemServer.latestFSR4
                                )
                            }.font(.subheadline)
                        }
                    }

                    Section(header: Text("Calibration")) {
                        HStack {
                            Image(systemName: "waveform.path")
                            Text("Status: \(logItemServer.statusMessage)")
                        }
                    }

                    Section(header: Text("FSR Sensors")) {
                        HStack { Image(systemName: "1.circle"); Text("FSR1: \(logItemServer.latestFSR1)") }
                        HStack { Image(systemName: "2.circle"); Text("FSR2: \(logItemServer.latestFSR2)") }
                        HStack { Image(systemName: "3.circle"); Text("FSR3: \(logItemServer.latestFSR3)") }
                        HStack { Image(systemName: "4.circle"); Text("FSR4: \(logItemServer.latestFSR4)") }
                    }

                    Section(header: Text("Device Motion")) {
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
                    }

                    Section(header: Text("GPS Location")) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Lon: \(logManager.getLongitude()), Lat: \(logManager.getLatitude()), Alt: \(logManager.getAltitude())").font(.subheadline)
                        }
                    }
                }

                Spacer()
                Button("Save CSV", role: .destructive) {
                    logManager.saveCSV()
                    debug = false
                }.buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            preventSleep()
            logManager.setSubjectId(subjectId: subjectId)
            logManager.setMode(mode: "debug")
            logManager.setStartTime(startTime: startTime)
        }
        .onDisappear {
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
        if UIApplication.shared.isIdleTimerDisabled == false {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}
