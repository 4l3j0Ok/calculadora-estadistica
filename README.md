# Calculadora de Probabilidad y Estadística

Aplicación de escritorio (PySide6 + QML) para calcular medidas de
frecuencia y dispersión estadística a partir de datos no agrupados o
agrupados (por valor o por intervalos).

Por defecto los resultados se redondean a **2 decimales**: es una ayuda
pensada para armar a mano las tablas de frecuencia/dispersión en hoja
(exámenes, prácticos), donde ese es el nivel de precisión habitual.

## Requisitos

- Python 3.14 (ver `.python-version`).
- [uv](https://docs.astral.sh/uv/) (recomendado) o `pip`.
- En Linux, las librerías de sistema de Qt/X11 (ver
  `.github/workflows/build-linux.yml` para la lista usada en CI).

## Entorno virtual y dependencias

Con `uv` (recomendado):

```bash
uv sync
```

Esto crea el entorno virtual en `.venv/` e instala `pydantic` y `pyside6`.

Con `venv` + `pip`:

```bash
python -m venv .venv
source .venv/bin/activate   # En Windows: .venv\Scripts\Activate.ps1
pip install .
```

## Ejecutar la app (desarrollo)

```bash
uv run python main.py
# o, con el entorno virtual activado:
python main.py
```

## Build de distribución (Nuitka)

El proyecto se empaqueta como ejecutable **standalone** (no `onefile`) con
[Nuitka](https://nuitka.net/), tanto para Windows como para Linux. Se usa
`standalone` en vez de `onefile` para reducir falsos positivos de
antivirus y facilitar el diagnóstico de problemas (los archivos quedan
visibles en una carpeta, no empaquetados/comprimidos en un solo binario).

Las dependencias de build (`nuitka`, `ordered-set`, `zstandard`) están
declaradas como grupo de dependencias `dev` en `pyproject.toml` (PEP 735,
`uv add --group dev ...`). Para instalarlas junto con las del proyecto:

```bash
uv sync --group dev
```

### Build local en Windows

```powershell
.\scripts\build-windows.ps1
```

Genera:

- Carpeta standalone: `dist/windows/CalculadoraEstadistica-<version>-Windows-x86_64/`
- ZIP listo para distribuir: `dist/releases/CalculadoraEstadistica-<version>-Windows-x86_64.zip`

### Build local en Linux

```bash
chmod +x scripts/build-linux.sh
./scripts/build-linux.sh
```

Genera:

- Carpeta standalone: `dist/linux/CalculadoraEstadistica-<version>-Linux-x86_64/`
- Archivo listo para distribuir: `dist/releases/CalculadoraEstadistica-<version>-Linux-x86_64.tar.gz`

### Ubicación de los artefactos

```text
dist/
├── windows/    # salida cruda de Nuitka + carpeta final renombrada (Windows)
├── linux/      # salida cruda de Nuitka + carpeta final renombrada (Linux)
└── releases/   # .zip / .tar.gz listos para distribuir/adjuntar a un Release
```

`dist/` no se versiona (ver `.gitignore`).

### Resolución de la versión

Los scripts de build resuelven la versión del artefacto en este orden:

1. Tag de git/GitHub (`vX.Y.Z` → `X.Y.Z`).
2. Variable de entorno `APP_VERSION`.
3. Campo `version` de `pyproject.toml`.
4. Fallback `0.0.0-dev`.

## GitHub Actions

Hay dos workflows independientes:

- `.github/workflows/build-windows.yml`
- `.github/workflows/build-linux.yml`

### Disparo manual

Desde la pestaña **Actions** del repositorio, elegir el workflow
correspondiente (`Build Windows` o `Build Linux`) y usar
**Run workflow** (`workflow_dispatch`).

### Generar una release mediante tags

Al publicar un tag `vX.Y.Z` ambos workflows se disparan automáticamente,
compilan su plataforma, suben el artefacto (`actions/upload-artifact`) y
lo adjuntan al GitHub Release asociado a ese tag:

```bash
git tag 1.0.0
git push origin 1.0.0
```
