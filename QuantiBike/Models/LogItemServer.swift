import Foundation
import Network

struct FootSensorData {
    var heel: Int = 0, toe: Int = 0, midLeft: Int = 0, midRight: Int = 0
    var heel_raw: Int = 0, toe_raw: Int = 0, midLeft_raw: Int = 0, midRight_raw: Int = 0
    var heel_baseline: Int = 0, toe_baseline: Int = 0, midLeft_baseline: Int = 0, midRight_baseline: Int = 0
    var heel_max: Int = 1, toe_max: Int = 1, midLeft_max: Int = 1, midRight_max: Int = 1
    var heel_norm: Float = 0.0, toe_norm: Float = 0.0, midLeft_norm: Float = 0.0, midRight_norm: Float = 0.0
}


class LogItemServer: ObservableObject {
    @Published var leftFoot = FootSensorData()
    @Published var rightFoot = FootSensorData()
    @Published var leftStatusMessage: String = ""
    @Published var rightStatusMessage: String = ""

    private var listener: NWListener
    private var connections: [NWConnection] = []

    init(port: NWEndpoint.Port) throws {
        listener = try NWListener(using: .tcp, on: port)
    }

    func start() {
        listener.stateUpdateHandler = { state in
            if case .ready = state {
                print("Server ready")
            }
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

        let isRight = msg.contains("board=right")

        DispatchQueue.main.async {
            if isRight {
                self.updateSensorData(target: &self.rightFoot, with: pairs, isRightFoot: true)
            } else {
                self.updateSensorData(target: &self.leftFoot, with: pairs, isRightFoot: false)
            }
        }
    }

    private func updateSensorData(target: inout FootSensorData, with pairs: [[String]], isRightFoot: Bool) {
        for pair in pairs where pair.count == 2 {
            let key = pair[0], value = pair[1]

            if key == "status" {
                if isRightFoot {
                    self.rightStatusMessage = value
                } else {
                    self.leftStatusMessage = value
                }
                continue
            }

            if let intVal = Int(value) {
                switch key {
                    case "left_heel", "right_heel": target.heel = intVal
                    case "left_toe", "right_toe": target.toe = intVal
                    case "left_mid_l", "right_mid_l": target.midLeft = intVal
                    case "left_mid_r", "right_mid_r": target.midRight = intVal

                    case "left_heel_raw", "right_heel_raw": target.heel_raw = intVal
                    case "left_toe_raw", "right_toe_raw": target.toe_raw = intVal
                    case "left_mid_l_raw", "right_mid_l_raw": target.midLeft_raw = intVal
                    case "left_mid_r_raw", "right_mid_r_raw": target.midRight_raw = intVal

                    case "left_heel_baseline", "right_heel_baseline": target.heel_baseline = intVal
                    case "left_toe_baseline", "right_toe_baseline": target.toe_baseline = intVal
                    case "left_mid_l_baseline", "right_mid_l_baseline": target.midLeft_baseline = intVal
                    case "left_mid_r_baseline", "right_mid_r_baseline": target.midRight_baseline = intVal

                    case "left_heel_max", "right_heel_max": target.heel_max = max(intVal, 1)
                    case "left_toe_max", "right_toe_max": target.toe_max = max(intVal, 1)
                    case "left_mid_l_max", "right_mid_l_max": target.midLeft_max = max(intVal, 1)
                    case "left_mid_r_max", "right_mid_r_max": target.midRight_max = max(intVal, 1)
                    default: break
                }
            }

            if let floatVal = Float(value) {
                switch key {
                    case "left_heel_norm", "right_heel_norm": target.heel_norm = floatVal
                    case "left_toe_norm", "right_toe_norm": target.toe_norm = floatVal
                    case "left_mid_l_norm", "right_mid_l_norm": target.midLeft_norm = floatVal
                    case "left_mid_r_norm", "right_mid_r_norm": target.midRight_norm = floatVal
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
