//
//  DroidrunPortal.swift
//  droidrun-ios-portal
//
//  Created by Timo Beckmann on 03.06.25.
//

import Foundation
import XCTest

enum PortalHardwareKey: Int {
    case home = 1
    case volumeUp = 2
    case volumeDown = 3
    case action = 4
    case camera = 5

    static let supportedKeysDescription =
        "1 (home), 2 (volume up), 3 (volume down), 4 (action; iOS 17+ with supported hardware), 5 (camera; iOS 18+ with supported hardware)"

    var displayName: String {
        switch self {
        case .home:
            return "home"
        case .volumeUp:
            return "volume up"
        case .volumeDown:
            return "volume down"
        case .action:
            return "action"
        case .camera:
            return "camera"
        }
    }

    var availabilityDescription: String {
        switch self {
        case .home:
            return "home button"
        case .volumeUp:
            return "volume up button on a physical device"
        case .volumeDown:
            return "volume down button on a physical device"
        case .action:
            return "action button on iOS 17 or newer with supported hardware"
        case .camera:
            return "camera button on iOS 18 or newer with supported hardware"
        }
    }

    var button: XCUIDevice.Button? {
        switch self {
        case .home:
            return .home
        #if !targetEnvironment(simulator)
        case .volumeUp:
            return .volumeUp
        case .volumeDown:
            return .volumeDown
        #else
        case .volumeUp, .volumeDown:
            return nil
        #endif
        case .action:
            if #available(iOS 17.0, *) {
                return .action
            }
            return nil
        case .camera:
            if #available(iOS 18.0, *) {
                return .camera
            }
            return nil
        }
    }
}

extension DroidrunPortalTools {
    enum Error: Swift.Error, LocalizedError {
        case invalidTool(name: String?, message: String)
        case noAppFound
        case unsupportedKey(key: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidTool(let name, let message):
                "Invalid tool \(name ?? "unknown"): \(message)"
            case .noAppFound:
                "No app found to interact with, try to open an app first."
            case .unsupportedKey(let key, let message):
                "Unsupported key \(key): \(message)"
            }
        }
    }
}

struct FocusedElement: Codable {
    let text: String
    let className: String
    let resourceId: String
}

final class DroidrunPortalTools: XCTestCase {
    var app: XCUIApplication?
    var bundleIdentifier: String?

    static let shared = DroidrunPortalTools()

    func reset() {
        self.bundleIdentifier = "com.apple.springboard"
        self.app = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        self.app?.activate()
        print("reset to homescreen")
    }

    private func looksLikeClock(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let pattern = #"^\d{1,2}:\d{2}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    @MainActor
    private func currentPackageName() -> String {
        if bundleIdentifier == "com.apple.springboard" {
            return "com.apple.springboard"
        }
        return bundleIdentifier ?? ""
    }

    @MainActor
    private func currentAppName() -> String {
        guard let app else {
            return ""
        }

        if bundleIdentifier == "com.apple.springboard" {
            return "Home Screen"
        }

        // Guard accessibility queries — if the app window isn't reachable
        // there's no point querying nav bars or labels.
        let window = app.windows.element(boundBy: 0)
        guard window.waitForExistence(timeout: 2) else {
            return bundleIdentifier ?? ""
        }

        let navBar = app.navigationBars.firstMatch
        if navBar.exists, !navBar.identifier.isEmpty, !looksLikeClock(navBar.identifier) {
            return navBar.identifier
        }

        let label = app.staticTexts.firstMatch
        if label.exists, !label.label.isEmpty, !looksLikeClock(label.label) {
            return label.label
        }

        return ""
    }

    private func fallbackScreenBounds() -> CGRect {
        CGRect(x: 0, y: 0, width: 430, height: 932)
    }

    // MARK: - State

    @MainActor
    func fetchStateFull() throws -> StateFullResponse {
        guard let app else {
            let screen = fallbackScreenBounds()
            return StateFullResponse(
                a11y_tree: "",
                phone_state: StateFullPhoneState(
                    currentApp: "Unknown",
                    packageName: "",
                    keyboardVisible: false,
                    isEditable: false,
                    focusedElement: nil
                ),
                device_context: DeviceContext(
                    screen_bounds: ScreenBounds(width: screen.width, height: screen.height)
                )
            )
        }

        let a11yTree: String
        do {
            a11yTree = try fetchAccessibilityTree()
        } catch {
            let screen = fallbackScreenBounds()
            return StateFullResponse(
                a11y_tree: "",
                phone_state: StateFullPhoneState(
                    currentApp: currentAppName(),
                    packageName: currentPackageName(),
                    keyboardVisible: false,
                    isEditable: false,
                    focusedElement: nil
                ),
                device_context: DeviceContext(
                    screen_bounds: ScreenBounds(width: screen.width, height: screen.height)
                )
            )
        }

        // Guard window frame query — this is the main source of
        // kAXErrorServerNotFound failures that accumulate and eventually
        // cause xcodebuild to kill the test runner.
        let window = app.windows.element(boundBy: 0)
        var frame = fallbackScreenBounds()
        if window.waitForExistence(timeout: 3) {
            let wf = window.frame
            if wf.width > 0 && wf.height > 0 {
                frame = wf
            }
        }

        let currentApp = currentAppName()

        // Guard keyboard queries — .exists and .isHittable can also
        // trigger accessibility failures on slow transitions.
        let kbd = app.keyboards.element
        let keyboardVisible = kbd.exists && kbd.isHittable

        let focusedElementState = findFocusedElement()

        let editableTypes: Set<String> = ["TextField", "SecureTextField", "TextView", "SearchField"]
        let isEditable = focusedElementState != nil && editableTypes.contains(focusedElementState!.className)

        return StateFullResponse(
            a11y_tree: a11yTree,
            phone_state: StateFullPhoneState(
                currentApp: currentApp,
                packageName: currentPackageName(),
                keyboardVisible: keyboardVisible,
                isEditable: isEditable,
                focusedElement: focusedElementState
            ),
            device_context: DeviceContext(
                screen_bounds: ScreenBounds(width: frame.width, height: frame.height)
            )
        )
    }

    @MainActor
    private func findFocusedElement() -> FocusedElement? {
        guard let app else { return nil }
        let focused = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasKeyboardFocus == true")).firstMatch
        guard focused.exists else { return nil }

        let rawValue = focused.value as? String ?? ""
        let value = rawValue == focused.placeholderValue ? "" : rawValue
        return FocusedElement(
            text: value,
            className: Self.elementTypeName(focused.elementType),
            resourceId: focused.identifier
        )
    }

    private static func elementTypeName(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .textField:       return "TextField"
        case .secureTextField: return "SecureTextField"
        case .textView:        return "TextView"
        case .searchField:     return "SearchField"
        case .button:          return "Button"
        case .staticText:      return "StaticText"
        case .image:           return "Image"
        case .cell:            return "Cell"
        case .switch:          return "Switch"
        case .slider:          return "Slider"
        case .picker:          return "Picker"
        case .link:            return "Link"
        case .webView:         return "WebView"
        default:               return "Other(\(type.rawValue))"
        }
    }

    // MARK: - App management

    @MainActor
    func openApp(bundleIdentifier: String) throws {
        if bundleIdentifier == self.bundleIdentifier, app != nil {
            app?.activate()
            return
        }

        let app = XCUIApplication(bundleIdentifier: bundleIdentifier)

        if bundleIdentifier == "com.apple.springboard" {
            app.activate() // Avoid relaunching springboard since that locks the phone
        } else {
            app.launch()
        }

        self.bundleIdentifier = bundleIdentifier
        self.app = app
    }

    // MARK: - Accessibility

    @MainActor
    func fetchAccessibilityTree() throws -> String {
        guard let app else {
            throw Error.noAppFound
        }

        // Guard: if the app window doesn't appear within 10s the
        // accessibility server is likely unreachable (app transitioning,
        // loading, etc.).  waitForExistence does NOT record an XCTest
        // failure, so bailing here avoids the kAXErrorServerNotFound
        // accumulation that eventually kills the test runner.
        let window = app.windows.element(boundBy: 0)
        if !window.waitForExistence(timeout: 10) {
            throw Error.invalidTool(
                name: "fetchAccessibilityTree",
                message: "App window not available after 10s — the app may be loading or transitioning."
            )
        }

        return app.accessibilityTree()
    }

    // MARK: - Gestures

    @MainActor
    func tapElement(rect coordinateString: String, count: Int?, longPress: Bool?) throws {
        print("Tap \(coordinateString) \(count ?? 1) times long: \(longPress ?? false)")
        guard let app else {
            throw Error.noAppFound
        }
        let coordinate = NSCoder.cgRect(for: coordinateString)
        let midPoint = CGPoint(x: coordinate.midX, y: coordinate.midY)
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let targetCoordinate = startCoordinate.withOffset(CGVector(dx: midPoint.x, dy: midPoint.y))
        if longPress == true {
            targetCoordinate.press(forDuration: 0.5)
        } else {
            if count == 2 {
                targetCoordinate.doubleTap()
            } else {
                targetCoordinate.tap()
            }
        }
    }

    @MainActor
    func swipe(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, duration: Double) throws {
        print("Swipe from (\(x1),\(y1)) to (\(x2),\(y2)) duration: \(duration)s")
        guard let app else {
            throw Error.noAppFound
        }
        let root = app.coordinate(withNormalizedOffset: .zero)
        let start = root.withOffset(CGVector(dx: x1, dy: y1))
        let end = root.withOffset(CGVector(dx: x2, dy: y2))
        start.press(forDuration: duration, thenDragTo: end)
    }

    // MARK: - Text input

    @MainActor
    @discardableResult
    private func clearText(rect: String? = nil, timeout: TimeInterval = 30) throws -> Int {
        print("Clear text \(rect ?? "<focused>") timeout: \(timeout)s")
        guard let app else {
            throw Error.noAppFound
        }

        if let rect {
            try tapElement(rect: rect, count: 1, longPress: false)
        }

        let focusedElement = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasKeyboardFocus == true")).firstMatch
        if !focusedElement.exists {
            _ = focusedElement.waitForExistence(timeout: 2)
        }
        guard focusedElement.exists else {
            throw Error.invalidTool(name: "clearText", message: "No element has keyboard focus.")
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        var totalDeleted = 0

        while true {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            if elapsed > timeout {
                print("Clear timed out after \(String(format: "%.1f", elapsed))s")
                break
            }

            let currentValue = focusedElement.value as? String ?? ""
            if currentValue.isEmpty || currentValue == focusedElement.placeholderValue {
                break
            }

            let countBefore = currentValue.count

            let endCoordinate = focusedElement.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.99))
            endCoordinate.tap()
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: countBefore)
            app.typeText(deleteString)

            let afterFast = focusedElement.value as? String ?? ""
            if afterFast.isEmpty || afterFast == focusedElement.placeholderValue {
                totalDeleted += countBefore
                break
            }

            let deletedThisPass = countBefore - afterFast.count
            if deletedThisPass > 0 {
                totalDeleted += deletedThisPass
                continue
            }

            app.typeText(XCUIKeyboardKey.delete.rawValue)
            let afterSingle = focusedElement.value as? String ?? ""
            let singleProgress = afterFast.count - afterSingle.count

            if singleProgress > 0 {
                totalDeleted += singleProgress
                continue
            }

            print("No progress after fast + single delete, stopping")
            break
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        print("Cleared \(totalDeleted) chars in \(String(format: "%.1f", elapsed))ms")
        return totalDeleted
    }

    @MainActor
    func enterText(rect: String? = nil, text: String, clear: Bool = false) async throws {
        print("Enter Text \(rect ?? "<focused>") -> \(text.prefix(50))... (\(text.count) chars)")
        guard let app else {
            throw Error.noAppFound
        }

        if clear {
            _ = try clearText(rect: rect)
        } else if let rect {
            try tapElement(rect: rect, count: 1, longPress: false)
        }

        let focused = app.descendants(matching: .any)
            .matching(NSPredicate(format: "hasKeyboardFocus == true")).firstMatch
        if !focused.exists {
            _ = focused.waitForExistence(timeout: 2)
        }
        guard focused.exists else {
            throw Error.invalidTool(name: "enterText", message: "No element has keyboard focus.")
        }

        let chunkSize = 100
        var offset = text.startIndex
        while offset < text.endIndex {
            let end = text.index(offset, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            app.typeText(String(text[offset..<end]))
            offset = end
        }
    }

    // MARK: - Device

    @MainActor
    func pressKey(key portalKey: PortalHardwareKey) throws {
        guard let button = portalKey.button else {
            throw Error.unsupportedKey(
                key: portalKey.rawValue,
                message: "\(portalKey.displayName) requires \(portalKey.availabilityDescription). Supported keys: \(PortalHardwareKey.supportedKeysDescription)."
            )
        }

        guard XCUIDevice.shared.hasHardwareButton(button) else {
            throw Error.unsupportedKey(
                key: portalKey.rawValue,
                message: "This device does not have a \(portalKey.displayName) hardware button. Supported keys: \(PortalHardwareKey.supportedKeysDescription)."
            )
        }

        print("Press Key \(button)")
        XCUIDevice.shared.press(button)
    }

    @MainActor
    func takeScreenshot() throws -> Data {
        let snapshot = XCUIScreen.main.screenshot()
        return snapshot.pngRepresentation
    }

    func getDate() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    @MainActor
    func back() throws {
        guard let app = self.app else {
            throw Error.noAppFound
        }
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists && backButton.isHittable {
            print("Tapping navigation bar back button")
            backButton.tap()
            return
        }
        let window = app.windows.element(boundBy: 0)
        if window.exists {
            let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            print("Performing right-edge swipe gesture for back navigation")
            start.press(forDuration: 0.1, thenDragTo: end)
            return
        }
        throw Error.invalidTool(name: "back", message: "No back navigation available.")
    }
}
