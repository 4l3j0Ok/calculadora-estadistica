"""Persistencia del historial de operaciones en SQLite.

Usa sqlite3 (stdlib) directamente, sin ORM, siguiendo el estilo del resto
del proyecto (funciones simples, sin capas de abstracción innecesarias).

La base vive en el directorio de datos del usuario (XDG en Linux,
`LOCALAPPDATA` en Windows; ver `services/runtime_paths.py`), nunca junto al
ejecutable/directorio de instalación: en un AppImage ese filesystem está
montado de solo lectura y `sqlite3.connect()` falla con
`OperationalError: unable to open database file`.
"""

import logging
import shutil
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from schemas.history import HistoryEntry, HistoryModule
from services.runtime_paths import get_history_db_path, legacy_history_db_path

logger = logging.getLogger(__name__)

_CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module TEXT NOT NULL,
    data_type TEXT NOT NULL,
    poblacional INTEGER,
    input_payload TEXT NOT NULL,
    result_summary TEXT NOT NULL,
    created_at TEXT NOT NULL
)
"""


def _migrate_legacy_db_if_needed(db_path: Path) -> None:
    """Copia (no mueve) una base heredada de versiones anteriores, que
    guardaban `history.db` junto al ejecutable/fuente (`app_base_dir()`).

    Solo migra si: la base nueva todavía no existe, la base heredada sí
    existe, y son rutas distintas. Nunca sobrescribe la base nueva.
    """
    if db_path.exists():
        return

    legacy_path = legacy_history_db_path()
    if legacy_path == db_path or not legacy_path.is_file():
        return

    logger.info(
        "Migrando historial heredado de %s a %s", legacy_path, db_path
    )
    shutil.copy2(legacy_path, db_path)


def _connect() -> sqlite3.Connection:
    db_path = get_history_db_path()
    try:
        db_path.parent.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise RuntimeError(
            f"No se pudo crear el directorio de la base de historial: {db_path.parent}"
        ) from exc

    _migrate_legacy_db_if_needed(db_path)

    try:
        conn = sqlite3.connect(str(db_path))
    except sqlite3.OperationalError as exc:
        raise RuntimeError(
            f"No se pudo abrir la base de historial en: {db_path}"
        ) from exc

    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    """Crea la tabla `history` si no existe. Debe llamarse al iniciar la app."""
    with _connect() as conn:
        conn.execute(_CREATE_TABLE_SQL)


def insert_entry(
    module: HistoryModule,
    data_type: str,
    input_payload: str,
    result_summary: str,
    poblacional: bool | None = None,
) -> HistoryEntry:
    """Inserta una nueva entrada de historial y retorna el objeto guardado."""
    created_at = datetime.now(timezone.utc).isoformat()
    with _connect() as conn:
        cursor = conn.execute(
            """
            INSERT INTO history
                (module, data_type, poblacional, input_payload, result_summary, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                module.value,
                data_type,
                None if poblacional is None else int(poblacional),
                input_payload,
                result_summary,
                created_at,
            ),
        )
        entry_id = cursor.lastrowid

    return HistoryEntry(
        id=entry_id,
        module=module,
        data_type=data_type,
        poblacional=poblacional,
        input_payload=input_payload,
        result_summary=result_summary,
        created_at=created_at,
    )


def list_entries() -> list[HistoryEntry]:
    """Retorna todas las entradas, más recientes primero."""
    with _connect() as conn:
        rows = conn.execute(
            "SELECT * FROM history ORDER BY id DESC"
        ).fetchall()

    return [
        HistoryEntry(
            id=row["id"],
            module=HistoryModule(row["module"]),
            data_type=row["data_type"],
            poblacional=None if row["poblacional"] is None else bool(row["poblacional"]),
            input_payload=row["input_payload"],
            result_summary=row["result_summary"],
            created_at=row["created_at"],
        )
        for row in rows
    ]


def delete_entry(entry_id: int) -> None:
    """Elimina una entrada de historial por id."""
    with _connect() as conn:
        conn.execute("DELETE FROM history WHERE id = ?", (entry_id,))


def clear_history() -> None:
    """Elimina todas las entradas de historial."""
    with _connect() as conn:
        conn.execute("DELETE FROM history")


def clear_by_module(module: HistoryModule) -> None:
    """Elimina todas las entradas de historial de un módulo puntual."""
    with _connect() as conn:
        conn.execute("DELETE FROM history WHERE module = ?", (module.value,))


def list_entries_by_module(module: HistoryModule) -> list[HistoryEntry]:
    """Retorna las entradas de un módulo, más recientes primero."""
    return [entry for entry in list_entries() if entry.module == module]
