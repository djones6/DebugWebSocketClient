import Foundation
import Starscream

class MyClient {

    private let client: WebSocket
    let id: Int
    private let payload: Data

    var RUNNING = true
    var completeLoops = 0

    init(client: WebSocket, id: Int, payload: Data, completionLock: DispatchSemaphore) {
        self.client = client
        self.id = id
        self.payload = payload

        client.onConnect = {
            print("Client \(id) connected")
            self.writeLoop()
        }
        client.onDisconnect = { err in
            let errString = err?.localizedDescription ?? "none"
            print("Client \(id) disconnected, err = \(errString)")
            completionLock.signal()
        }
    }

    func writeLoop() {
        guard RUNNING else {
            print("Client \(id) finished running")
            return
        }
        let completion: () -> () = {
            self.completeLoops += 1
            self.writeLoop()
        }
        let message = "Client \(id) message \(completeLoops): padpadpadpadpadpadpadpad".data(using: .utf8)! + self.payload
        client.write(data: message, completion: completion)
    }

    func stopRunning() {
        RUNNING = false
        client.disconnect()
    }

}
