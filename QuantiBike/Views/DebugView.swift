//  DebugView.swift
//  QuantiBike
//  Updated to support dual foot sensor data and calibration status display

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
                    Text("Subject ID \(subjectId)").font(.subheadline)
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
                                calibrationStatus: "Left: \(logItemServer.leftStatusMessage); Right: \(logItemServer.rightStatusMessage)"
                            )
                        }
                    }
                    HStack {
                        Image(systemName: "bolt")
                        Text("Left: \(logItemServer.leftStatusMessage)").font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Right: \(logItemServer.rightStatusMessage)").font(.subheadline)
                    }

                    Group {
                        Text("📍 Left Foot").bold()
                        Text("FSR1: \(logItemServer.leftFoot.fsr1), Raw: \(logItemServer.leftFoot.fsr1_raw), Norm: \(logItemServer.leftFoot.fsr1_norm)")
                        Text("FSR2: \(logItemServer.leftFoot.fsr2), Raw: \(logItemServer.leftFoot.fsr2_raw), Norm: \(logItemServer.leftFoot.fsr2_norm)")
                        Text("FSR3: \(logItemServer.leftFoot.fsr3), Raw: \(logItemServer.leftFoot.fsr3_raw), Norm: \(logItemServer.leftFoot.fsr3_norm)")
                        Text("FSR4: \(logItemServer.leftFoot.fsr4), Raw: \(logItemServer.leftFoot.fsr4_raw), Norm: \(logItemServer.leftFoot.fsr4_norm)")
                    }

                    Group {
                        Text("📍 Right Foot").bold()
                        Text("FSR1: \(logItemServer.rightFoot.fsr1), Raw: \(logItemServer.rightFoot.fsr1_raw), Norm: \(logItemServer.rightFoot.fsr1_norm)")
                        Text("FSR2: \(logItemServer.rightFoot.fsr2), Raw: \(logItemServer.rightFoot.fsr2_raw), Norm: \(logItemServer.rightFoot.fsr2_norm)")
                        Text("FSR3: \(logItemServer.rightFoot.fsr3), Raw: \(logItemServer.rightFoot.fsr3_raw), Norm: \(logItemServer.rightFoot.fsr3_norm)")
                        Text("FSR4: \(logItemServer.rightFoot.fsr4), Raw: \(logItemServer.rightFoot.fsr4_raw), Norm: \(logItemServer.rightFoot.fsr4_norm)")
                    }
                }
                Spacer()
                Button("Save CSV", role: .destructive) {
                    logManager.saveCSV()
                    debug = false
                }
                .buttonStyle(.borderedProminent)
                .padding(10)
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
        return (formatter.string(from: interval) ?? "") + ".\(ms)"
    }

    func preventSleep() {
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
