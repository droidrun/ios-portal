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

## Architecture

The portal leverages iOS XCTest framework and XCUITest capabilities to:
- Extract UI state information (accessibility trees, screenshots)
- Perform automated interactions (taps, swipes, text input)
- Launch and manage applications
- Handle device-level inputs

### Key Components

- **DroidrunPortalServer**: XCTest class that runs an HTTP server on port 6643, or the next available port up to 6652
- **DroidrunPortalHandler**: HTTP route handler defining the REST API endpoints
- **DroidrunPortalTools**: Core automation engine implementing device interactions
- **AccessibilityTree**: UI state extraction and compression utilities

## Run iOS Portal Locally

Mobilerun does not start iOS Portal automatically. Start this XCTest server
first, then point Mobilerun or any HTTP client at the local Portal URL.

### Prerequisites

- Xcode installed and opened at least once.
- An iOS simulator, or a connected and unlocked physical iPhone/iPad.
- For physical devices, `iproxy` from `libimobiledevice`.

If Xcode signing fails on a local physical device, use a local command-line or
Xcode user setting for your Apple Developer Team. Do not commit local signing
changes to the shared project files.

### Physical iPhone Or iPad

Find the device UDID:

```bash
xcrun xctrace list devices
```

Start the Portal UI test:

```bash
./device.sh <device-udid>
```

Keep that terminal running. In another terminal, forward the device port:

```bash
iproxy -u <device-udid> -s 127.0.0.1 6643:6643
```

If the Xcode log says `Portal server listening on port 6644`, forward local
port `6643` to that device port instead:

```bash
iproxy -u <device-udid> -s 127.0.0.1 6643:6644
```

### iOS Simulator

List available simulators:

```bash
xcrun simctl list devices available
```

Start the Portal:

```bash
./simulator.sh "<simulator-name>"
```

The simulator runs on the Mac, so `iproxy` is not needed.

### Health Checks

Use these checks before running Mobilerun or another client:

```bash
curl -fsS http://127.0.0.1:6643/device/date
curl -fsS 'http://127.0.0.1:6643/state?timeout=4' -o state.json
curl -fsS http://127.0.0.1:6643/vision/screenshot -o screenshot.png
```

Stop the XCTest run and `iproxy` when testing is complete.

## API Reference

### Device Information

#### GET `/device/date`

Returns the current device date. Mobilerun uses this endpoint as a lightweight
Portal health check.

**Response:**
```json
{
  "date": "2026-06-08T20:31:46.766Z"
}
```

### Vision & State Extraction

#### GET `/state`

Returns the current app state, screen bounds, and compressed accessibility tree.

**Response:**
```json
{
  "a11y_tree": "Compressed accessibility tree string",
  "phone_state": {
    "currentApp": "Settings",
    "packageName": "com.apple.Preferences",
    "keyboardVisible": false,
    "isEditable": false,
    "focusedElement": null
  },
  "device_context": {
    "screen_bounds": {
      "width": 440,
      "height": 956
    }
  }
}
```

#### GET `/vision/screenshot`

Captures a screenshot of the current screen.

**Response:** PNG image data (`Content-Type: image/png`)

### App Management

#### POST `/inputs/launch`

Launches an application by bundle identifier.

**Request Body:**
```json
{
  "bundleIdentifier": "com.apple.Preferences"
}
```

**Response:**
```json
{
  "message": "opened com.apple.Preferences"
}
```

### Gesture Automation

#### POST `/gestures/tap`

Performs a tap, double tap, or long press at an iOS rect.

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

Performs a swipe between explicit start and end coordinates.

**Request Body:**
```json
{
  "x1": 100,
  "y1": 700,
  "x2": 100,
  "y2": 200,
  "durationMs": 300
}
```

**Response:**
```json
{
  "message": "swiped"
}
```

#### POST `/gestures/back`

Navigates back when the current app exposes a supported back affordance.

**Response:**
```json
{
  "message": "navigated back"
}
```

### Input Automation

#### POST `/inputs/type`

Enters text into the focused element, or taps `rect` first when provided.

**Request Body:**
```json
{
  "rect": "{{100,200},{50,50}}",
  "text": "Hello World",
  "clear": false
}
```

`rect` and `clear` are optional. `text` is required.

**Response:**
```json
{
  "message": "entered text"
}
```

#### POST `/inputs/key`

Presses supported device hardware keys.

**Request Body:**
```json
{
  "key": 1
}
```

**Supported keys:**
- `1`: Home button
- `2`: Volume up, physical devices only
- `3`: Volume down, physical devices only
- `4`: Action button, iOS 17+ and supported hardware only
- `5`: Camera button, iOS 18+ and supported hardware only

**Response:**
```json
{
  "message": "pressed key"
}
```

## Features

### UI State Extraction
- **Accessibility Tree**: Compressed representation of the UI hierarchy with memory addresses removed
- **Screenshots**: PNG format screen captures
- **App State**: Current application context and keyboard status

### Automation Capabilities
- **App Launching**: Launch any installed app by bundle identifier
- **Touch Interactions**: Single taps, double taps, long presses
- **Gesture Recognition**: Swipe gestures between explicit start and end coordinates
- **Text Input**: Automated typing with keyboard handling
- **Hardware Keys**: Device button presses

### Smart Features
- **App Management**: Automatic app switching and state management
- **Keyboard Detection**: Intelligent keyboard presence detection
- **Focus Management**: Ensures proper element focus for text input
- **Error Handling**: Comprehensive error reporting and validation

## Client Usage

The Portal is designed for automation clients that can:
- send HTTP requests to the Portal endpoints
- read accessibility tree state for UI understanding
- combine `/state` and screenshots for visual verification
- issue one action at a time and observe again after each action

### Direct HTTP Example

```python
import requests

base_url = "http://127.0.0.1:6643"

print(requests.get(f"{base_url}/device/date").json())

state = requests.get(f"{base_url}/state").json()
print(state["phone_state"])

screenshot = requests.get(f"{base_url}/vision/screenshot")
with open("screenshot.png", "wb") as f:
    f.write(screenshot.content)

requests.post(
    f"{base_url}/inputs/launch",
    json={"bundleIdentifier": "com.apple.Preferences"},
)
```

### Mobilerun CLI

After the Portal health checks succeed, install Mobilerun in Python
`>=3.11,<3.14` and point it at the local Portal URL:

```bash
python3.13 -m pip install -U mobilerun

mobilerun device ui --ios --device http://127.0.0.1:6643
mobilerun device screenshot --ios --device http://127.0.0.1:6643
mobilerun device press home --ios --device http://127.0.0.1:6643
mobilerun device start com.apple.Preferences --ios --device http://127.0.0.1:6643
```

Run an LLM-backed task with any configured Mobilerun provider:

```bash
mobilerun run "Open Settings and report the current foreground app." \
  --ios \
  --device http://127.0.0.1:6643 \
  --provider <provider> \
  --model <model> \
  --steps 7 \
  --no-stream \
  --save-trajectory none
```

Example Gemini API-key run:

```bash
export GOOGLE_API_KEY="$(tr -d '\n' < "<google-key-file>")"
export GEMINI_API_KEY="$GOOGLE_API_KEY"

mobilerun run "Open Settings and report the current foreground app." \
  --ios \
  --device http://127.0.0.1:6643 \
  --provider GoogleGenAI \
  --model gemini-3.1-flash-lite \
  --steps 7 \
  --no-stream \
  --save-trajectory none
```

For screenshot-backed reasoning, enable vision:

```bash
mobilerun run "Open Settings and report the current foreground app." \
  --ios \
  --device http://127.0.0.1:6643 \
  --provider GoogleGenAI \
  --model gemini-3.1-flash-lite \
  --steps 7 \
  --vision \
  --no-stream \
  --save-trajectory none
```

## Technical Details

### Dependencies
- **FlyingFox**: HTTP server framework for Swift
- **XCTest**: iOS testing framework for UI automation
- **SwiftUI**: User interface framework

### Server Configuration
- **Port**: 6643, or the next available port up to 6652
- **Protocol**: HTTP/1.1
- **Content Types**: JSON, PNG images
- **Threading**: Async/await support

### Coordinate System
- Uses iOS coordinate system (points, not pixels)
- Rectangle format: `"{{x,y},{width,height}}"`
- Swipe coordinates use explicit start and end points

## Limitations

- Requires iOS testing environment to run
- Limited to apps accessible through XCUITest
- Network access required for remote operation
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
