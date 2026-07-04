"""Persistencia del historial de operaciones en SQLite.

Usa sqlite3 (stdlib) directamente, sin ORM, siguiendo el estilo del resto
del proyecto (funciones simples, sin capas de abstracción innecesarias).
"""

import sqlite3
from datetime import datetime, timezone
from pathlib import Path

from schemas.history import HistoryEntry, HistoryModule

DB_PATH = Path(__file__).resolve().parent.parent / "history.db"

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


def _connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
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
