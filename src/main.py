# Directivas de build de Nuitka (ver scripts/build-windows.ps1 y
# scripts/build-linux.sh). Se leen como comentarios al compilar con
# `nuitka src/main.py`; no afectan la ejecución normal en modo desarrollo.
#
# nuitka-project: --mode=standalone
# nuitka-project: --enable-plugin=pyside6
# nuitka-project: --assume-yes-for-downloads
# nuitka-project: --remove-output
# nuitka-project: --include-data-dir=src/qml=qml
# nuitka-project: --include-data-dir=src/assets=assets
# nuitka-project: --include-data-files=pyproject.toml=pyproject.toml
# nuitka-project: --report=nuitka-report.xml
#
# Incluye los módulos QML runtime de Qt (QtQuick, QtQuick.Controls,
# QtQuick.Layouts, etc.) y patchea correctamente el rpath de sus plugins
# (.so/.dll). Se excluye explícitamente `Qt/labs/assetdownloader`: en
# algunas versiones de la wheel de PySide6 esa carpeta trae artefactos de
# build (.a/.o) sueltos -no una librería real- que hacen fallar a
# `patchelf` durante el link (no se usa esa API QML en la app).
# nuitka-project: --include-qt-plugins=qml
# nuitka-project: --noinclude-dlls=PySide6/qml/Qt/labs/assetdownloader/*
#
# El visor Markdown es 100% nativo de Qt (TextEdit + QTextDocument, ver
# src/qml/components/NativeMarkdownView.qml): no usa QtWebEngine ni Chromium.
# Las fórmulas LaTeX se rasterizan con matplotlib.mathtext; se incluye la
# data de matplotlib (mpl-data: fuentes, matplotlibrc) para que el motor
# mathtext funcione en el standalone. Las plantillas Markdown y el
# documento formulas.md viajan embebidos en src/resources_rc.py (ver
# src/resources.qrc), no como archivos sueltos.
# nuitka-project: --include-package-data=matplotlib
# nuitka-project: --include-module=matplotlib.backends.backend_agg
# nuitka-project-if: {OS} == "Windows":
#     nuitka-project: --windows-console-mode=disable
#     nuitka-project: --windows-icon-from-ico=src/assets/calculator.ico
# nuitka-project-if: {OS} == "Linux":
#     nuitka-project: --linux-icon=src/assets/calculator.png

import os
import sys

# Layout `src/`: agregar la raíz del repo a `sys.path` para que
# `from src...` funcione al ejecutar `python src/main.py` desde la raíz
# (Python agrega el directorio del script = `src/`, no la raíz) y al
# compilar con Nuitka (que fija `sys.path` al inicio del bundle).
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _REPO_ROOT not in sys.path:
    sys.path.insert(0, _REPO_ROOT)

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import (
    QApplication,  # QApplication (no QGuiApplication) carga los plugins de estilo de KDE/plasma-integration
)

from src import (
    resources_rc,  # noqa: F401  (registra los recursos embebidos, p. ej. el ícono)
)
from src.controllers.CalculadoraController import CalculadoraController
from src.controllers.DispersionController import DispersionController
from src.controllers.HistoryController import HistoryController
from src.controllers.MarkdownController import MarkdownController
from src.services.runtime_paths import app_base_dir, app_version


def main():
    app = QApplication(sys.argv)
    app.setFont(QFont("CaskaydiaCove NFM"))
    app.setWindowIcon(QIcon(":/assets/calculator.png"))
    engine = QQmlApplicationEngine()

    # Registrar controllers para QML (guardar referencia para evitar GC)
    calculadora_controller = CalculadoraController()
    dispersion_controller = DispersionController()
    history_controller = HistoryController()
    markdown_controller = MarkdownController()

    engine.rootContext().setContextProperty(
        "calculadoraController", calculadora_controller
    )
    engine.rootContext().setContextProperty(
        "dispersionController", dispersion_controller
    )
    engine.rootContext().setContextProperty("historyController", history_controller)
    engine.rootContext().setContextProperty("markdownController", markdown_controller)
    engine.rootContext().setContextProperty("appVersion", app_version())

    # Mantener referencias para evitar garbage collection
    app._calculadora_controller = calculadora_controller
    app._dispersion_controller = dispersion_controller
    app._history_controller = history_controller
    app._markdown_controller = markdown_controller

    qml_path = os.path.join(app_base_dir(), "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
