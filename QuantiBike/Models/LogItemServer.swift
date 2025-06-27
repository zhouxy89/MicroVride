import Foundation
import Network

class LogItemServer: ObservableObject {
    @Published var statusMessage: String = ""
    @Published var leftFoot = FSRFootData(fsr1: 0, fsr2: 0, fsr3: 0, fsr4: 0,
                                          fsr1_raw: 0, fsr2_raw: 0, fsr3_raw: 0, fsr4_raw: 0,
                                          fsr1_norm: 0, fsr2_norm: 0, fsr3_norm: 0, fsr4_norm: 0,
                                          fsr1_baseline: 0, fsr2_baseline: 0, fsr3_baseline: 0, fsr4_baseline: 0,
                                          fsr1_max: 1, fsr2_max: 1, fsr3_max: 1, fsr4_max: 1)
    @Published var rightFoot = FSRFootData(fsr1: 0, fsr2: 0, fsr3: 0, fsr4: 0,
                                           fsr1_raw: 0, fsr2_raw: 0, fsr3_raw: 0, fsr4_raw: 0,
                                           fsr1_norm: 0, fsr2_norm: 0, fsr3_norm: 0, fsr4_norm: 0,
                                           fsr1_baseline: 0, fsr2_baseline: 0, fsr3_baseline: 0, fsr4_baseline: 0,
                                           fsr1_max: 1, fsr2_max: 1, fsr3_max: 1, fsr4_max: 1)

    private var listener: NWListener
    private var latestBoard = ""

    init(port: UInt16 = 12345) throws {
        self.listener = try NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!)
    }

    func start() {
        listener.newConnectionHandler = handle
        listener.start(queue: .main)
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: .main)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
            if let data = data, let string = String(data: data, encoding: .utf8) {
                self.handleMessage(string)
            }
            if !isComplete && error == nil {
                self.receive(on: connection)
            }
        }
    }

    private func handleMessage(_ string: String) {
        let pairs = string.components(separatedBy: "&")
        var data = [String: String]()
        for pair in pairs {
            let components = pair.components(separatedBy: "=")
            if components.count == 2 {
                data[components[0]] = components[1]
            }
        }

        if let status = data["status"] {
            DispatchQueue.main.async { self.statusMessage = status }
        }

        let board = data["board"] ?? "board1"
        let target = board == "board1" ? "leftFoot" : "rightFoot"

        var updated = FSRFootData(
            fsr1: 0, fsr2: 0, fsr3: 0, fsr4: 0,
            fsr1_raw: 0, fsr2_raw: 0, fsr3_raw: 0, fsr4_raw: 0,
            fsr1_norm: 0, fsr2_norm: 0, fsr3_norm: 0, fsr4_norm: 0,
            fsr1_baseline: 0, fsr2_baseline: 0, fsr3_baseline: 0, fsr4_baseline: 0,
            fsr1_max: 1, fsr2_max: 1, fsr3_max: 1, fsr4_max: 1
        )

        for i in 1...4 {
            updated[keyPath: \FSRFootData.fsr1 + i - 1] = Int(data["fsr\(i)"] ?? "0") ?? 0
            updated[keyPath: \FSRFootData.fsr1_raw + i - 1] = Int(data["fsr\(i)_raw"] ?? "0") ?? 0
            updated[keyPath: \FSRFootData.fsr1_norm + i - 1] = Float(data["fsr\(i)_norm"] ?? "0") ?? 0
            updated[keyPath: \FSRFootData.fsr1_baseline + i - 1] = Int(data["fsr\(i)_baseline"] ?? "0") ?? 0
            updated[keyPath: \FSRFootData.fsr1_max + i - 1] = Int(data["fsr\(i)_max"] ?? "1") ?? 1
        }

        DispatchQueue.main.async {
            if target == "leftFoot" {
                self.leftFoot = updated
            } else {
                self.rightFoot = updated
            }
        }
    }

    func stop() {
        listener.cancel()
    }
}
