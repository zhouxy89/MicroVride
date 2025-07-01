//  RoutingView.swift
//  QuantiBike
//  Updated to handle dual foot data logging and calibration using a background-safe timer

import MapKit
import SwiftUI
import AVFoundation

struct RoutingView: View {
    @EnvironmentObject var logItemServer: LogItemServer
    @State var logManager = LogManager()
    @Binding var subjectId: String
    @Binding var subjectSet: Bool
    @State var currentAnnouncement: RouteAnnouncement?

    var startTime: Date = Date()
    @State var runtime: Float64 = 0.0

    var body: some View {
        VStack {
            MapView(announcement: $currentAnnouncement)
                .ignoresSafeArea(.all)
                .overlay(alignment: .topLeading) {
                    if let announcement = currentAnnouncement {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: announcement.getIcon())
                                    .fontWeight(.bold)
                                    .font(.custom("Arrow", size: 65, relativeTo: .largeTitle))
                                Text("\(announcement.distance)m").font(.title).fontWeight(.bold)
                            }.padding(10)
                            Text(announcement.getText()).font(.headline).padding(10)
                        }
                        .background(Color(.black).cornerRadius(10))
                        .padding(10)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    VStack {
                        Image(systemName: "airpodspro")
                            .foregroundColor(logManager.headPhoneMotionManager.deviceMotion != nil ? .green : .red)
                            .padding(10)

                        Text("\(String(format: "%03d", Int(runtime)))")
                            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                                runtime = Date().timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
                            }

                        Button("Finish", role: .destructive, action: {
                            logManager.stopLoggingTimer()
                            logManager.saveCSV()
                            subjectSet = false
                        })
                        .buttonStyle(.borderedProminent)
                        .cornerRadius(10)
                        .padding(10)
                    }
                    .background(Color(.black).cornerRadius(10))
                    .padding(10)
                }
        }
        .onAppear {
            preventSleep()
            logManager.setSubjectId(subjectId: subjectId)
            logManager.setStartTime(startTime: startTime)
            logManager.setMode(mode: "map")
            logManager.logItemServer = logItemServer
            logManager.startLoggingTimer()
        }
        .onDisappear {
            logManager.stopLoggingTimer()
            logManager.stopUpdates()
        }
    }
}

func preventSleep() {
    if !UIApplication.shared.isIdleTimerDisabled {
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
