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
