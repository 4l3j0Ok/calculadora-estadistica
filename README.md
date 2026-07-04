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
2. Variable de entorno `APP_VERSION` (usada por `release.yml` para pasar
   la versión ya resuelta por semantic-release a los builds).
3. Campo `version` de `pyproject.toml` (mantenido al día automáticamente
   por semantic-release en cada release).
4. Fallback `0.0.0-dev`.

## Releases automatizadas (semantic-release)

La versión y las releases de GitHub se generan automáticamente con
[semantic-release](https://semantic-release.org/) a partir de los mensajes
de commit en `main`, siguiendo [Conventional Commits](https://www.conventionalcommits.org/):

| Tipo de commit                    | Efecto en la versión                    |
| ---------------------------------- | ---------------------------------------- |
| `fix:`, `perf:`, `style:`          | patch (`0.1.0` → `0.1.1`)                 |
| `feat:`, `refactor:`               | minor (`0.1.0` → `0.2.0`)                 |
| pie `BREAKING CHANGE: ...`         | major (`0.1.0` → `1.0.0`)                 |
| `docs:`, `chore:`, `build:`, `ci:`, `test:` | no genera release                |

La configuración vive en `.releaserc.json`. En cada push a `main` (que no
sea el propio commit de release), el workflow
`.github/workflows/release.yml`:

1. Corre `semantic-release`, que analiza los commits, decide la próxima
   versión, genera/actualiza `CHANGELOG.md`, actualiza la versión en
   `pyproject.toml`/`uv.lock` (via `uv version --frozen`, plugin
   `@semantic-release/exec`), commitea esos cambios como
   `chore(release): X.Y.Z [skip ci]` y crea el tag `X.Y.Z` (sin prefijo
   `v`, ver `tagFormat` en `.releaserc.json`) junto con el GitHub Release.
2. Si hubo una release nueva, dispara `build-windows.yml` y
   `build-linux.yml` (como workflows reutilizables) para compilar ambas
   plataformas y adjuntar sus artefactos (`.zip` / `.tar.gz`) a ese
   Release.

No hace falta crear tags a mano: alcanza con mergear/pushear commits con
el formato correcto a `main`.

Dependencias de Node necesarias solo para correr `semantic-release` (no
son parte de la app): están en `package.json` y se instalan en CI con
`npm install`. Localmente, para probar la config (no recomendado hacer un
release real desde la máquina local):

```bash
npm install
npx semantic-release --dry-run
```

## GitHub Actions

Hay tres workflows:

- `.github/workflows/release.yml` — orquesta semantic-release y, si
  corresponde, dispara los builds.
- `.github/workflows/build-windows.yml`
- `.github/workflows/build-linux.yml`

`build-windows.yml` y `build-linux.yml` **no** se disparan con pushes de
tags: solo se ejecutan como workflows reutilizables (`workflow_call`)
invocados desde `release.yml` cuando hubo una release nueva, o
manualmente (`workflow_dispatch`). No crean ni gestionan releases de
GitHub por su cuenta; solo adjuntan su artefacto al Release que ya existe
(creado por `release.yml`/semantic-release) cuando reciben el input
`app_version`.

### Disparo manual

Desde la pestaña **Actions** del repositorio, elegir el workflow
correspondiente (`Release`, `Build Windows` o `Build Linux`) y usar
**Run workflow** (`workflow_dispatch`). Al correr `Build Windows`/`Build
Linux` manualmente (sin pasar por `release.yml`) no se adjunta ningún
artefacto a un Release: solo queda disponible como artifact del run
(`actions/upload-artifact`), útil para probar el build sin publicar nada.
