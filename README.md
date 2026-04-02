<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./static/portal-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./static/portal.png">
  <img src="./static/portal.png"  width="full">
</picture>

[![GitHub stars](https://img.shields.io/github/stars/droidrun/ios-portal?style=social)](https://github.com/droidrun/ios-portal/stargazers)
[![Discord](https://img.shields.io/discord/1360219330318696488?color=7289DA&label=Discord&logo=discord&logoColor=white)](https://discord.gg/ZZbKEZZkwK)
[![Documentation](https://img.shields.io/badge/Documentation-📕-blue)](https://docs.droidrun.ai)
[![Twitter Follow](https://img.shields.io/twitter/follow/droid_run?style=social)](https://x.com/droid_run)


A comprehensive iOS automation portal that provides HTTP API access to iOS device UI state extraction and automated interactions.

## Overview

The Droidrun iOS Portal is a specialized iOS application that runs UI tests to expose device automation capabilities through a RESTful HTTP API. It consists of two main components:

1. **Portal App** (`droidrun-ios-portal`): A minimal SwiftUI application that serves as the host
2. **Portal Server** (`droidrun-ios-portalUITests`): XCTest-based HTTP server providing automation APIs

## First-Time Setup

```bash
open droidrun-ios-portal.xcodeproj
```

In Xcode:

1. Set your signing team for both targets:
   - `droidrun-ios-portal`
   - `droidrun-ios-portalUITests`
2. Change both bundle identifiers to unique values you own.
3. Let Xcode generate signing assets for your Apple Developer account.

Example bundle identifiers:
- `com.yourname.droidrun-ios-portal`
- `com.yourname.droidrun-ios-portalUITests`

The default bundle identifiers are not reusable under your Apple Developer account.

If you are deploying to a physical device, you may also need to trust your developer certificate on the device:
- `Settings > General > VPN & Device Management`
- select your developer profile
- tap **Trust**

## Run

```bash
# physical device
./device.sh YOUR_DEVICE_UDID
iproxy 6643 6643

# simulator
./simulator.sh "iPhone 16 Pro"

# verify
curl http://127.0.0.1:6643/device/date
curl http://127.0.0.1:6643/state
```

The server listens on the first available port in the `6643-6652` range.

## Architecture

The portal leverages iOS XCTest framework and XCUITest capabilities to:
- Extract UI state information (unified state payloads, screenshots)
- Perform automated interactions (taps, swipes, text input)
- Launch and manage applications
- Handle device-level inputs

### Key Components

- **DroidrunPortalServer**: XCTest class that runs an HTTP server on the first free port in `6643-6652`
- **DroidrunPortalHandler**: HTTP route handler defining the REST API endpoints
- **DroidrunPortalTools**: Core automation engine implementing device interactions
- **AccessibilityTree**: UI state extraction and compression utilities

## Setup

The portal runs as an Xcode UI test. On physical devices, access it locally over USB port forwarding with `iproxy`.

### Prerequisites

- macOS with Xcode 15+
- Apple Developer account for signing
- iPhone/iPad with Developer Mode enabled, or an iOS Simulator
- `iproxy` from `libimobiledevice` for physical devices

```bash
brew install libimobiledevice
```

### Run on a physical device

1. Open `droidrun-ios-portal.xcodeproj` in Xcode.
2. Update signing for both targets:
   - `droidrun-ios-portal`
   - `droidrun-ios-portalUITests`
3. Change the bundle identifiers to your own unique values.
   You must do this before building. The default bundle identifiers are not available for reuse in your Apple Developer account.

Example:
- `com.yourname.droidrun-ios-portal`
- `com.yourname.droidrun-ios-portalUITests`

4. Let Xcode create signing assets for your Apple Developer account.
5. If prompted on the device, trust your developer certificate:
   - `Settings > General > VPN & Device Management`
   - select your developer profile
   - tap **Trust**
6. Start the server test:

```bash
# Find the device UDID first
xcrun xctrace list devices

# Run the "Droidrun Server" UI test on the device
./device.sh YOUR_DEVICE_UDID
```

7. Forward the port from the device to your Mac:

```bash
iproxy 6643 6643
```

If `6643` is already taken, the server automatically falls back to the next free port up to `6652`. In that case, forward the chosen port instead.

### Run on the simulator

```bash
xcrun simctl list devices available
./simulator.sh "iPhone 16 Pro"
```

The simulator portal is available directly on `http://127.0.0.1:6643` unless the server binds to a later port in the scan range.

### Verify the server

```bash
curl http://127.0.0.1:6643/device/date
```

Example response:

```json
{
  "date": "2026-03-31 10:30:00"
}
```

## API Reference

### State & Observation

#### GET `/state`

Returns the unified state payload used by Droidrun.

**Response:**

```json
{
  "a11y_tree": "Compressed accessibility tree string",
  "phone_state": {
    "currentApp": "Home Screen",
    "packageName": "com.apple.springboard",
    "keyboardVisible": false,
    "isEditable": false,
    "focusedElement": null
  },
  "device_context": {
    "screen_bounds": {
      "width": 430,
      "height": 932
    }
  }
}
```

Notes:
- `a11y_tree` is returned as compressed text, not structured JSON.
- On transient state errors, the server returns an empty fallback payload instead of closing the connection.

#### GET `/vision/screenshot`

Captures a screenshot of the current screen.

**Response:** PNG image data (`Content-Type: image/png`)

#### GET `/device/date`

Returns the current device date and time as a string.

**Response:**

```json
{
  "date": "2026-03-31 10:30:00"
}
```

### App Management

#### POST `/inputs/launch`

Launches an application by bundle identifier.

**Request Body:**

```json
{
  "bundleIdentifier": "com.apple.mobilesafari"
}
```

**Response:**

```json
{
  "message": "opened com.apple.mobilesafari"
}
```

### Gesture Automation

#### POST `/gestures/tap`

Performs a tap, double-tap, or long-press on a rect.

**Request Body:**

```json
{
  "rect": "{{100,200},{50,50}}",
  "count": 1,
  "longPress": false
}
```

**Response:**

```json
{
  "message": "tapped element"
}
```

#### POST `/gestures/swipe`

Performs a swipe between two points.

**Request Body:**

```json
{
  "x1": 200.0,
  "y1": 800.0,
  "x2": 200.0,
  "y2": 200.0,
  "durationMs": 600
}
```

**Response:**

```json
{
  "message": "swiped"
}
```

#### POST `/gestures/back`

Requests backward navigation.

**Response:**

```json
{
  "message": "navigated back"
}
```

### Input Automation

#### POST `/inputs/type`

Types into the currently focused input.

**Request Body:**

```json
{
  "text": "Hello World",
  "clear": true
}
```

`rect` is also accepted as an optional field.

**Response:**

```json
{
  "message": "entered text"
}
```

#### POST `/inputs/key`

Presses a supported hardware key.

**Request Body:**

```json
{
  "key": 1
}
```

**Supported keys:**
- `1`: Home
- `2`: Volume Up (device only)
- `3`: Volume Down (device only)
- `4`: Action
- `5`: Camera

**Response:**

```json
{
  "message": "pressed key"
}
```

## Features

### UI State Extraction
- **Unified State**: One `/state` response containing accessibility tree, phone state, and screen bounds
- **Accessibility Tree**: Compressed representation of the UI hierarchy with memory addresses removed
- **Screenshots**: PNG format screen captures
- **App State**: Current application context, keyboard status, and focused element details

### Automation Capabilities
- **App Launching**: Launch any installed app by bundle identifier
- **Touch Interactions**: Single taps, double taps, long presses
- **Gesture Recognition**: Coordinate-based swipes and back navigation
- **Text Input**: Automated typing with optional field clearing
- **Hardware Keys**: Device button presses

### Smart Features
- **App Management**: Automatic app switching and state management
- **Keyboard Detection**: Intelligent keyboard presence detection
- **Focus Management**: Ensures proper element focus for text input
- **Error Handling**: Comprehensive error reporting and validation

## Usage

### Client Integration

The portal is designed to work with automation agents that can:
- Send HTTP requests to the portal endpoints
- Process accessibility tree data for UI understanding
- Coordinate multiple automation actions
- Handle screenshot analysis for visual verification

### Example Client Usage

```python
import requests

# Health check
date = requests.get("http://127.0.0.1:6643/device/date").json()
print(date["date"])

# Get unified state
state = requests.get("http://127.0.0.1:6643/state").json()
print(state["phone_state"])

# Take screenshot
screenshot = requests.get("http://127.0.0.1:6643/vision/screenshot")
with open("screenshot.png", "wb") as f:
    f.write(screenshot.content)

# Launch app
requests.post(
    "http://127.0.0.1:6643/inputs/launch",
    json={"bundleIdentifier": "com.apple.mobilesafari"},
)

# Perform tap
requests.post(
    "http://127.0.0.1:6643/gestures/tap",
    json={"rect": "{{100,200},{50,50}}", "count": 1, "longPress": False},
)

# Perform swipe
requests.post(
    "http://127.0.0.1:6643/gestures/swipe",
    json={"x1": 200, "y1": 800, "x2": 200, "y2": 200, "durationMs": 600},
)

# Type text into the focused field
requests.post(
    "http://127.0.0.1:6643/inputs/type",
    json={"text": "Hello from Droidrun", "clear": True},
)
```

## Technical Details

### Dependencies
- **FlyingFox**: HTTP server framework for Swift
- **XCTest**: iOS testing framework for UI automation
- **SwiftUI**: User interface framework

### Server Configuration
- **Port**: first free port in `6643-6652`
- **Protocol**: HTTP/1.1
- **Content Types**: JSON, PNG images
- **Threading**: Async/await support

### Coordinate System
- Uses iOS coordinate system (points, not pixels)
- Rectangle format: `"{{x,y},{width,height}}"`
- Swipe coordinates are explicit start and end points

## Limitations

- Requires iOS testing environment to run
- Limited to apps accessible through XCUITest
- Physical-device usage typically relies on `iproxy` over USB
- Some system-level interactions may be restricted

## Security Considerations

- The portal provides full device automation access
- Should only be used in controlled testing environments
- Network access should be restricted to trusted clients
- Consider implementing authentication for production use

## Contributing

This project is part of the larger Droidrun automation framework. Contributions should focus on:
- Enhanced UI state extraction
- Additional gesture support
- Improved error handling
- Performance optimizations

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This is the iOS portal component of the Droidrun framework. For complete automation workflows, integrate with the corresponding agent component that orchestrates automation tasks using this portal's API. 
