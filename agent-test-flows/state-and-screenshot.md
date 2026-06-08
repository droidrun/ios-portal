# State And Screenshot

Use this to verify the read-only state and screenshot endpoints.

## State

```bash
curl -fsS http://127.0.0.1:6643/state > <output-dir>/state.json
python3 - <<'PY'
import json
from pathlib import Path

state = json.loads(Path("<output-dir>/state.json").read_text())
phone_state = state["phone_state"]
screen = state["device_context"]["screen_bounds"]
assert "a11y_tree" in state
assert isinstance(phone_state, dict)
assert screen["width"] > 0
assert screen["height"] > 0
print(phone_state)
PY
```

Expected:

- JSON response.
- `phone_state` exists.
- `device_context.screen_bounds.width` and `device_context.screen_bounds.height` are positive.
- `a11y_tree` exists.

## Screenshot

```bash
curl -fsS http://127.0.0.1:6643/vision/screenshot > <output-dir>/screenshot.png
file <output-dir>/screenshot.png
test -s <output-dir>/screenshot.png
```

Expected:

- PNG image data.
- Non-empty file.

## Follow-Up State

```bash
curl -fsS http://127.0.0.1:6643/state > <output-dir>/state-after-screenshot.json
python3 - <<'PY'
import json
from pathlib import Path

state = json.loads(Path("<output-dir>/state-after-screenshot.json").read_text())
assert "phone_state" in state
assert "a11y_tree" in state
print(state["phone_state"])
PY
```

Expected: state still returns successfully after screenshot capture.
