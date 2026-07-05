"""Resolución de rutas de la app, compatible con dev y builds de Nuitka.

Hay dos categorías de rutas, que no deben mezclarse:

- Recursos de solo lectura (`qml/`, `assets/`, etc.): viven junto al
  ejecutable/fuente. Ver `app_base_dir()`.
- Datos modificables del usuario (p. ej. `history.db`): NUNCA deben vivir
  junto al ejecutable, en el directorio de instalación, en el `cwd`, ni en
  el filesystem montado de un AppImage (`/tmp/.mount_*/...`), porque esos
  lugares pueden ser de solo lectura o desaparecer al cerrar la app. Deben
  ir al directorio de datos del usuario (XDG en Linux, `LOCALAPPDATA` en
  Windows). Ver `get_user_data_dir()` / `get_history_db_path()`.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

APP_DATA_DIR_NAME = "calculadora-estadistica"
HISTORY_DB_FILENAME = "history.db"


def app_base_dir() -> str:
    """Directorio base de recursos de solo lectura (qml/, assets/, etc.).

    En un build `--mode=standalone` de Nuitka, `sys.argv[0]` es la ruta
    real del ejecutable en el momento de invocarlo (a diferencia de
    `__compiled__.containing_dir`, fijado en tiempo de compilación, que no
    refleja si la carpeta de salida fue luego movida/renombrada). En
    desarrollo se usa la ubicación de este archivo.

    Importante: este directorio puede ser de solo lectura (p. ej. el
    filesystem montado de un AppImage). No usar para datos modificables;
    para eso ver `get_user_data_dir()`.
    """
    is_compiled = "__compiled__" in globals() or hasattr(sys, "frozen")
    if is_compiled:
        return os.path.dirname(os.path.abspath(sys.argv[0]))
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def get_user_data_dir() -> Path:
    """Directorio de datos persistentes y escribibles del usuario.

    - Windows: `%LOCALAPPDATA%\\calculadora-estadistica` (o
      `~\\AppData\\Local\\calculadora-estadistica` si `LOCALAPPDATA` no
      está definida).
    - Resto de plataformas (Linux/macOS): respeta XDG,
      `${XDG_DATA_HOME:-~/.local/share}/calculadora-estadistica`.

    Crea el directorio si no existe. Lanza `RuntimeError` con la ruta
    intentada si no se puede crear (no se oculta el error).
    """
    if sys.platform == "win32":
        base_dir = os.environ.get("LOCALAPPDATA")
        if base_dir:
            data_dir = Path(base_dir) / APP_DATA_DIR_NAME
        else:
            data_dir = Path.home() / "AppData" / "Local" / APP_DATA_DIR_NAME
    else:
        xdg_data_home = os.environ.get("XDG_DATA_HOME")
        if xdg_data_home:
            data_dir = Path(xdg_data_home) / APP_DATA_DIR_NAME
        else:
            data_dir = Path.home() / ".local" / "share" / APP_DATA_DIR_NAME

    try:
        data_dir.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        raise RuntimeError(
            f"No se pudo crear el directorio de datos del usuario: {data_dir}"
        ) from exc

    return data_dir


def get_history_db_path() -> Path:
    """Ruta completa a la base SQLite del historial, en el directorio de
    datos del usuario (ver `get_user_data_dir()`)."""
    return get_user_data_dir() / HISTORY_DB_FILENAME


def legacy_history_db_path() -> Path:
    """Ruta donde versiones anteriores guardaban `history.db` (junto al
    ejecutable/fuente, vía `app_base_dir()`). Solo se usa para migrar datos
    existentes a `get_history_db_path()`; no debe usarse para escribir."""
    return Path(app_base_dir()) / HISTORY_DB_FILENAME
