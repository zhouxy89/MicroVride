//  LogItemServer.swift
//  QuantiBike
//  Handles dual-foot sensor inputs from two ESP32 boards

import Foundation
import Network

struct FootSensorData {
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
    var fsr1_norm: Float = 0
    var fsr2_norm: Float = 0
    var fsr3_norm: Float = 0
    var fsr4_norm: Float = 0
}

class LogItemServer: ObservableObject {
    @Published var leftFoot = FootSensorData()
    @Published var rightFoot = FootSensorData()
    @Published var leftStatusMessage: String = ""
    @Published var rightStatusMessage: String = ""

    private var listener: NWListener!
    private var connections: [UUID: NWConnection] = [:]

    init(port: UInt16 = 12345) {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
        } catch {
            print("Failed to create TCP listener: \(error)")
        }
    }

    func start() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        listener.start(queue: .main)
        print("✅ LogItemServer started on port \(listener.port?.rawValue ?? 0)")
    }

    func stop() {
        listener.cancel()
        for conn in connections.values {
            conn.cancel()
        }
        connections.removeAll()
    }

    private func handleNewConnection(_ connection: NWConnection) {
        let id = UUID()
        connections[id] = connection
        connection.start(queue: .main)

        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processData(data)
            }

            if isComplete || error != nil {
                connection.cancel()
                self?.connections.removeValue(forKey: id)
            } else {
                self?.handleNewConnection(connection)
            }
        }
    }

    private func processData(_ data: Data) {
        guard let message = String(data: data, encoding: .utf8) else { return }

        let components = message.split(separator: "&").map { $0.split(separator: "=") }.compactMap {
            $0.count == 2 ? (String($0[0]), String($0[1])) : nil
        }

        var board: String = "left" // default board
        var tempData = FootSensorData()

        for (key, value) in components {
            if key == "board" {
                board = value.lowercased()
                continue
            }

            if key == "status" {
                DispatchQueue.main.async {
                    if board == "left" {
                        self.leftStatusMessage = value
                    } else {
                        self.rightStatusMessage = value
                    }
                }
                continue
            }

            if let intVal = Int(value) {
                switch key {
                case "fsr1": tempData.fsr1 = intVal
                case "fsr2": tempData.fsr2 = intVal
                case "fsr3": tempData.fsr3 = intVal
                case "fsr4": tempData.fsr4 = intVal
                case "fsr1_raw": tempData.fsr1_raw = intVal
                case "fsr2_raw": tempData.fsr2_raw = intVal
                case "fsr3_raw": tempData.fsr3_raw = intVal
                case "fsr4_raw": tempData.fsr4_raw = intVal
                case "fsr1_baseline": tempData.fsr1_baseline = intVal
                case "fsr2_baseline": tempData.fsr2_baseline = intVal
                case "fsr3_baseline": tempData.fsr3_baseline = intVal
                case "fsr4_baseline": tempData.fsr4_baseline = intVal
                case "fsr1_max": tempData.fsr1_max = max(intVal, 1)
                case "fsr2_max": tempData.fsr2_max = max(intVal, 1)
                case "fsr3_max": tempData.fsr3_max = max(intVal, 1)
                case "fsr4_max": tempData.fsr4_max = max(intVal, 1)
                default: break
                }
            }

            if let floatVal = Float(value) {
                switch key {
                case "fsr1_norm": tempData.fsr1_norm = floatVal
                case "fsr2_norm": tempData.fsr2_norm = floatVal
                case "fsr3_norm": tempData.fsr3_norm = floatVal
                case "fsr4_norm": tempData.fsr4_norm = floatVal
                default: break
                }
            }
        }

        DispatchQueue.main.async {
            if board == "left" {
                self.leftFoot = tempData
            } else if board == "right" {
                self.rightFoot = tempData
            }
        }
    }
}
