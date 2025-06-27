// DebugView.swift (Updated for FSR extended info with minimal UI delay)

import SwiftUI
import CoreLocation

struct DebugView: View {
    @Binding var subjectId: String
    @Binding var debug: Bool
    @StateObject var logManager = LogManager()
    @EnvironmentObject var logItemServer: LogItemServer

    var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    var startTime = Date()
    @State var runtime = 0.0
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "bicycle")
                Text("QuantiBike Debug").font(.largeTitle)
            }
            .padding(.bottom)
            
            GroupBox(label: Label("Subject Info", systemImage: "person.circle")) {
                Text("Subject ID: \(subjectId)")
                Text("Status: \(logItemServer.statusMessage)").foregroundColor(.blue)
            }
            .padding(.bottom)

            GroupBox(label: Label("FSR Sensor Values", systemImage: "waveform.path.ecg")) {
                VStack(alignment: .leading) {
                    Text("FSR1: \(logItemServer.latestFSR1)")
                    Text("FSR2: \(logItemServer.latestFSR2)")
                    Text("FSR3: \(logItemServer.latestFSR3)")
                    Text("FSR4: \(logItemServer.latestFSR4)")
                }
            }
            .padding(.bottom)

            GroupBox(label: Label("Device Motion", systemImage: "iphone")) {
                VStack(alignment: .leading) {
                    if logManager.motionManager.deviceMotion != nil {
                        Text("\(logManager.motionManager.deviceMotion!)")
                    } else {
                        Text("No Gyro Data present")
                    }
                    if logManager.motionManager.accelerometerData != nil {
                        Text("\(logManager.motionManager.accelerometerData!)")
                    } else {
                        Text("No Accel Data present")
                    }
                }
            }
            .padding(.bottom)

            GroupBox(label: Label("Location", systemImage: "location")) {
                Text("Longitude: \(logManager.getLongitude()), Latitude: \(logManager.getLatitude()), Altitude: \(logManager.getAltitude())")
            }
            .padding(.bottom)

            Spacer()

            Button("Save CSV", role: .destructive) {
                logManager.saveCSV()
                debug = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
        .onAppear {
            preventSleep()
            logManager.setSubjectId(subjectId: subjectId)
            logManager.setMode(mode: "debug")
            logManager.setStartTime(startTime: startTime)
        }
        .onDisappear {
            logManager.stopUpdates()
        }
        .onReceive(timer) { _ in
            runtime = Date().timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
            logManager.triggerUpdate(runtime: runtime,
                                     fsr1: logItemServer.latestFSR1,
                                     fsr2: logItemServer.latestFSR2,
                                     fsr3: logItemServer.latestFSR3,
                                     fsr4: logItemServer.latestFSR4)
        }
    }

    func preventSleep() {
        if UIApplication.shared.isIdleTimerDisabled == false {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView(subjectId: .constant("demo"), debug: .constant(true))
            .environmentObject(try! LogItemServer(port: 12345))
    }
}
