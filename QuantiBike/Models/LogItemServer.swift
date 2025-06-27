// LogItemServer.swift (Extended to Handle Raw, Norm, Baseline, Max Values)

import Foundation
import Network

struct ConnectionData {
    let connection: NWConnection
    let id: UUID
    var clientData: ClientData
}

struct ClientData {
    var fsr1: Int = 0
    var fsr2: Int = 0
    var fsr3: Int = 0
    var fsr4: Int = 0
    var fsr1_raw: Int = 0
    var fsr2_raw: Int = 0
    var fsr3_raw: Int = 0
    var fsr4_raw: Int = 0
    var fsr1_baseline: Int = 0
    var fsr2_baseline: Int = 0
    var fsr3_baseline: Int = 0
    var fsr4_baseline: Int = 0
    var fsr1_max: Int = 1
    var fsr2_max: Int = 1
    var fsr3_max: Int = 1
    var fsr4_max: Int = 1
    var fsr1_norm: Float = 0.0
    var fsr2_norm: Float = 0.0
    var fsr3_norm: Float = 0.0
    var fsr4_norm: Float = 0.0
    var status: String = ""
}

class LogItemServer: ObservableObject {

    @Published var latestFSR1: Int = 0
    @Published var latestFSR2: Int = 0
    @Published var latestFSR3: Int = 0
    @Published var latestFSR4: Int = 0
    @Published var latestFSR1_raw: Int = 0
    @Published var latestFSR2_raw: Int = 0
    @Published var latestFSR3_raw: Int = 0
    @Published var latestFSR4_raw: Int = 0
    @Published var latestFSR1_norm: Float = 0
    @Published var latestFSR2_norm: Float = 0
    @Published var latestFSR3_norm: Float = 0
    @Published var latestFSR4_norm: Float = 0
    @Published var latestFSR1_baseline: Int = 0
    @Published var latestFSR2_baseline: Int = 0
    @Published var latestFSR3_baseline: Int = 0
    @Published var latestFSR4_baseline: Int = 0
    @Published var latestFSR1_max: Int = 1
    @Published var latestFSR2_max: Int = 1
    @Published var latestFSR3_max: Int = 1
    @Published var latestFSR4_max: Int = 1


    @Published var statusMessage: String = ""

    private var listener: NWListener
    private var connections: [ConnectionData] = []

    init(port: NWEndpoint.Port) throws {
        listener = try NWListener(using: .tcp, on: port)
    }

    func start() {
        listener.stateUpdateHandler = handleStateChange(state:)
        listener.newConnectionHandler = handleNewConnection(connection:)
        listener.start(queue: .main)
    }

    private func handleStateChange(state: NWListener.State) {
        switch state {
        case .ready:
            print("Server is ready.")
        case .failed(let error):
            print("Server failed with error: \(error)")
        default:
            break
        }
    }

    private func handleNewConnection(connection: NWConnection) {
        connections.forEach { $0.connection.cancel() }
        connections.removeAll()
        let connectionData = ConnectionData(connection: connection, id: UUID(), clientData: ClientData())
        connections.append(connectionData)
        processConnection(connectionData)
    }

    private func processConnection(_ connectionData: ConnectionData) {
        connectionData.connection.start(queue: .main)
        connectionData.connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] (data, _, isComplete, error) in
            guard let self = self else { return }

            if let data = data, !data.isEmpty {
                self.processData(data, for: connectionData.id)
            }

            if isComplete || error != nil {
                connectionData.connection.cancel()
                self.connections.removeAll { $0.id == connectionData.id }
            }
        }
    }

    private func processData(_ data: Data, for id: UUID) {
        if let index = connections.firstIndex(where: { $0.id == id }) {
            if let dataString = String(data: data, encoding: .utf8) {
                let keyValuePairs = dataString.split(separator: "&")

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    var connectionData = self.connections[index]

                    for pair in keyValuePairs {
                        let components = pair.split(separator: "=").map(String.init)
                        if components.count == 2 {
                            let key = components[0]
                            let value = components[1]

                            if key == "status" {
                                self.statusMessage = value
                                continue
                            }

                            if let intValue = Int(value) {
                                switch key {
                                case "fsr1": self.latestFSR1 = intValue; connectionData.clientData.fsr1 = intValue
                                case "fsr2": self.latestFSR2 = intValue; connectionData.clientData.fsr2 = intValue
                                case "fsr3": self.latestFSR3 = intValue; connectionData.clientData.fsr3 = intValue
                                case "fsr4": self.latestFSR4 = intValue; connectionData.clientData.fsr4 = intValue
                                case "fsr1_raw": connectionData.clientData.fsr1_raw = intValue
                                case "fsr2_raw": connectionData.clientData.fsr2_raw = intValue
                                case "fsr3_raw": connectionData.clientData.fsr3_raw = intValue
                                case "fsr4_raw": connectionData.clientData.fsr4_raw = intValue
                                case "fsr1_baseline": connectionData.clientData.fsr1_baseline = intValue
                                case "fsr2_baseline": connectionData.clientData.fsr2_baseline = intValue
                                case "fsr3_baseline": connectionData.clientData.fsr3_baseline = intValue
                                case "fsr4_baseline": connectionData.clientData.fsr4_baseline = intValue
                                case "fsr1_max": connectionData.clientData.fsr1_max = intValue
                                case "fsr2_max": connectionData.clientData.fsr2_max = intValue
                                case "fsr3_max": connectionData.clientData.fsr3_max = intValue
                                case "fsr4_max": connectionData.clientData.fsr4_max = intValue
                                default: break
                                }
                            }

                            if let floatValue = Float(value) {
                                switch key {
                                case "fsr1_norm": connectionData.clientData.fsr1_norm = floatValue
                                case "fsr2_norm": connectionData.clientData.fsr2_norm = floatValue
                                case "fsr3_norm": connectionData.clientData.fsr3_norm = floatValue
                                case "fsr4_norm": connectionData.clientData.fsr4_norm = floatValue
                                default: break
                                }
                            }
                        }
                    }
                    self.connections[index] = connectionData
                }
            }
        }
    }

    func stop() {
        listener.cancel()
        connections.forEach { $0.connection.cancel() }
        connections.removeAll()
    }
}
