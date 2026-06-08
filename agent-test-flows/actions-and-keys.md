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

## Home Icon Regression

This verifies that tapping a Home-screen icon refreshes the portal's stored app
reference before the next `/state` call.

```bash
curl -fsS -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":1}'

curl -fsS http://127.0.0.1:6643/state > <output-dir>/home-state.json

python3 - <<'PY'
import json
import re
from pathlib import Path

state = json.loads(Path("<output-dir>/home-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "com.apple.springboard", phone_state

for line in state["a11y_tree"].splitlines():
    if "Icon" in line and "Settings" in line:
        match = re.search(r"\{\{([0-9.]+),\s*([0-9.]+)\},\s*\{([0-9.]+),\s*([0-9.]+)\}\}", line)
        if match:
            x, y, w, h = map(float, match.groups())
            Path("<output-dir>/settings-icon-rect.txt").write_text(
                f"{{{{{x:.1f}, {y:.1f}}}, {{{w:.1f}, {h:.1f}}}}}"
            )
            break
else:
    raise AssertionError("Settings icon not visible on Home screen")
PY

rect="$(cat <output-dir>/settings-icon-rect.txt)"
curl -fsS -X POST http://127.0.0.1:6643/gestures/tap \
  -H "Content-Type: application/json" \
  -d "{\"rect\":\"$rect\",\"count\":1,\"longPress\":false}"

curl -fsS http://127.0.0.1:6643/state > <output-dir>/settings-from-icon-state.json

python3 - <<'PY'
import json
from pathlib import Path

state = json.loads(Path("<output-dir>/settings-from-icon-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "com.apple.Preferences", phone_state
print(phone_state)
PY
```

Expected:

- Home state reports `packageName` as `com.apple.springboard`.
- State after tapping the Settings icon reports `packageName` as
  `com.apple.Preferences`.

## Portal App Bundle Regression

This verifies that the portal app itself is recognized by its tracked bundle id
when it is opened from the Home screen. The project bundle id is
`ai.droidrun.droidrun-ios-portal`.

```bash
curl -fsS -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":1}'

curl -fsS http://127.0.0.1:6643/state > <output-dir>/home-state.json

python3 - <<'PY'
import json
import re
from pathlib import Path

state = json.loads(Path("<output-dir>/home-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "com.apple.springboard", phone_state

for line in state["a11y_tree"].splitlines():
    if "Icon" in line and ("Droidrun" in line or "Portal" in line):
        match = re.search(r"\{\{([0-9.]+),\s*([0-9.]+)\},\s*\{([0-9.]+),\s*([0-9.]+)\}\}", line)
        if match:
            x, y, w, h = map(float, match.groups())
            Path("<output-dir>/portal-icon-rect.txt").write_text(
                f"{{{{{x:.1f}, {y:.1f}}}, {{{w:.1f}, {h:.1f}}}}}"
            )
            break
else:
    Path("<output-dir>/portal-icon-rect.txt").write_text("")
    print("Portal app icon not visible; skipping live icon tap check")
PY

rect="$(cat <output-dir>/portal-icon-rect.txt)"
if [ -n "$rect" ]; then
  curl -fsS -X POST http://127.0.0.1:6643/gestures/tap \
    -H "Content-Type: application/json" \
    -d "{\"rect\":\"$rect\",\"count\":1,\"longPress\":false}"

  curl -fsS http://127.0.0.1:6643/state > <output-dir>/portal-app-state.json

  python3 - <<'PY'
import json
from pathlib import Path

state = json.loads(Path("<output-dir>/portal-app-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "ai.droidrun.droidrun-ios-portal", phone_state
PY
fi
```

Expected:

- If the portal icon is visible, state after tapping it reports `packageName` as
  `ai.droidrun.droidrun-ios-portal`.
- If the portal icon is not visible, record the skip reason.

## Unknown Home Icon Regression

This verifies that tapping a Home-screen icon outside the portal's known bundle
list does not leave the portal pinned to Home Screen and does not break later
coordinate gestures. The degraded state must preserve the device's real screen
bounds from Home state. Clock is the default target because it is visible on the
test device and is intentionally not in the known bundle list.

```bash
curl -fsS -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":1}'

curl -fsS http://127.0.0.1:6643/state > <output-dir>/home-state.json

python3 - <<'PY'
import json
import re
from pathlib import Path

state = json.loads(Path("<output-dir>/home-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "com.apple.springboard", phone_state

for line in state["a11y_tree"].splitlines():
    if "Icon" in line and "Clock" in line:
        match = re.search(r"\{\{([0-9.]+),\s*([0-9.]+)\},\s*\{([0-9.]+),\s*([0-9.]+)\}\}", line)
        if match:
            x, y, w, h = map(float, match.groups())
            Path("<output-dir>/unknown-icon-rect.txt").write_text(
                f"{{{{{x:.1f}, {y:.1f}}}, {{{w:.1f}, {h:.1f}}}}}"
            )
            break
else:
    raise AssertionError("Clock icon not visible on Home screen")
PY

rect="$(cat <output-dir>/unknown-icon-rect.txt)"
curl -fsS -X POST http://127.0.0.1:6643/gestures/tap \
  -H "Content-Type: application/json" \
  -d "{\"rect\":\"$rect\",\"count\":1,\"longPress\":false}"

curl -fsS http://127.0.0.1:6643/state > <output-dir>/unknown-app-state.json

python3 - <<'PY'
import json
from pathlib import Path

home = json.loads(Path("<output-dir>/home-state.json").read_text())
state = json.loads(Path("<output-dir>/unknown-app-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["currentApp"] == "Unknown", phone_state
assert phone_state["packageName"] == "", phone_state
assert state["device_context"]["screen_bounds"] == home["device_context"]["screen_bounds"], (
    state["device_context"],
    home["device_context"],
)
PY

curl -fsS -X POST http://127.0.0.1:6643/gestures/tap \
  -H "Content-Type: application/json" \
  -d '{"rect":"{{10.0, 10.0}, {1.0, 1.0}}","count":1,"longPress":false}'

curl -fsS -X POST http://127.0.0.1:6643/inputs/key \
  -H "Content-Type: application/json" \
  -d '{"key":1}'

curl -fsS -X POST http://127.0.0.1:6643/inputs/launch \
  -H "Content-Type: application/json" \
  -d '{"bundleIdentifier":"com.apple.Preferences"}'
```

Expected:

- State after tapping Clock reports `currentApp` as `Unknown`.
- State after tapping Clock does not report `packageName` as
  `com.apple.springboard`.
- State after tapping Clock preserves the same `device_context.screen_bounds`
  reported from Home state.
- A follow-up coordinate tap returns `200`, not `noAppFound`.
- Home and explicit Settings launch recover normal app tracking.

## Home Icon Stress Loop

Run this after the single Home icon regression passes.

```bash
for i in $(seq 1 10); do
  curl -fsS -X POST http://127.0.0.1:6643/inputs/key \
    -H "Content-Type: application/json" \
    -d '{"key":1}' >/dev/null

  curl -fsS http://127.0.0.1:6643/state > <output-dir>/home-state.json

  python3 - <<'PY'
import json
import re
from pathlib import Path

state = json.loads(Path("<output-dir>/home-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "com.apple.springboard", phone_state

for line in state["a11y_tree"].splitlines():
    if "Icon" in line and "Settings" in line:
        match = re.search(r"\{\{([0-9.]+),\s*([0-9.]+)\},\s*\{([0-9.]+),\s*([0-9.]+)\}\}", line)
        if match:
            x, y, w, h = map(float, match.groups())
            Path("<output-dir>/settings-icon-rect.txt").write_text(
                f"{{{{{x:.1f}, {y:.1f}}}, {{{w:.1f}, {h:.1f}}}}}"
            )
            break
else:
    raise AssertionError("Settings icon not visible on Home screen")
PY

  rect="$(cat <output-dir>/settings-icon-rect.txt)"
  curl -fsS -X POST http://127.0.0.1:6643/gestures/tap \
    -H "Content-Type: application/json" \
    -d "{\"rect\":\"$rect\",\"count\":1,\"longPress\":false}" >/dev/null

  curl -fsS http://127.0.0.1:6643/state > <output-dir>/settings-from-icon-state.json

  python3 - <<'PY'
import json
from pathlib import Path

state = json.loads(Path("<output-dir>/settings-from-icon-state.json").read_text())
phone_state = state["phone_state"]
assert phone_state["packageName"] == "com.apple.Preferences", phone_state
PY

  echo "ok $i"
done
```

Expected: all 10 iterations print `ok <n>` and the portal server remains reachable.

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
