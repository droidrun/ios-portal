# Agent Test Flows

Small Markdown runbooks for checking the iOS Portal HTTP API on a simulator or physical iPhone.

## Use This Folder

1. Start the portal with `setup-and-server.md`.
2. Check state and screenshots with `state-and-screenshot.md`.
3. Check safe actions and hardware keys with `actions-and-keys.md`.
4. Report pass, fail, or skip for each command you ran.

## Target Inputs

Fill these values at test time:

| Value | Meaning |
| --- | --- |
| `<simulator-name>` | Simulator name passed to `./simulator.sh` |
| `<device-udid>` | Physical iPhone UDID passed to `./device.sh` and `iproxy` |
| `<portal-url>` | Usually `http://127.0.0.1:6643` |
| `<output-dir>` | Temporary directory for saved state and screenshot files |

Do not hardcode local simulator names, device IDs, hostnames, or personal paths in these docs.

## Current API Checks

| Check | Endpoint or command |
| --- | --- |
| Start on simulator | `./simulator.sh "<simulator-name>"` |
| Start on phone | `./device.sh <device-udid>` |
| Date | `GET /device/date` |
| State | `GET /state` |
| Screenshot | `GET /vision/screenshot` |
| Launch app | `POST /inputs/launch` |
| Tap | `POST /gestures/tap` |
| Swipe | `POST /gestures/swipe` |
| Type text | `POST /inputs/type` |
| Hardware key | `POST /inputs/key` |
| Back | `POST /gestures/back` |

## Safety

- Use coordinates from the current `/state` response or visible UI.
- Do not type into accounts, payment fields, messages, or personal apps.
- Stop the portal test run and `iproxy` when the smoke check is complete.
