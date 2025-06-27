//  RoutingView.swift
//  QuantiBike
//
//  Updated to support full 4-FSR data structure and calibration status

import MapKit
import SwiftUI
import AVFoundation

struct RoutingView: View {
    @EnvironmentObject var logItemServer: LogItemServer
    @State var logManager = LogManager()
    @Binding var subjectId: String
    @Binding var subjectSet: Bool
    @State var currentAnnouncement: RouteAnnouncement?

    var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var startTime: Date = Date()
    @State var runtime: Float64 = 0.0

    var body: some View {
        VStack {
            MapView(announcement: $currentAnnouncement)
                .ignoresSafeArea(.all)
                .overlay(alignment: .topLeading) {
                    HStack(alignment: .top) {
                        if let announcement = currentAnnouncement {
                            VStack {
                                HStack {
                                    Image(systemName: announcement.getIcon())
                                        .fontWeight(.bold)
                                        .font(.custom("Arrow", size: 65, relativeTo: .largeTitle))
                                    Text("\(announcement.distance)m").font(.title).fontWeight(.bold)
                                }.padding(10)
                                Text(announcement.getText()).font(.headline).padding(10)
                            }
                            .background(Color(.black).cornerRadius(10))
                        }
                    }
                    .padding(10)
                }
                .overlay(alignment: .bottomTrailing) {
                    HStack(alignment: .bottom) {
                        VStack {
                            if logManager.headPhoneMotionManager.deviceMotion != nil {
                                Image(systemName: "airpodspro")
                                    .foregroundColor(Color(.systemGreen)).padding(10)
                            } else {
                                Image(systemName: "airpodspro")
                                    .foregroundColor(Color(.systemRed)).padding(10)
                            }

                            HStack {
                                Text("\(String(format: "%03d", Int(runtime)))")
                                    .onReceive(timer) { _ in
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
                                    }
                            }

                            Button("Finish", role: .destructive, action: {
                                logManager.saveCSV()
                                subjectSet = false
                            })
                            .buttonStyle(.borderedProminent)
                            .cornerRadius(10)
                            .padding(10)
                        }
                        .background(Color(.black).cornerRadius(10))
                    }
                    .padding(10)
                }
        }
        .onAppear {
            preventSleep()
            logManager.setSubjectId(subjectId: subjectId)
            logManager.setStartTime(startTime: startTime)
            logManager.setMode(mode: "map")
        }
        .onDisappear {
            logManager.stopUpdates()
        }
    }
}

func preventSleep() {
    if !UIApplication.shared.isIdleTimerDisabled {
        UIApplication.shared.isIdleTimerDisabled = true
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        RoutingView(
            subjectId: .constant("test"),
            subjectSet: .constant(true),
            currentAnnouncement: RouteAnnouncement(action: "left", location: CLLocation(), updateMap: false)
        )
        
    }
}

