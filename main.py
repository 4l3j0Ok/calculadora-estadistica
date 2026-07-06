# Directivas de build de Nuitka (ver scripts/build-windows.ps1 y
# scripts/build-linux.sh). Se leen como comentarios al compilar con
# `nuitka main.py`; no afectan la ejecución normal en modo desarrollo.
#
# nuitka-project: --mode=standalone
# nuitka-project: --enable-plugin=pyside6
# nuitka-project: --assume-yes-for-downloads
# nuitka-project: --remove-output
# nuitka-project: --include-data-dir=qml=qml
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
# qml/components/NativeMarkdownView.qml): no usa QtWebEngine ni Chromium.
# Las fórmulas LaTeX se rasterizan con matplotlib.mathtext; se incluye la
# data de matplotlib (mpl-data: fuentes, matplotlibrc) para que el motor
# mathtext funcione en el standalone. Las plantillas Markdown y el
# documento formulas.md viajan embebidos en resources_rc.py (ver
# resources.qrc), no como archivos sueltos.
# nuitka-project: --include-package-data=matplotlib
# nuitka-project: --include-module=matplotlib.backends.backend_agg
# nuitka-project-if: {OS} == "Windows":
#     nuitka-project: --windows-console-mode=disable
#     nuitka-project: --windows-icon-from-ico=assets/calculator.ico
# nuitka-project-if: {OS} == "Linux":
#     nuitka-project: --linux-icon=assets/git.svg

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
from controllers.MarkdownController import MarkdownController
from services.runtime_paths import app_base_dir, app_version


def main():
    app = QApplication(sys.argv)
    app.setFont(QFont("CaskaydiaCove NFM"))
    app.setWindowIcon(QIcon(":/assets/git.svg"))
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
    engine.rootContext().setContextProperty(
        "historyController", history_controller
    )
    engine.rootContext().setContextProperty(
        "markdownController", markdown_controller
    )
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
