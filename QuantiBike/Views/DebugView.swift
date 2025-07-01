//  RoutingView.swift
//  QuantiBike
//  Updated to ensure consistent logging using background timer

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
    var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

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
                            }

                            Button("Finish", role: .destructive, action: {
                                logManager.stopBackgroundLogging()
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
            logManager.startBackgroundLogging(dataSource: logItemServer)
        }
        .onDisappear {
            logManager.stopBackgroundLogging()
            logManager.stopUpdates()
        }
    }
}

func preventSleep() {
    if !UIApplication.shared.isIdleTimerDisabled {
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
