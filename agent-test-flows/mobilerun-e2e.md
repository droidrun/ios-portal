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

## LLM Agent

Use any configured `mobilerun` LLM provider. Common provider examples:

| Provider | Example env var | Example `--provider` | Example `--model` |
| --- | --- | --- | --- |
| Gemini API key | `GOOGLE_API_KEY` or `GEMINI_API_KEY` | `GoogleGenAI` | `gemini-3.1-flash-lite` |
| Gemini OAuth | cached OAuth credentials | `gemini_oauth_code_assist` | `gemini-3.1-flash-lite` |
| OpenAI / Codex | `OPENAI_API_KEY` or cached OAuth credentials | `OpenAIResponses` or `openai_oauth` | `gpt-5.5` |
| Anthropic Claude | `ANTHROPIC_API_KEY` or cached OAuth credentials | `Anthropic` or `anthropic_oauth` | `claude-sonnet-4-6` |
| OpenAI-compatible | provider-specific key | `OpenAILike` | provider-specific model |

Load provider credentials without printing secrets. For example:

```bash
export GOOGLE_API_KEY="$(tr -d '\n' < "<google-key-file>")"
export GEMINI_API_KEY="$GOOGLE_API_KEY"

export OPENAI_API_KEY="$(tr -d '\n' < "<openai-key-file>")"
export ANTHROPIC_API_KEY="$(tr -d '\n' < "<anthropic-key-file>")"
```

Run each task with the provider/model under test:

```bash
uv run python -m mobilerun run "<task>" \
  --ios \
  --device http://127.0.0.1:6643 \
  --provider <provider> \
  --model <model> \
  --steps 7 \
  --no-stream \
  --save-trajectory none
```

Example Gemini run:

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

- At least two of the three tasks complete successfully for the provider under test.
- If a task fails, classify it as Portal/XCTest, provider/auth/network/model, or
  local `mobilerun` regression.
- Portal remains reachable after the run.
