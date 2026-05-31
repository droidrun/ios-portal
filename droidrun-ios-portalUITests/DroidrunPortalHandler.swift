//
//  DroidrunPortalHandler.swift
//  droidrun-ios-portal
//
//  Created by Timo Beckmann on 04.06.25.
//

import FlyingFox
import FlyingFoxMacros
import XCTest

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
    let x1: CGFloat
    let y1: CGFloat
    let x2: CGFloat
    let y2: CGFloat
    let durationMs: Double?  // milliseconds, defaults to 300
}

struct GestureResponse: Encodable {
    let message: String
}

struct ErrorResponse: Encodable {
    let error: String
}

struct TypeBody: Decodable {
    let rect: String?
    let text: String
    let clear: Bool?
}

struct KeyBody: Decodable {
    let key: Int
}

struct DateResponse: Encodable {
    let date: String
}

// -- /state response types ----------------------------------------------------

struct ScreenBounds: Encodable {
    let width: CGFloat
    let height: CGFloat
}

struct DeviceContext: Encodable {
    let screen_bounds: ScreenBounds
}

struct StateFullPhoneState: Encodable {
    let currentApp: String
    let packageName: String
    let keyboardVisible: Bool
    let isEditable: Bool
    let focusedElement: FocusedElement?
}

struct StateFullResponse: Encodable {
    let a11y_tree: String
    let phone_state: StateFullPhoneState
    let device_context: DeviceContext
}

@HTTPHandler
struct DroidrunPortalHandler {
    private func jsonResponse<T: Encodable>(
        _ body: T,
        statusCode: HTTPStatusCode = .ok
    ) throws -> HTTPResponse {
        return try HTTPResponse(
            statusCode: statusCode,
            headers: [.contentType: "application/json"],
            body: JSONEncoder().encode(body)
        )
    }

    @JSONRoute("GET /state")
    func stateFull() async throws -> StateFullResponse {
        do {
            return try await DroidrunPortalTools.shared.fetchStateFull()
        } catch {
            // Return a degraded response instead of dropping the connection.
            // The droidrun agent can retry and the test runner avoids
            // accumulating unhandled errors that cause xcodebuild to kill it.
            print("[Portal] /state error (returning fallback): \(error)")
            return StateFullResponse(
                a11y_tree: "",
                phone_state: StateFullPhoneState(
                    currentApp: "",
                    packageName: "",
                    keyboardVisible: false,
                    isEditable: false,
                    focusedElement: nil
                ),
                device_context: DeviceContext(
                    screen_bounds: ScreenBounds(width: 430, height: 932)
                )
            )
        }
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
        let durationSec = (body.durationMs ?? 300) / 1000.0
        try await DroidrunPortalTools.shared.swipe(x1: body.x1, y1: body.y1, x2: body.x2, y2: body.y2, duration: durationSec)
        return GestureResponse(message: "swiped")
    }

    @JSONRoute("POST /inputs/type")
    func enterText(_ body: TypeBody) async throws -> GestureResponse {
        try await DroidrunPortalTools.shared.enterText(
            rect: body.rect,
            text: body.text,
            clear: body.clear == true
        )
        return GestureResponse(message: "entered text")
    }

    @HTTPRoute("POST /inputs/key")
    func pressKey(_ request: HTTPRequest) async throws -> HTTPResponse {
        let body = try await JSONDecoder().decode(KeyBody.self, from: request.bodyData)

        guard let key = PortalHardwareKey(rawValue: body.key) else {
            return try jsonResponse(
                ErrorResponse(
                    error: "Unsupported key \(body.key). Supported keys: \(PortalHardwareKey.supportedKeysDescription)."
                ),
                statusCode: .badRequest
            )
        }

        do {
            try await DroidrunPortalTools.shared.pressKey(key: key)
        } catch let error as DroidrunPortalTools.Error {
            return try jsonResponse(
                ErrorResponse(error: error.localizedDescription),
                statusCode: .badRequest
            )
        }

        return try jsonResponse(GestureResponse(message: "pressed key"))
    }

    @JSONRoute("POST /gestures/back")
    func back() async throws -> GestureResponse {
        try await DroidrunPortalTools.shared.back()
        return GestureResponse(message: "navigated back")
    }

    @JSONRoute("GET /device/date")
    func date() async throws -> DateResponse {
        return DateResponse(date: DroidrunPortalTools.shared.getDate())
    }
}
