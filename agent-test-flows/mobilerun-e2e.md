# Mobilerun E2E

Use this to verify `mobilerun` against a running iOS Portal at
`http://127.0.0.1:6643`.

## Static And Focused Checks

Run from the `mobilerun` repo:

```bash
cd <mobilerun-repo>
env UV_CACHE_DIR=/private/tmp/uv-cache-mobilerun uv lock --check
env UV_CACHE_DIR=/private/tmp/uv-cache-mobilerun uv run python -m pytest \
  tests/test_ios_provider.py \
  tests/test_visual_remote_connection.py \
  tests/test_provider_registry.py \
  tests/test_gemini_oauth_llm.py \
  tests/test_llm_picker.py \
  tests/test_vision_only_run_cli.py \
  -q
env UV_CACHE_DIR=/private/tmp/uv-cache-mobilerun uv run ruff check mobilerun tests
env UV_CACHE_DIR=/private/tmp/uv-cache-mobilerun uv run --extra dev black --check mobilerun tests
```

Expected:

- Lock check exits `0`.
- Focused tests pass.
- Ruff and Black checks pass.

## Direct CLI

```bash
uv run python -m mobilerun device ui --ios --device http://127.0.0.1:6643
uv run python -m mobilerun device screenshot --ios --device http://127.0.0.1:6643
uv run python -m mobilerun device press home --ios --device http://127.0.0.1:6643
uv run python -m mobilerun device start com.apple.Preferences --ios --device http://127.0.0.1:6643
uv run python -m mobilerun device ui --ios --device http://127.0.0.1:6643
```

If the Settings search field is visible, tap it and type safe local text:

```bash
uv run python -m mobilerun device tap <search-x> <search-y> --ios --device http://127.0.0.1:6643
uv run python -m mobilerun device type "wifi" --clear --ios --device http://127.0.0.1:6643
```

Expected:

- UI output contains `phone_state`.
- Screenshot command writes a PNG path.
- Home succeeds.
- Settings launches and reports `packageName` as `com.apple.Preferences`.
- Safe typing succeeds when a text field is focused.

## Gemini Agent

Load the Gemini key without printing it:

```bash
export GEMINI_API_KEY="$(tr -d '\n' < "<gemini-key-file>")"
export GOOGLE_API_KEY="$GEMINI_API_KEY"
```

Run each task:

```bash
uv run python -m mobilerun run "<task>" \
  --ios \
  --device http://127.0.0.1:6643 \
  --provider GoogleGenAI \
  --model gemini-3.1-flash-lite \
  --steps 7 \
  --no-stream \
  --save-trajectory none
```

Recommended tasks:

1. `Open Settings and report the current foreground app.`
2. `Open Settings, search for Wi-Fi, and report whether Wi-Fi results are visible.`
3. `Return to the Home screen, open Settings from the icon, and report the foreground app.`

Expected:

- At least two of the three tasks complete successfully.
- If a task fails, classify it as Portal/XCTest, Gemini/auth/network/model, or
  local `mobilerun` regression.
- Portal remains reachable after the run.
