# Actions And Keys

Use this to verify safe portal actions. Start from a running portal at `http://127.0.0.1:6643`.

## Launch Settings

```bash
curl -fsS -X POST http://127.0.0.1:6643/inputs/launch \
  -H "Content-Type: application/json" \
  -d '{"bundleIdentifier":"com.apple.Preferences"}'
```

Expected: `{"message":"opened com.apple.Preferences"}`.

Capture state after launch:

```bash
curl -fsS http://127.0.0.1:6643/state > <output-dir>/settings-state.json
python3 - <<'PY'
import json
from pathlib import Path

state = json.loads(Path("<output-dir>/settings-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "com.apple.Preferences", phone_state
print(phone_state)
PY
```

## Tap

Choose a visible, safe Settings row from `/state`.

```bash
curl -fsS -X POST http://127.0.0.1:6643/gestures/tap \
  -H "Content-Type: application/json" \
  -d '{"rect":"{{<x>,<y>},{<width>,<height>}}","count":1,"longPress":false}'
```

Expected: `{"message":"tapped element"}`.

## Swipe

Swipe inside a visible scrollable Settings area.

```bash
curl -fsS -X POST http://127.0.0.1:6643/gestures/swipe \
  -H "Content-Type: application/json" \
  -d '{"x1":<start-x>,"y1":<start-y>,"x2":<end-x>,"y2":<end-y>,"durationMs":300}'
```

Expected: `{"message":"swiped"}`.

## Type

Only type after focusing a safe local field, such as the Settings search field.

```bash
curl -fsS -X POST http://127.0.0.1:6643/inputs/type \
  -H "Content-Type: application/json" \
  -d '{"rect":"{{<x>,<y>},{<width>,<height>}}","text":"portal smoke","clear":true}'
```

Expected: `{"message":"entered text"}`.

## Back

Run after navigating into a Settings subpage.

```bash
curl -fsS -X POST http://127.0.0.1:6643/gestures/back \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected: `{"message":"navigated back"}`.

## Hardware Keys

Home should work on simulator and physical iPhone:

```bash
curl -i -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":1}'
```

Volume keys should only be expected on physical iPhones that support them:

```bash
curl -i -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":2}'
```

```bash
curl -i -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":3}'
```

Newer device buttons should return `200` only when the OS and hardware support them, otherwise clear `400` JSON:

```bash
curl -i -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":4}'
```

```bash
curl -i -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":5}'
```

Invalid keys should return clear `400` JSON:

```bash
curl -i -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":99}'
```

Expected:

- HTTP status `400`.
- JSON body includes an `error` field.

## Home State Regression

This verifies that pressing Home updates the portal's stored app reference. It
prevents `/state` from querying a stale foreground app after Home.

```bash
curl -fsS -X POST http://127.0.0.1:6643/inputs/launch \
  -H "Content-Type: application/json" \
  -d '{"bundleIdentifier":"com.apple.Preferences"}'

curl -fsS http://127.0.0.1:6643/state > <output-dir>/settings-state.json

curl -fsS -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":1}'

curl -fsS http://127.0.0.1:6643/state > <output-dir>/home-state.json

python3 - <<'PY'
import json
from pathlib import Path

settings = json.loads(Path("<output-dir>/settings-state.json").read_text())
home = json.loads(Path("<output-dir>/home-state.json").read_text())
assert settings["phone_state"]["packageName"] == "com.apple.Preferences"
assert home["phone_state"]["packageName"] == "com.apple.springboard", home["phone_state"]
assert home["phone_state"]["currentApp"] == "Home Screen", home["phone_state"]
print("settings:", settings["phone_state"])
print("home:", home["phone_state"])
PY

curl -fsS -X POST http://127.0.0.1:6643/inputs/launch \
  -H "Content-Type: application/json" \
  -d '{"bundleIdentifier":"com.apple.Preferences"}'
```

Expected:

- Settings state reports `packageName` as `com.apple.Preferences`.
- Home state reports `packageName` as `com.apple.springboard`.
- Home state reports `currentApp` as `Home Screen`.
- Relaunching Settings returns `{"message":"opened com.apple.Preferences"}`.

## Home State Stress Loop

Run this after the single Home regression passes.

```bash
for i in $(seq 1 10); do
  curl -fsS -X POST http://127.0.0.1:6643/inputs/launch \
    -H "Content-Type: application/json" \
    -d '{"bundleIdentifier":"com.apple.Preferences"}' >/dev/null

  curl -fsS http://127.0.0.1:6643/state > <output-dir>/settings-state.json

  curl -fsS -X POST http://127.0.0.1:6643/inputs/key \
    -H "Content-Type: application/json" \
    -d '{"key":1}' >/dev/null

  curl -fsS http://127.0.0.1:6643/state > <output-dir>/home-state.json

  python3 - <<'PY'
import json
from pathlib import Path

settings = json.loads(Path("<output-dir>/settings-state.json").read_text())
home = json.loads(Path("<output-dir>/home-state.json").read_text())
assert settings["phone_state"]["packageName"] == "com.apple.Preferences", settings["phone_state"]
assert home["phone_state"]["packageName"] == "com.apple.springboard", home["phone_state"]
assert home["phone_state"]["currentApp"] == "Home Screen", home["phone_state"]
PY

  echo "ok $i"
done
```

Expected: all 10 iterations print `ok <n>` and the portal server remains reachable.
