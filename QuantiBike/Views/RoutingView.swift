//  RoutingView.swift
//  QuantiBike
//  Updated for two-foot FSR sensor logging with full left/right data structure

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
                            }.background(Color(.black).cornerRadius(10))
                        }
                    }.padding(10)
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
                                            leftFoot: logItemServer.leftFoot,
                                            rightFoot: logItemServer.rightFoot,
                                            calibrationStatus: logItemServer.statusMessage
                                        )
                                    }
                            }
                            Button("Finish", role: .destructive, action: {
                                logManager.saveCSV()
                                subjectSet = false
                            }).buttonStyle(.borderedProminent).cornerRadius(10).padding(10)
                        }.background(Color(.black).cornerRadius(10))
                    }.padding(10)
                }
                .onAppear(perform: {
                    preventSleep()
                    logManager.setSubjectId(subjectId: subjectId)
                    logManager.setStartTime(startTime: startTime)
                    logManager.setMode(mode: "map")
                })
                .onDisappear(perform: {
                    logManager.stopUpdates()
                })
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
        RoutingView(subjectId: .constant("test"), subjectSet: .constant(true), currentAnnouncement: RouteAnnouncement(action: "left", location: CLLocation(), updateMap: false))
    }
}
