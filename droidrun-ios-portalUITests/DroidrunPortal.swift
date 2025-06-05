//
//  droidrun_ios_portalUITests.swift
//  droidrun-ios-portalUITests
//
//  Created by Timo Beckmann on 03.06.25.
//

import XCTest
import FlyingFox

final class DroidrunPortal: XCTestCase {
    var app: XCUIApplication?
    var server: HTTPServer!
    
    private let port: in_port_t = 6643
    
    static let shared = DroidrunPortal()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        server = HTTPServer(port: self.port, handler: DroidrunPortalHandler())
        
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        // server?.stop()
    }
    
    @MainActor
    func testLoop() async throws {
        try await server.run()
        
        /*let listeningAddress = await server.listeningAddress
        print("🚀 HTTP Server running on \(listeningAddress.debugDescription)")
        print("⏹️  Press Stop in Xcode to terminate")*/
        
        // Keep the run loop alive
        /*let runLoop = RunLoop.current
        while runLoop.run(mode: .default, before: Date.distantFuture) {
            // This will run until the test is manually stopped
        }*/
        
        /*await server.stop(timeout: 3)
        print("HTTP Server closed")*/
    }
}
