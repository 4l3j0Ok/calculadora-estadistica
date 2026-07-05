"""Tests de services/runtime_paths.py.

Todos los casos usan monkeypatch/tmp_path para no leer ni escribir en el
HOME real del usuario/runner.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from services import runtime_paths


def test_linux_con_xdg_data_home(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr(runtime_paths.sys, "platform", "linux")
    monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))
    monkeypatch.delenv("LOCALAPPDATA", raising=False)

    db_path = runtime_paths.get_history_db_path()

    assert db_path == tmp_path / "calculadora-estadistica" / "history.db"
    assert db_path.parent.is_dir()


def test_linux_sin_xdg_data_home(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr(runtime_paths.sys, "platform", "linux")
    monkeypatch.delenv("XDG_DATA_HOME", raising=False)
    monkeypatch.setattr(runtime_paths.Path, "home", lambda: tmp_path)

    db_path = runtime_paths.get_history_db_path()

    assert db_path == tmp_path / ".local" / "share" / "calculadora-estadistica" / "history.db"
    assert db_path.parent.is_dir()


def test_windows_con_localappdata(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr(runtime_paths.sys, "platform", "win32")
    monkeypatch.setenv("LOCALAPPDATA", str(tmp_path))

    db_path = runtime_paths.get_history_db_path()

    assert db_path == tmp_path / "calculadora-estadistica" / "history.db"
    assert db_path.parent.is_dir()


def test_windows_sin_localappdata(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.setattr(runtime_paths.sys, "platform", "win32")
    monkeypatch.delenv("LOCALAPPDATA", raising=False)
    monkeypatch.setattr(runtime_paths.Path, "home", lambda: tmp_path)

    db_path = runtime_paths.get_history_db_path()

    assert db_path == tmp_path / "AppData" / "Local" / "calculadora-estadistica" / "history.db"
    assert db_path.parent.is_dir()


def test_get_user_data_dir_falla_con_mensaje_claro_si_no_puede_crear(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    monkeypatch.setattr(runtime_paths.sys, "platform", "linux")
    monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))

    def _mkdir_falla(self: Path, *args: object, **kwargs: object) -> None:
        raise OSError("simulado: sin permisos")

    monkeypatch.setattr(runtime_paths.Path, "mkdir", _mkdir_falla)

    with pytest.raises(RuntimeError, match="No se pudo crear el directorio de datos"):
        runtime_paths.get_user_data_dir()
