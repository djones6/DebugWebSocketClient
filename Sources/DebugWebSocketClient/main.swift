import Foundation
import Starscream

var FILE = "256k.bin"
var CONCURRENCY = 1
var TEST_DURATION = 5000
var HOST = "localhost"
var PORT = 8080

// Debug
var DEBUG = false

func usage() {
    print("Options are:")
    print("  -c, --concurrency n: number of concurrent Dispatch blocks (default: \(CONCURRENCY))")
    print("  -f, --file name: file to send (default: '\(FILE)')")
    print("  -h, --host name: hostname of server (default: '\(HOST)')")
    print("  -p, --port n: port of server (default: '\(PORT)')")
    print("  -t, --time n: maximum runtime of the test (in ms) (default: \(TEST_DURATION))")
    print("  -d, --debug: print a lot of debugging output (default: \(DEBUG))")
    exit(1)
}

// Parse an expected int value provided on the command line
func parseInt(param: String, value: String) -> Int {
    if let userInput = Int(value) {
        return userInput
    } else {
        print("Invalid value for \(param): '\(value)'")
        exit(1)
    }
}

var param:String? = nil
var remainingArgs = CommandLine.arguments.dropFirst(1)
for arg in remainingArgs {
    if let _param = param {
        param = nil
        switch _param {
        case "-h", "--host":
            HOST = arg
        case "-p", "--port":
            PORT = parseInt(param: _param, value: arg)
        case "-f", "--file":
            FILE = arg
        case "-c", "--concurrency":
            CONCURRENCY = parseInt(param: _param, value: arg)
        case "-t", "--time":
            TEST_DURATION = parseInt(param: _param, value: arg)
        default:
            print("Invalid option '\(arg)'")
            usage()
        }
    } else {
        switch arg {
        case "-h", "--host", "-p", "--port", "-c", "--concurrency", "-f", "--file", "-t", "--time":
            param = arg
        case "-d", "--debug":
            DEBUG = true
        case "-?", "--help", "--?":
            usage()
        default:
            print("Invalid option '\(arg)'")
            usage()
        }
    }
}

let payload = FileManager().contents(atPath: FILE)
guard let payload = payload else {
    fatalError("File \(FILE) could not be read")
}

// Lock to allow us to wait for all clients to disconnect
let completionLock = DispatchSemaphore(value: 0)

if DEBUG {
    print("Concurrency: \(CONCURRENCY), Payload: \(payload.count) bytes, Time limit: \(TEST_DURATION)ms")
}
let startTime = Date()
var clients: [MyClient] = []

// Start the clients
for i in 1...CONCURRENCY {
    let wsclient = WebSocket(url: URL(string: "ws://\(HOST):\(PORT)/ws")!)
    let client = MyClient(client: wsclient, id: i, payload: payload, completionLock: completionLock)
    clients.append(client)
    wsclient.connect()
}

print("Clients created: \(clients.count)")

DispatchQueue.global().asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(TEST_DURATION)) {
    for client in clients {
        client.stopRunning()
    }

    // Calculate stats
    let elapsedTime = -startTime.timeIntervalSinceNow

    // Wait for client disconnection
    for _ in 1...CONCURRENCY {
        completionLock.wait()
    }

    // Sum total of complete ops
    var completedOps = 0
    for client in clients {
        print("Client \(client.id) sent \(client.completeLoops) messages")
        completedOps += client.completeLoops
    }

    var displayOps = Double(completedOps)
    var opsUnit:NSString = "%.0f"
    if completedOps > 100000000 {
        displayOps = displayOps / 1000000
        opsUnit = "%.2fm"
    } else if completedOps > 100000 {
        displayOps = displayOps / 1000
        opsUnit = "%.2fk"
    }
    let opsPerSec = displayOps / elapsedTime

    let output = String(format: "Concurrency %d: completed %d requests (\(opsUnit) ops) in %.2f seconds, \(opsUnit) ops/sec", CONCURRENCY, completedOps, displayOps, elapsedTime, opsPerSec)
    print("\(output)")

    print("Better press CTRL+C now")
}

// Go
dispatchMain()
