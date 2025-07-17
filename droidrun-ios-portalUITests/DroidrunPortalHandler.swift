//
//  DroidrunPortalHandler.swift
//  droidrun-ios-portal
//
//  Created by Timo Beckmann on 04.06.25.
//

import FlyingFox
import FlyingFoxMacros
import XCTest

struct InfoResponse: Encodable {
    let description: String
}

struct A11yResponse: Encodable {
    let accessibilityTree: String
}

struct ClickablesResponse: Encodable {
    let nodes: [AccessibilityTreeClickables.Node]
}

struct AppsResponse: Encodable {
    let apps: [String]
}

struct LaunchAppBody: Decodable {
    let bundleIdentifier: String
}

struct LaunchAppResponse: Encodable {
    let message: String
}

struct TapBody: Decodable {
    let rect: String
    let count: Int?
    let longPress: Bool?
}

struct SwipeBody: Decodable {
    let x: CGFloat
    let y: CGFloat
    let dir: SwipeDirection
}

struct GestureResponse: Encodable {
    let message: String
}

struct TypeBody: Decodable {
    let rect: String
    let text: String
}

struct KeyBody: Decodable {
    let key: Int
}


@HTTPHandler
struct DroidrunPortalHandler {
    
    @JSONRoute("GET /")
    func info() throws -> InfoResponse {
        let description = XCUIDevice.shared.description
        return InfoResponse(description: description)
    }
    
    @JSONRoute("GET /vision/state")
    func fetchPhoneState() async throws -> PhoneState {
        return try await DroidrunPortalTools.shared.fetchPhoneState()
    }
    
    @JSONRoute("GET /vision/a11y")
    func fetchAccessibilityTree() async throws -> A11yResponse {
        let a11y = try await DroidrunPortalTools.shared.fetchAccessibilityTree()
        return A11yResponse(accessibilityTree: a11y)
    }

    @JSONRoute("GET /vision/clickables")
    func fetchAccessibilityClickables() async throws -> ClickablesResponse {
        let nodes = try await DroidrunPortalTools.shared.fetchAccessibilityClickables()
        return ClickablesResponse(nodes: nodes)
    }

    @JSONRoute("GET /vision/apps")
    func fetchApps() async throws -> AppsResponse {
        let apps = await DroidrunPortalTools.shared.listApps()
        return AppsResponse(apps: apps)
    }
    
    @HTTPRoute("GET /vision/screenshot")
    func takeScreenshot() async throws -> HTTPResponse {
        let screenshot = try await DroidrunPortalTools.shared.takeScreenshot()
        return HTTPResponse(statusCode: .ok, headers: [.contentType: "image/png"], body: screenshot)
    }
    
    @JSONRoute("POST /inputs/launch")
    func launchApp(_ body: LaunchAppBody) async throws -> LaunchAppResponse {
        try await DroidrunPortalTools.shared.openApp(bundleIdentifier: body.bundleIdentifier)
        return LaunchAppResponse(message: "opened \(body.bundleIdentifier)")
    }
    
    @JSONRoute("POST /gestures/tap")
    func tapElement(_ body: TapBody) async throws -> GestureResponse {
        try await DroidrunPortalTools.shared.tapElement(rect: body.rect, count: body.count, longPress: body.longPress)
        return GestureResponse(message: "tapped element")
    }
    
    @JSONRoute("POST /gestures/swipe")
    func swipe(_ body: SwipeBody) async throws -> GestureResponse {
        try await DroidrunPortalTools.shared.swipe(x: body.x, y: body.y, direction: body.dir)
        return GestureResponse(message: "swiped")
    }
    
    @JSONRoute("POST /inputs/type")
    func enterText(_ body: TypeBody) async throws -> GestureResponse {
        try await DroidrunPortalTools.shared.enterText(rect: body.rect, text: body.text)
        return GestureResponse(message: "entered text")
    }
    
    @JSONRoute("POST /inputs/key")
    func pressKey(_ body: KeyBody) async throws -> GestureResponse {
        guard let key = XCUIDevice.Button(rawValue: body.key) else {
            throw HTTPUnhandledError()
        }
        
        try await DroidrunPortalTools.shared.pressKey(key: key)
        return GestureResponse(message: "pressed key")
    }

    @HTTPRoute("GET /debug")
    func debug(_ request: HTTPRequest) -> HTTPResponse {
        let text = DroidrunPortalTools.shared.app.debugDescription
        return HTTPResponse(statusCode: .accepted, body: text.data(using: .utf8) ?? Data())
    }
}
