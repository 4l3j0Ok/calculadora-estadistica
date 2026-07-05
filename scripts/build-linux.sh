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

EXECUTABLE_NAME="${APP_NAME}"
BINARY_PATH="${DIST_DIR}/${EXECUTABLE_NAME}"
if [[ ! -f "${BINARY_PATH}" ]]; then
    # Nuitka nombra el binario según --output-filename; si no se aplicó,
    # cae de vuelta al nombre del entrypoint sin extensión.
    EXECUTABLE_NAME="main"
    BINARY_PATH="${DIST_DIR}/${EXECUTABLE_NAME}"
fi

if [[ -f "${BINARY_PATH}" ]]; then
    echo "==> Marcando el binario principal como ejecutable: ${BINARY_PATH}"
    chmod +x "${BINARY_PATH}"
else
    echo "ERROR: no se encontró el binario principal dentro de ${DIST_DIR}" >&2
    exit 1
fi
echo "==> Nombre del ejecutable detectado: ${EXECUTABLE_NAME}"

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

# ═══════════════════════════════════════════════════════════════════════
# AppImage
#
# A partir de acá, el pipeline es:
#   FINAL_DIR (standalone de Nuitka, ya validado arriba)
#   → AppDir (deployment/AppRun + .desktop + .metainfo.xml + bibliotecas
#     XCB/XKB del sistema)
#   → appimagetool
#   → AppImage + AppImage.zsync
#
# No se usa linuxdeploy/appimage-builder/pkg2appimage ni se corre patchelf
# sobre el standalone: el contenido de FINAL_DIR se copia tal cual.
# ═══════════════════════════════════════════════════════════════════════

NUITKA_DIST="${FINAL_DIR}"
DEPLOYMENT_DIR="${REPO_ROOT}/deployment"
APP_ID="io.github.4l3j0Ok.calculadora-estadistica"
SYSTEM_LIB_DIR="/usr/lib/x86_64-linux-gnu"

echo ""
echo "==> Iniciando empaquetado en AppImage..."

# ── Validar el standalone fuera del repo ─────────────────────────────────
# Corre el ejecutable copiado a una carpeta temporal ajena al repositorio,
# para confirmar que QML/assets están realmente embebidos en el standalone
# (--include-data-dir en main.py) y no se están leyendo por accidente
# desde el árbol fuente.
echo "==> Validando el standalone de Nuitka fuera del repositorio..."
TEMP_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_TEST_DIR}"' EXIT

cp -a "${NUITKA_DIST}" "${TEMP_TEST_DIR}/app.dist"

NUITKA_SMOKE_LOG="${OUTPUT_DIR}/nuitka-smoke.log"
set +e
timeout 15s \
    xvfb-run -a \
    "${TEMP_TEST_DIR}/app.dist/${EXECUTABLE_NAME}" \
    >"${NUITKA_SMOKE_LOG}" 2>&1
nuitka_smoke_status=$?
set -e

if [[ ${nuitka_smoke_status} -ne 0 && ${nuitka_smoke_status} -ne 124 ]]; then
    echo "ERROR: el standalone de Nuitka terminó con código ${nuitka_smoke_status}." >&2
    cat "${NUITKA_SMOKE_LOG}" >&2
    exit 1
fi

FORBIDDEN_PATTERNS=(
    "Could not load the Qt platform plugin"
    "QQmlApplicationEngine failed"
    "ModuleNotFoundError"
    "ImportError"
    "cannot open shared object file"
    "No such file or directory"
    "[Ss]egmentation fault"
    "Aborted"
)
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    if grep -qE "${pattern}" "${NUITKA_SMOKE_LOG}"; then
        echo "ERROR: se encontró '${pattern}' en ${NUITKA_SMOKE_LOG}:" >&2
        cat "${NUITKA_SMOKE_LOG}" >&2
        exit 1
    fi
done
echo "==> Standalone validado correctamente (código de salida: ${nuitka_smoke_status})."

# ── Localizar libqxcb.so dentro del standalone ───────────────────────────
LIBQXCB="$(find "${NUITKA_DIST}" -type f -name libqxcb.so -print -quit)"
if [[ -z "${LIBQXCB}" ]]; then
    echo "ERROR: no se encontró libqxcb.so dentro de ${NUITKA_DIST}." >&2
    exit 1
fi
echo "==> libqxcb.so encontrado: ${LIBQXCB}"

# ── Preparar el AppDir ────────────────────────────────────────────────────
APPDIR="${OUTPUT_DIR}/${APP_NAME}.AppDir"
echo "==> Preparando AppDir: ${APPDIR}"
rm -rf "${APPDIR}"
APP_ROOT="${APPDIR}/usr/share/calculadora-estadistica"
mkdir -p \
    "${APP_ROOT}" \
    "${APPDIR}/usr/bin" \
    "${APPDIR}/usr/lib/x86_64-linux-gnu" \
    "${APPDIR}/usr/share/applications" \
    "${APPDIR}/usr/share/icons/hicolor/256x256/apps" \
    "${APPDIR}/usr/share/metainfo"

# Copia íntegra del standalone de Nuitka: no se reorganiza ni se mueven
# archivos individualmente (.so, plugins Qt, .pyc, recursos de Nuitka
# quedan tal como los dejó Nuitka, junto al ejecutable).
cp -a "${NUITKA_DIST}/." "${APP_ROOT}/"

# ── Enlace del ejecutable en usr/bin ──────────────────────────────────────
ln -rs "${APP_ROOT}/${EXECUTABLE_NAME}" "${APPDIR}/usr/bin/${EXECUTABLE_NAME}"

# ── AppRun ────────────────────────────────────────────────────────────────
install -m 0755 "${DEPLOYMENT_DIR}/AppRun" "${APPDIR}/AppRun"

# ── Bibliotecas XCB/XKB del sistema ───────────────────────────────────────
# Solo se copian estas bibliotecas (y opcionalmente libX11-xcb/libXau/
# libXdmcp). Qt, Python, PySide6 y Shiboken siguen viniendo del standalone
# de Nuitka; no se tocan libc/libstdc++/libGL/libwayland/etc. del sistema.
echo "==> Copiando bibliotecas XCB/XKB del sistema (${SYSTEM_LIB_DIR})..."
APP_LIB_DIR="${APPDIR}/usr/lib/x86_64-linux-gnu"
shopt -s nullglob

xcb_libs=("${SYSTEM_LIB_DIR}"/libxcb-*.so*)
xkb_libs=(
    "${SYSTEM_LIB_DIR}"/libxkbcommon.so*
    "${SYSTEM_LIB_DIR}"/libxkbcommon-x11.so*
)

if (( ${#xcb_libs[@]} == 0 )); then
    echo "ERROR: no se encontraron libxcb-*.so* en ${SYSTEM_LIB_DIR}." >&2
    exit 1
fi
if (( ${#xkb_libs[@]} == 0 )); then
    echo "ERROR: no se encontraron bibliotecas libxkbcommon en ${SYSTEM_LIB_DIR}." >&2
    exit 1
fi

cp -aL "${xcb_libs[@]}" "${APP_LIB_DIR}/"
cp -aL "${xkb_libs[@]}" "${APP_LIB_DIR}/"

optional_libs=(
    "${SYSTEM_LIB_DIR}"/libX11-xcb.so*
    "${SYSTEM_LIB_DIR}"/libXau.so*
    "${SYSTEM_LIB_DIR}"/libXdmcp.so*
)
if (( ${#optional_libs[@]} > 0 )); then
    cp -aL "${optional_libs[@]}" "${APP_LIB_DIR}/"
fi
shopt -u nullglob

# ── Validar libqxcb.so con las bibliotecas copiadas ───────────────────────
LIBQXCB_LDD_LOG="${OUTPUT_DIR}/libqxcb-ldd.log"
LD_LIBRARY_PATH="${APP_LIB_DIR}:${NUITKA_DIST}" \
    ldd "${LIBQXCB}" >"${LIBQXCB_LDD_LOG}"
if grep -q "not found" "${LIBQXCB_LDD_LOG}"; then
    echo "ERROR: libqxcb.so tiene dependencias sin resolver:" >&2
    cat "${LIBQXCB_LDD_LOG}" >&2
    exit 1
fi
echo "==> libqxcb.so resuelve correctamente todas sus dependencias."

# ── Integración de escritorio (.desktop, metainfo, ícono) ─────────────────
install -m 0644 \
    "${DEPLOYMENT_DIR}/${APP_ID}.desktop" \
    "${APPDIR}/usr/share/applications/${APP_ID}.desktop"
install -m 0644 \
    "${DEPLOYMENT_DIR}/${APP_ID}.metainfo.xml" \
    "${APPDIR}/usr/share/metainfo/${APP_ID}.metainfo.xml"
install -m 0644 \
    "${REPO_ROOT}/assets/calculator.png" \
    "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${APP_ID}.png"

ln -sf \
    "usr/share/applications/${APP_ID}.desktop" \
    "${APPDIR}/${APP_ID}.desktop"
ln -sf \
    "usr/share/icons/hicolor/256x256/apps/${APP_ID}.png" \
    "${APPDIR}/${APP_ID}.png"
cp "${REPO_ROOT}/assets/calculator.png" "${APPDIR}/.DirIcon"

echo "==> AppDir preparado."

# ── Descargar y verificar appimagetool ────────────────────────────────────
APPIMAGETOOL_VERSION="1.9.1"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-x86_64.AppImage"
APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
APPIMAGETOOL="${OUTPUT_DIR}/.build-tools/appimagetool-x86_64.AppImage"

mkdir -p "$(dirname "${APPIMAGETOOL}")"
if [[ ! -f "${APPIMAGETOOL}" ]]; then
    echo "==> Descargando appimagetool ${APPIMAGETOOL_VERSION}..."
    curl -sL -o "${APPIMAGETOOL}" "${APPIMAGETOOL_URL}"
fi

echo "==> Verificando SHA-256 de appimagetool..."
echo "${APPIMAGETOOL_SHA256}  ${APPIMAGETOOL}" | sha256sum -c -
chmod +x "${APPIMAGETOOL}"

# ── Construir el AppImage ─────────────────────────────────────────────────
mkdir -p "${RELEASES_DIR}"
APPIMAGE_NAME="${APP_NAME}-${VERSION}-x86_64.AppImage"
APPIMAGE_PATH="${RELEASES_DIR}/${APPIMAGE_NAME}"
UPDATE_INFO='gh-releases-zsync|4l3j0Ok|calculadora-estadistica|latest|CalculadoraEstadistica-*-x86_64.AppImage.zsync'

rm -f "${APPIMAGE_PATH}" "${APPIMAGE_PATH}.zsync"

echo "==> Ejecutando appimagetool..."
export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH=x86_64
export VERSION

APPIMAGETOOL_ABS="$(cd "$(dirname "${APPIMAGETOOL}")" && pwd)/$(basename "${APPIMAGETOOL}")"
APPDIR_ABS="$(cd "${APPDIR}" && pwd)"
APPIMAGE_PATH_ABS="${REPO_ROOT}/${APPIMAGE_PATH}"

# appimagetool (vía zsyncmake) escribe el .zsync en el directorio de
# trabajo actual, no junto al AppImage generado; por eso se ejecuta con
# cwd = RELEASES_DIR para que ambos archivos queden en el mismo lugar.
(
    cd "${RELEASES_DIR}"
    "${APPIMAGETOOL_ABS}" \
        -u "${UPDATE_INFO}" \
        "${APPDIR_ABS}" \
        "${APPIMAGE_PATH_ABS}"
)

if [[ ! -f "${APPIMAGE_PATH}" ]]; then
    echo "ERROR: appimagetool no generó ${APPIMAGE_PATH}." >&2
    exit 1
fi
if [[ ! -f "${APPIMAGE_PATH}.zsync" ]]; then
    echo "ERROR: appimagetool no generó ${APPIMAGE_PATH}.zsync." >&2
    exit 1
fi
chmod +x "${APPIMAGE_PATH}"
echo "==> AppImage generado: ${APPIMAGE_PATH}"
echo "==> zsync generado: ${APPIMAGE_PATH}.zsync"

# ── Smoke test del AppImage ────────────────────────────────────────────────
echo "==> Ejecutando smoke test del AppImage..."
APPIMAGE_SMOKE_LOG="${OUTPUT_DIR}/appimage-smoke.log"
set +e
timeout 15s env \
    APPIMAGE_EXTRACT_AND_RUN=1 \
    xvfb-run -a \
    "${APPIMAGE_PATH}" \
    >"${APPIMAGE_SMOKE_LOG}" 2>&1
appimage_smoke_status=$?
set -e

if [[ ${appimage_smoke_status} -ne 0 && ${appimage_smoke_status} -ne 124 ]]; then
    echo "ERROR: el AppImage terminó con código ${appimage_smoke_status}." >&2
    cat "${APPIMAGE_SMOKE_LOG}" >&2
    exit 1
fi
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    if grep -qE "${pattern}" "${APPIMAGE_SMOKE_LOG}"; then
        echo "ERROR: se encontró '${pattern}' en ${APPIMAGE_SMOKE_LOG}:" >&2
        cat "${APPIMAGE_SMOKE_LOG}" >&2
        exit 1
    fi
done
echo "==> Smoke test del AppImage OK (código de salida: ${appimage_smoke_status})."

# ── Verificar la update information embebida ──────────────────────────────
# Nota: --appimage-updateinfo lo resuelve el runtime del AppImage sin
# necesidad de FUSE ni de montar/extraer nada. No debe usarse
# APPIMAGE_EXTRACT_AND_RUN=1 acá: ese flag hace que el runtime salte el
# manejo de argumentos especiales y termine ejecutando AppRun con
# "--appimage-updateinfo" como argumento de la aplicación (que no lo
# entiende y falla).
echo "==> Verificando --appimage-updateinfo..."
ACTUAL_UPDATE_INFO="$("${APPIMAGE_PATH}" --appimage-updateinfo)"
if [[ "${ACTUAL_UPDATE_INFO}" != "${UPDATE_INFO}" ]]; then
    echo "ERROR: update information inesperada." >&2
    echo "  esperado: ${UPDATE_INFO}" >&2
    echo "  obtenido: ${ACTUAL_UPDATE_INFO}" >&2
    exit 1
fi
echo "==> Update information OK: ${ACTUAL_UPDATE_INFO}"

echo ""
echo "==> Empaquetado en AppImage completado."
echo "    AppDir:   ${APPDIR}"
echo "    AppImage: ${APPIMAGE_PATH}"
echo "    zsync:    ${APPIMAGE_PATH}.zsync"
