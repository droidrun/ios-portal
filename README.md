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

- **DroidrunPortalServer**: XCTest class that runs an HTTP server on port 6643
- **DroidrunPortalHandler**: HTTP route handler defining the REST API endpoints
- **DroidrunPortalTools**: Core automation engine implementing device interactions
- **AccessibilityTree**: UI state extraction and compression utilities

## API Reference

### Device Information

#### GET `/`
Returns basic device information and description.

**Response:**
```json
{
  "description": "Device description string"
}
```

### Vision & State Extraction

#### GET `/vision/state`
Retrieves current phone state including active app and keyboard status.

**Response:**
```json
{
  "activity": "com.example.app - Screen Title",
  "keyboardShown": false
}
```

#### GET `/vision/a11y`
Extracts the accessibility tree of the current UI state.

**Response:**
```json
{
  "accessibilityTree": "Compressed accessibility tree string"
}
```

#### GET `/vision/screenshot`
Captures a screenshot of the current screen.

**Response:** PNG image data (Content-Type: image/png)

### App Management

#### POST `/inputs/launch`
Launches an application by bundle identifier.

**Request Body:**
```json
{
  "bundleIdentifier": "com.example.app"
}
```

**Response:**
```json
{
  "message": "opened com.example.app"
}
```

### Gesture Automation

#### POST `/gestures/tap`
Performs tap gestures on screen coordinates.

**Request Body:**
```json
{
  "rect": "{{x,y},{width,height}}",
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
Performs swipe gestures from specified coordinates.

**Request Body:**
```json
{
  "x": 100.0,
  "y": 200.0,
  "dir": "up"
}
```

**Supported directions:** `up`, `down`, `left`, `right`

**Response:**
```json
{
  "message": "swiped"
}
```

### Input Automation

#### POST `/inputs/type`
Enters text into a focused input field.

**Request Body:**
```json
{
  "rect": "{{x,y},{width,height}}",
  "text": "Hello World"
}
```

**Response:**
```json
{
  "message": "entered text"
}
```

#### POST `/inputs/key`
Presses device hardware keys.

**Request Body:**
```json
{
  "key": 0
}
```

**Supported keys:**
- `0`: Home button
- `4`: Action button
- `5`: Camera button

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
- **Gesture Recognition**: Swipe gestures in four directions
- **Text Input**: Automated typing with keyboard handling
- **Hardware Keys**: Device button presses

### Smart Features
- **App Management**: Automatic app switching and state management
- **Keyboard Detection**: Intelligent keyboard presence detection
- **Focus Management**: Ensures proper element focus for text input
- **Error Handling**: Comprehensive error reporting and validation

## Usage

### Prerequisites
- iOS device or simulator
- Xcode with XCTest capabilities
- Network access to the device

### Running the Portal

1. Build and run the portal app on the target iOS device
2. The XCTest suite will automatically start the HTTP server on port 6643
3. The server will continue running until the test session ends

### Client Integration

The portal is designed to work with automation agents that can:
- Send HTTP requests to the portal endpoints
- Process accessibility tree data for UI understanding
- Coordinate multiple automation actions
- Handle screenshot analysis for visual verification

### Example Client Usage

```python
import requests

# Get device info
response = requests.get('http://device-ip:6643/')
device_info = response.json()

# Take screenshot
screenshot = requests.get('http://device-ip:6643/vision/screenshot')
with open('screenshot.png', 'wb') as f:
    f.write(screenshot.content)

# Get accessibility tree
a11y = requests.get('http://device-ip:6643/vision/a11y').json()
print(a11y['accessibilityTree'])

# Launch app
requests.post('http://device-ip:6643/inputs/launch', 
              json={'bundleIdentifier': 'com.apple.mobilesafari'})

# Perform tap
requests.post('http://device-ip:6643/gestures/tap',
              json={'rect': '{{100,200},{50,50}}', 'count': 1})
```

## Technical Details

### Dependencies
- **FlyingFox**: HTTP server framework for Swift
- **XCTest**: iOS testing framework for UI automation
- **SwiftUI**: User interface framework

### Server Configuration
- **Port**: 6643 (configurable)
- **Protocol**: HTTP/1.1
- **Content Types**: JSON, PNG images
- **Threading**: Async/await support

### Coordinate System
- Uses iOS coordinate system (points, not pixels)
- Rectangle format: `"{{x,y},{width,height}}"`
- Swipe coordinates specify starting points

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

[Add appropriate license information]

---

**Note**: This is the iOS portal component of the Droidrun framework. For complete automation workflows, integrate with the corresponding agent component that orchestrates automation tasks using this portal's API. 