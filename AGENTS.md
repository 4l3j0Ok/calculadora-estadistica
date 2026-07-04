# Repository Notes

- Active project: `poo-ayudante-de-catedra/02-calculadora-p-y-e`, a small PySide6/QML desktop app for probability/statistics calculators.
- Run project commands from `poo-ayudante-de-catedra/02-calculadora-p-y-e`; `main.py` loads `qml/Main.qml` via a relative path.
- Tooling is `uv` with Python `3.14` from `.python-version`; dependencies are only `pydantic` and `pyside6` in `pyproject.toml`/`uv.lock`.

## Commands

- Install/sync dependencies: `uv sync`.
- Launch the GUI app: `uv run python main.py`.
- Fast Python syntax/import verification: `uv run python -m compileall main.py controllers schemas services`.
- Regenerate embedded Qt resources after editing `resources.qrc` or `assets/calculator.png`: `uv run pyside6-rcc resources.qrc -o resources_rc.py`.
- QML lint is available with `uv run pyside6-qmllint qml/*.qml qml/components/*.qml`, but the current tree emits many existing warnings; use it mainly for focused checks unless cleaning those warnings is in scope.

## Architecture

- `main.py` creates `QApplication`, registers `CalculadoraController` and `DispersionController` as QML context properties, keeps references on `app` to avoid GC, and loads `qml/Main.qml`.
- QML pages call Python slots by the context property names `calculadoraController` and `dispersionController`; keep slot signatures compatible with those calls.
- Parsing/validation for both calculators is centralized in `services/parser.py`; calculation logic is centralized in `services/calculator.py`; controllers should mostly translate between QML JSON/models and those services.
- Pydantic models/enums live in `schemas/`; frequency-table and dispersion models are separate even when parsing helpers are shared.
- `resources_rc.py` is generated from `resources.qrc` and imported for side effects so `:/assets/calculator.png` works.

## Input Quirks

- Non-grouped numeric input uses semicolon-separated values because comma is accepted as a decimal separator and normalized to `.`.
- Grouped QML rows are JSON objects with `xi`/`frecuencia` or `lower`/`upper`/`frecuencia`; parser errors are user-facing Spanish messages.
