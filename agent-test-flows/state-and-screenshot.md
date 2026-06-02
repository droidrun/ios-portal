# State And Screenshot

Use this to verify the read-only state and screenshot endpoints.

## State

```bash
curl -fsS http://127.0.0.1:6643/state > <output-dir>/state.json
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
```

Expected:

- PNG image data.
- Non-empty file.

## Follow-Up State

```bash
curl -fsS http://127.0.0.1:6643/state > <output-dir>/state-after-screenshot.json
```

Expected: state still returns successfully after screenshot capture.
