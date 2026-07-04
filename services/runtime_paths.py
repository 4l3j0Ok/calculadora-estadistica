"""Resolución de rutas base de la app, compatible con dev y builds de Nuitka.

En un build `--mode=standalone` de Nuitka, Nuitka expone la variable global
`__compiled__` en cada módulo compilado, con `__compiled__.containing_dir`
apuntando a la carpeta de la app (junto al ejecutable). En desarrollo (o si
no está compilado), se recurre a la ubicación de este archivo.

Ver: https://nuitka.net/user-documentation/common-issue-solutions.html
"""

import os
import sys


def app_base_dir() -> str:
    """Directorio base de la app (donde viven qml/, assets/, etc.).

    En un build compilado con Nuitka, `sys.argv[0]` es la ruta real del
    ejecutable en el momento de invocarlo (a diferencia de
    `__compiled__.containing_dir`, fijado en tiempo de compilación, que no
    refleja si la carpeta de salida fue luego movida/renombrada). En
    desarrollo se usa la ubicación de este archivo.
    """
    is_compiled = "__compiled__" in globals() or hasattr(sys, "frozen")
    if is_compiled:
        return os.path.dirname(os.path.abspath(sys.argv[0]))
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
