# Directivas de build de Nuitka (ver scripts/build-windows.ps1 y
# scripts/build-linux.sh). Se leen como comentarios al compilar con
# `nuitka main.py`; no afectan la ejecución normal en modo desarrollo.
#
# nuitka-project: --mode=standalone
# nuitka-project: --enable-plugin=pyside6
# nuitka-project: --assume-yes-for-downloads
# nuitka-project: --remove-output
# nuitka-project: --include-data-dir=qml=qml
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
# nuitka-project-if: {OS} == "Windows":
#     nuitka-project: --windows-console-mode=disable
#     nuitka-project: --windows-icon-from-ico=assets/calculator.ico
# nuitka-project-if: {OS} == "Linux":
#     nuitka-project: --linux-icon=assets/calculator.png

import os
import sys

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import (
    QApplication,  # QApplication (no QGuiApplication) carga los plugins de estilo de KDE/plasma-integration
)

import resources_rc  # noqa: F401  (registra los recursos embebidos, p. ej. el ícono)
from controllers.CalculadoraController import CalculadoraController
from controllers.DispersionController import DispersionController
from controllers.HistoryController import HistoryController
from services.runtime_paths import app_base_dir


def main():
    app = QApplication(sys.argv)
    app.setFont(QFont("CaskaydiaCove NFM"))
    app.setWindowIcon(QIcon(":/assets/calculator.png"))
    engine = QQmlApplicationEngine()

    # Registrar controllers para QML (guardar referencia para evitar GC)
    calculadora_controller = CalculadoraController()
    dispersion_controller = DispersionController()
    history_controller = HistoryController()

    engine.rootContext().setContextProperty(
        "calculadoraController", calculadora_controller
    )
    engine.rootContext().setContextProperty(
        "dispersionController", dispersion_controller
    )
    engine.rootContext().setContextProperty(
        "historyController", history_controller
    )

    # Mantener referencias para evitar garbage collection
    app._calculadora_controller = calculadora_controller
    app._dispersion_controller = dispersion_controller
    app._history_controller = history_controller

    qml_path = os.path.join(app_base_dir(), "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_path))
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
