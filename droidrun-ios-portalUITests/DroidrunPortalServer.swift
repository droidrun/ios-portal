//
//  droidrun_ios_portalUITests.swift
//  droidrun-ios-portalUITests
//
//  Created by Timo Beckmann on 03.06.25.
//

import XCTest
import FlyingFox

final class DroidrunPortalServer: XCTestCase {
    var app: XCUIApplication?
    var server: HTTPServer!

    private static let basePort: in_port_t = 6643
    private static let maxPortOffset: in_port_t = 10

    override func setUpWithError() throws {
        continueAfterFailure = true

        DroidrunPortalTools.shared.reset()

        // Try ports starting from basePort, bump by one if taken.
        var boundPort: in_port_t?
        for offset: in_port_t in 0..<Self.maxPortOffset {
            let port = Self.basePort + offset
            let candidate = HTTPServer(port: port, handler: DroidrunPortalHandler())
            let started = tryStartServer(candidate, port: port)
            if started {
                server = candidate
                boundPort = port
                break
            }
        }

        guard let port = boundPort else {
            XCTFail("Could not bind to any port in \(Self.basePort)–\(Self.basePort + Self.maxPortOffset - 1)")
            return
        }

        print("Portal server listening on port \(port)")
        RunLoop.main.run()
    }

    /// Attempt to start the server on the given port.  Returns true if the
    /// Task is running, false if the port was already taken.
    private func tryStartServer(_ server: HTTPServer, port: in_port_t) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var ok = true

        Task {
            do {
                // FlyingFox 0.16 uses start(); newer versions renamed this to run().
                try await server.start()
            } catch {
                ok = false
                print("Port \(port) unavailable: \(error.localizedDescription)")
            }
            semaphore.signal()
        }

        // Give the server a moment to either bind or fail.
        let result = semaphore.wait(timeout: .now() + 1.0)
        if result == .timedOut {
            // Timed out = server is running (blocking in run())
            return true
        }
        return ok
    }

    override func tearDownWithError() throws {
        let expectation = XCTestExpectation(description: "Stop server")
        Task {
            await server?.stop()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    @MainActor
    func testLoop() async throws {
    }
}
