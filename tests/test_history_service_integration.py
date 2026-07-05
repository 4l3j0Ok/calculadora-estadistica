"""Test de integración: history_service + SQLite en el directorio XDG.

Verifica que la base se cree en el directorio de datos del usuario (según
`XDG_DATA_HOME`) y NO junto al ejecutable/proyecto.
"""

from __future__ import annotations

import importlib
from pathlib import Path

import pytest


@pytest.fixture
def history_service_module(monkeypatch: pytest.MonkeyPatch, tmp_path: Path):
    """Recarga `services.history_service` con `XDG_DATA_HOME` apuntando a
    un directorio temporal, para no tocar datos reales del usuario/runner.

    También aísla la ruta "heredada" (`legacy_history_db_path`) a un
    archivo inexistente dentro de `tmp_path`, para que estos tests no
    dependan de si hay o no un `history.db` real junto al proyecto (p. ej.
    en un checkout local de desarrollo).
    """
    monkeypatch.setattr("sys.platform", "linux")
    monkeypatch.setenv("XDG_DATA_HOME", str(tmp_path))
    monkeypatch.delenv("LOCALAPPDATA", raising=False)

    from services import runtime_paths

    importlib.reload(runtime_paths)

    from services import history_service

    importlib.reload(history_service)

    fake_legacy_path = tmp_path / "legacy-no-existe" / "history.db"
    monkeypatch.setattr(
        history_service, "legacy_history_db_path", lambda: fake_legacy_path
    )

    yield history_service, tmp_path

    importlib.reload(runtime_paths)
    importlib.reload(history_service)


def test_init_db_crea_la_base_en_el_directorio_xdg(history_service_module, tmp_path: Path) -> None:
    history_service, xdg_data_home = history_service_module

    history_service.init_db()

    expected_db = xdg_data_home / "calculadora-estadistica" / "history.db"
    assert expected_db.is_file()


def test_insertar_y_listar_entradas_persiste_en_la_base_xdg(
    history_service_module, tmp_path: Path
) -> None:
    from schemas.history import HistoryModule

    history_service, xdg_data_home = history_service_module

    history_service.init_db()
    history_service.insert_entry(
        module=HistoryModule.FRECUENCIAS,
        data_type="no_agrupados",
        input_payload="1;2;3",
        result_summary="media=2",
    )

    entries = history_service.list_entries()
    assert len(entries) == 1
    assert entries[0].result_summary == "media=2"

    expected_db = xdg_data_home / "calculadora-estadistica" / "history.db"
    assert expected_db.is_file()


def test_no_se_crea_ninguna_base_junto_al_proyecto_o_ejecutable(
    history_service_module, tmp_path: Path
) -> None:
    history_service, _xdg_data_home = history_service_module

    from services.runtime_paths import app_base_dir

    legacy_db = Path(app_base_dir()) / "history.db"
    legacy_existia_antes = legacy_db.exists()
    legacy_mtime_antes = legacy_db.stat().st_mtime if legacy_existia_antes else None

    history_service.init_db()

    # init_db() no debe crear (ni modificar) ninguna base junto al
    # proyecto/ejecutable: solo debe tocar el directorio XDG temporal.
    if legacy_existia_antes:
        assert legacy_db.stat().st_mtime == legacy_mtime_antes
    else:
        assert not legacy_db.exists()
