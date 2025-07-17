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
    
    private let port: in_port_t = 6643
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        DroidrunPortalTools.shared.reset()
        server = HTTPServer(port: self.port, handler: DroidrunPortalHandler())
        
        Task {
            try? await server.run()
        }
                
        RunLoop.main.run()
    }
    
    override func tearDownWithError() throws {
        let expectation = XCTestExpectation(description: "Stop server")
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
