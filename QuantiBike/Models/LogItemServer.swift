//  LogItemServer.swift
//  Handles two-foot FSR sensor data

import Foundation
import Network

struct FootSensorData {
    var fsr1: Int = 0, fsr2: Int = 0, fsr3: Int = 0, fsr4: Int = 0
    var fsr1_raw: Int = 0, fsr2_raw: Int = 0, fsr3_raw: Int = 0, fsr4_raw: Int = 0
    var fsr1_baseline: Int = 0, fsr2_baseline: Int = 0, fsr3_baseline: Int = 0, fsr4_baseline: Int = 0
    var fsr1_max: Int = 1, fsr2_max: Int = 1, fsr3_max: Int = 1, fsr4_max: Int = 1
    var fsr1_norm: Float = 0.0, fsr2_norm: Float = 0.0, fsr3_norm: Float = 0.0, fsr4_norm: Float = 0.0
}

class LogItemServer: ObservableObject {
    @Published var leftFoot = FootSensorData()
    @Published var rightFoot = FootSensorData()
    @Published var statusMessage: String = ""

    private var listener: NWListener
    private var connections: [NWConnection] = []

    init(port: NWEndpoint.Port) throws {
        listener = try NWListener(using: .tcp, on: port)
    }

    func start() {
        listener.stateUpdateHandler = { state in
            if case .ready = state { print("Server ready") }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        listener.start(queue: .main)
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        connections.append(connection)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, _ in
            guard let self = self else { return }
            if let data = data, let string = String(data: data, encoding: .utf8) {
                self.handleMessage(string)
            }
            if isComplete {
                connection.cancel()
                self.connections.removeAll { $0 === connection }
            } else {
                self.receive(on: connection)
            }
        }
    }

    private func handleMessage(_ msg: String) {
        let pairs = msg.split(separator: "&").map { $0.split(separator: "=").map(String.init) }

        DispatchQueue.main.async {
            if msg.contains("board=right") {
                self.updateSensorData(&self.rightFoot, with: pairs)
            } else {
                self.updateSensorData(&self.leftFoot, with: pairs)
            }
        }
    }

    private func updateSensorData(_ target: inout FootSensorData, with pairs: [[String]]) {
        for pair in pairs where pair.count == 2 {
            let key = pair[0], value = pair[1]

            if key == "status" {
                self.statusMessage = value
                continue
            }

            if let intVal = Int(value) {
                switch key {
                    case "fsr1": target.fsr1 = intVal
                    case "fsr2": target.fsr2 = intVal
                    case "fsr3": target.fsr3 = intVal
                    case "fsr4": target.fsr4 = intVal
                    case "fsr1_raw": target.fsr1_raw = intVal
                    case "fsr2_raw": target.fsr2_raw = intVal
                    case "fsr3_raw": target.fsr3_raw = intVal
                    case "fsr4_raw": target.fsr4_raw = intVal
                    case "fsr1_baseline": target.fsr1_baseline = intVal
                    case "fsr2_baseline": target.fsr2_baseline = intVal
                    case "fsr3_baseline": target.fsr3_baseline = intVal
                    case "fsr4_baseline": target.fsr4_baseline = intVal
                    case "fsr1_max": target.fsr1_max = intVal
                    case "fsr2_max": target.fsr2_max = intVal
                    case "fsr3_max": target.fsr3_max = intVal
                    case "fsr4_max": target.fsr4_max = intVal
                    default: break
                }
            }

            if let floatVal = Float(value) {
                switch key {
                    case "fsr1_norm": target.fsr1_norm = floatVal
                    case "fsr2_norm": target.fsr2_norm = floatVal
                    case "fsr3_norm": target.fsr3_norm = floatVal
                    case "fsr4_norm": target.fsr4_norm = floatVal
                    default: break
                }
            }
        }
    }

    func stop() {
        listener.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
    }
}

