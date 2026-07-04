#!/usr/bin/env bash
# Build standalone de Linux con Nuitka.
#
# Uso:
#   chmod +x scripts/build-linux.sh
#   ./scripts/build-linux.sh
#
# Puede ejecutarse desde cualquier directorio. Resuelve la raíz del repo
# de forma relativa a este script.

set -euo pipefail

# ── Resolución de rutas ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${REPO_ROOT}"

APP_NAME="CalculadoraEstadistica"
ENTRYPOINT="main.py"
OUTPUT_DIR="dist/linux"
RELEASES_DIR="dist/releases"

echo "==> Raíz del repositorio: ${REPO_ROOT}"

# ── Verificar Python ─────────────────────────────────────────────────────
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    echo "ERROR: no se encontró un intérprete de Python en el PATH." >&2
    exit 1
fi
echo "==> Usando intérprete: $(command -v "${PYTHON_BIN}") ($(${PYTHON_BIN} --version))"

# ── Usar el entorno virtual activo si existe ─────────────────────────────
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    echo "==> Entorno virtual activo detectado: ${VIRTUAL_ENV}"
elif [[ -x "${REPO_ROOT}/.venv/bin/python" ]]; then
    echo "==> Activando entorno virtual local: ${REPO_ROOT}/.venv"
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/.venv/bin/activate"
    PYTHON_BIN="python"
else
    echo "==> No se encontró un entorno virtual; se usará el intérprete del sistema."
fi

# ── Instalar/verificar dependencias ──────────────────────────────────────
# Las dependencias de build (nuitka, ordered-set, zstandard) viven en el
# grupo de dependencias "dev" de pyproject.toml (uv add --group dev ...).
if command -v uv >/dev/null 2>&1; then
    echo "==> Sincronizando dependencias del proyecto (incluyendo grupo 'dev') con uv..."
    uv sync --group dev
    RUN_PREFIX=(uv run)
else
    echo "==> uv no está disponible; instalando dependencias con pip..."
    "${PYTHON_BIN}" -m pip install --upgrade pip
    "${PYTHON_BIN}" -m pip install .
    "${PYTHON_BIN}" -m pip install nuitka ordered-set zstandard
    RUN_PREFIX=("${PYTHON_BIN}")
fi

# ── Resolver versión ──────────────────────────────────────────────────────
# Orden: 1) tag de git/GitHub  2) variable de entorno APP_VERSION
#        3) versión en pyproject.toml  4) fallback 0.0.0-dev
resolve_version() {
    if [[ -n "${GITHUB_REF_NAME:-}" && "${GITHUB_REF_NAME}" == v* ]]; then
        echo "${GITHUB_REF_NAME#v}"
        return
    fi
    if git_tag="$(git -C "${REPO_ROOT}" describe --tags --exact-match 2>/dev/null)"; then
        echo "${git_tag#v}"
        return
    fi
    if [[ -n "${APP_VERSION:-}" ]]; then
        echo "${APP_VERSION}"
        return
    fi
    if [[ -f "${REPO_ROOT}/pyproject.toml" ]]; then
        pyproject_version="$(grep -m1 '^version' "${REPO_ROOT}/pyproject.toml" | sed -E 's/version[[:space:]]*=[[:space:]]*"([^"]+)"/\1/')"
        if [[ -n "${pyproject_version}" ]]; then
            echo "${pyproject_version}"
            return
        fi
    fi
    echo "0.0.0-dev"
}

VERSION="$(resolve_version)"
echo "==> Versión resuelta: ${VERSION}"

# ── Limpiar outputs anteriores del build (solo los de este script) ──────
echo "==> Limpiando salidas anteriores en ${OUTPUT_DIR}..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}" "${RELEASES_DIR}"

# ── Ejecutar Nuitka ───────────────────────────────────────────────────────
echo "==> Compilando con Nuitka (standalone, Linux)..."
"${RUN_PREFIX[@]}" python -m nuitka \
    --output-dir="${OUTPUT_DIR}" \
    --output-filename="${APP_NAME}" \
    --report="${OUTPUT_DIR}/nuitka-report.xml" \
    "${ENTRYPOINT}"

DIST_DIR="${OUTPUT_DIR}/main.dist"
if [[ ! -d "${DIST_DIR}" ]]; then
    echo "ERROR: no se encontró la carpeta de salida esperada: ${DIST_DIR}" >&2
    exit 1
fi

BINARY_PATH="${DIST_DIR}/${APP_NAME}"
if [[ ! -f "${BINARY_PATH}" ]]; then
    # Nuitka nombra el binario según --output-filename; si no se aplicó,
    # cae de vuelta al nombre del entrypoint sin extensión.
    BINARY_PATH="${DIST_DIR}/main"
fi

if [[ -f "${BINARY_PATH}" ]]; then
    echo "==> Marcando el binario principal como ejecutable: ${BINARY_PATH}"
    chmod +x "${BINARY_PATH}"
else
    echo "ADVERTENCIA: no se encontró el binario principal dentro de ${DIST_DIR}" >&2
fi

# ── Renombrar carpeta final ───────────────────────────────────────────────
FINAL_DIR_NAME="${APP_NAME}-${VERSION}-Linux-x86_64"
FINAL_DIR="${OUTPUT_DIR}/${FINAL_DIR_NAME}"
rm -rf "${FINAL_DIR}"
mv "${DIST_DIR}" "${FINAL_DIR}"

# ── Empaquetar en tar.gz ──────────────────────────────────────────────────
ARCHIVE_NAME="${APP_NAME}-${VERSION}-Linux-x86_64.tar.gz"
ARCHIVE_PATH="${RELEASES_DIR}/${ARCHIVE_NAME}"
echo "==> Empaquetando en ${ARCHIVE_PATH}..."
tar -czf "${ARCHIVE_PATH}" -C "${OUTPUT_DIR}" "${FINAL_DIR_NAME}"

echo ""
echo "==> Build de Linux completado."
echo "    Carpeta standalone: ${FINAL_DIR}"
echo "    Archivo comprimido: ${ARCHIVE_PATH}"
