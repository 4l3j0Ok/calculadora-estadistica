# Repository Notes

- This is a root-level PySide6/QML desktop app; run normal project commands from the repository root so `uv` uses this `pyproject.toml`/`uv.lock`.
- Python is pinned by `.python-version` to `3.14`; dependency management is `uv`. Runtime deps include PySide6, Pydantic, Jinja2, and Markdown; build/test deps are in the `dev` dependency group.
- `package.json` is only for semantic-release tooling; it is not part of the Python app runtime.

## Commands

- Sync runtime deps: `uv sync`.
- Sync build/test deps too: `uv sync --group dev`.
- Launch the GUI app: `uv run python src/main.py`.
- Build configuration for Nuitka lives in `[tool.nuitka]` of `pyproject.toml`; the per-OS bits (icon, console mode) are passed by `scripts/build-linux.sh` / `scripts/build-windows.ps1`.
- Run tests: `uv run pytest`.
- Run one test file: `uv run pytest tests/test_markdown_io.py`.
- Fast syntax/import check: `uv run python -m compileall src`.
- Regenerate Qt resources after editing `resources.qrc` or any file embedded there: `uv run pyside6-rcc resources.qrc -o resources_rc.py`.
- Linux release build: `./scripts/build-linux.sh` after `uv sync --group dev`; it also does its own dependency sync and smoke tests under `xvfb-run`.
- Windows release build: `./scripts/build-windows.ps1` after `uv sync --group dev`.

## Architecture

- `src/main.py` is the app entrypoint. It creates `QApplication`, imports `resources_rc` for Qt resource registration, registers `calculadoraController`, `dispersionController`, `historyController`, `markdownController`, and `appVersion` in QML, then loads `qml/Main.qml` via `src.services.runtime_paths.app_base_dir()`.
- Keep QML slot/property names compatible with those context properties; the QML pages call Python slots directly.
- Parsing and user-facing Spanish validation errors are centralized in `src/services/parser.py`; statistical calculation is in `src/services/calculator.py` and `src/services/descriptive_stats.py`; controllers should mainly translate between QML JSON/models and services.
- Pydantic models live in `src/schemas/`; frequency, dispersion, and history schemas are separate even when parser helpers are shared.
- Markdown copy/paste uses `src/services/markdown_io.py` with Jinja2 templates from `assets/templates/*.md.j2`; those templates are embedded through `resources.qrc` but also have a filesystem fallback for tests.

## Data And Resources

- Read-only app resources (`qml/`, `assets/`, `pyproject.toml`) are resolved relative to `app_base_dir()` so dev and Nuitka standalone builds work; do not use that path for writable data.
- History is SQLite via `src/services/history_service.py` and must stay in the user data dir: `${XDG_DATA_HOME:-~/.local/share}/calculadora-estadistica/history.db` on Linux/macOS or `%LOCALAPPDATA%\calculadora-estadistica\history.db` on Windows.
- `history_service` copies a legacy `history.db` from the app base only when the new user-data DB does not exist; never write new mutable state beside the executable/project.
- `resources_rc.py` is generated from `resources.qrc`; update it whenever embedded assets or Markdown templates change.

## Input Quirks

- Non-grouped numeric input uses semicolon-separated values because comma is accepted as a decimal separator and normalized to `.`.
- Grouped rows passed from QML are JSON objects with `xi`/`frecuencia` or `lower`/`upper`/`frecuencia`.
- Interval rows are sorted by lower bound and validated against overlap; contiguous intervals are allowed.

## Releases

- `.releaserc.json` releases only from `main`, with tag format `X.Y.Z` (no `v`).
- `semantic-release` updates `CHANGELOG.md`, `pyproject.toml`, and `uv.lock` via `uv version --frozen`, then commits `chore(release): X.Y.Z [skip ci]`.
- Build scripts resolve artifact version from exact git/GitHub tag, then `APP_VERSION`, then `pyproject.toml`, then `0.0.0-dev`; release workflows pass `APP_VERSION` through `app_version`.
- GitHub build workflows are reusable/manual; release assets are attached only when called with `app_version` from `release.yml`.
