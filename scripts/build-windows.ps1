#requires -Version 5.1
<#
.SYNOPSIS
    Build standalone de Windows con Nuitka.

.EXAMPLE
    .\scripts\build-windows.ps1

    Puede ejecutarse desde cualquier ubicación; resuelve la raíz del repo
    en base a la ubicación de este script.
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ── Resolución de rutas ──────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $RepoRoot

$AppName = "CalculadoraEstadistica"
$ProductName = "Calculadora de Probabilidad y Estadistica"
$CompanyName = "4l3j0Ok"
$FileDescription = "Calculadora de Probabilidad y Estadistica (POO)"
$Copyright = "Copyright (c) $((Get-Date).Year) $CompanyName"
$Entrypoint = "main.py"
$OutputDir = "dist\windows"
$ReleasesDir = "dist\releases"
$IconPath = "assets\calculator.ico"

Write-Host "==> Raiz del repositorio: $RepoRoot"

# ── Verificar Python ──────────────────────────────────────────────────────
$PythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $PythonCmd) {
    $PythonCmd = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $PythonCmd) {
    Write-Error "No se encontro un interprete de Python en el PATH."
    exit 1
}
Write-Host "==> Usando interprete: $($PythonCmd.Source)"
& $PythonCmd.Source --version

# ── Usar el entorno virtual activo si existe ──────────────────────────────
if ($env:VIRTUAL_ENV) {
    Write-Host "==> Entorno virtual activo detectado: $env:VIRTUAL_ENV"
} elseif (Test-Path (Join-Path $RepoRoot ".venv\Scripts\Activate.ps1")) {
    Write-Host "==> Activando entorno virtual local: $RepoRoot\.venv"
    & (Join-Path $RepoRoot ".venv\Scripts\Activate.ps1")
} else {
    Write-Host "==> No se encontro un entorno virtual; se usara el interprete del sistema."
}

# ── Instalar/verificar dependencias ───────────────────────────────────────
# Las dependencias de build (nuitka, ordered-set, zstandard) viven en el
# grupo de dependencias "dev" de pyproject.toml (uv add --group dev ...).
$UvCmd = Get-Command uv -ErrorAction SilentlyContinue
if ($UvCmd) {
    Write-Host "==> Sincronizando dependencias del proyecto (incluyendo grupo 'dev') con uv..."
    uv sync --group dev
    if ($LASTEXITCODE -ne 0) { throw "uv sync fallo." }
    $RunCmd = "uv"
    $RunCmdArgs = @("run")
} else {
    Write-Host "==> uv no esta disponible; instalando dependencias con pip..."
    & $PythonCmd.Source -m pip install --upgrade pip
    & $PythonCmd.Source -m pip install .
    & $PythonCmd.Source -m pip install nuitka ordered-set zstandard
    $RunCmd = $PythonCmd.Source
    $RunCmdArgs = @()
}

# ── Resolver version ───────────────────────────────────────────────────────
# Orden: 1) tag de git/GitHub  2) variable de entorno APP_VERSION
#        3) version en pyproject.toml  4) fallback 0.0.0-dev
function Resolve-AppVersion {
    if ($env:GITHUB_REF_NAME) {
        return $env:GITHUB_REF_NAME.Substring(1)
    }
    try {
        $gitTag = git -C $RepoRoot describe --tags --exact-match 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitTag) {
            return ($gitTag -replace '^v', '')
        }
    } catch {
        # ignorar: no hay tag exacto en el commit actual
    }
    if ($env:APP_VERSION) {
        return $env:APP_VERSION
    }
    $pyprojectPath = Join-Path $RepoRoot "pyproject.toml"
    if (Test-Path $pyprojectPath) {
        $match = Select-String -Path $pyprojectPath -Pattern '^version\s*=\s*"([^"]+)"' | Select-Object -First 1
        if ($match) {
            return $match.Matches[0].Groups[1].Value
        }
    }
    return "0.0.0-dev"
}

$Version = Resolve-AppVersion
Write-Host "==> Version resuelta: $Version"

# Version numerica para metadata de Windows (formato x.x.x.x)
$VersionNumericParts = ($Version -replace '[^0-9.].*$', '') -split '\.'
$VersionNumericParts = @($VersionNumericParts | Where-Object { $_ -ne "" })
while ($VersionNumericParts.Count -lt 4) { $VersionNumericParts += "0" }
$WindowsVersion = ($VersionNumericParts[0..3] -join ".")
Write-Host "==> Version numerica (metadata Windows): $WindowsVersion"

# ── Limpiar outputs anteriores del build (solo los de este script) ──────
Write-Host "==> Limpiando salidas anteriores en $OutputDir..."
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $ReleasesDir | Out-Null

if (-not (Test-Path $IconPath)) {
    Write-Error "No se encontro el icono: $IconPath"
    exit 1
}

# ── Ejecutar Nuitka ────────────────────────────────────────────────────────
Write-Host "==> Compilando con Nuitka (standalone, Windows)..."
$NuitkaArgs = @(
    "python", "-m", "nuitka",
    "--output-dir=$OutputDir",
    "--output-filename=${AppName}.exe",
    "--report=$OutputDir\nuitka-report.xml",
    "--company-name=$CompanyName",
    "--product-name=$ProductName",
    "--file-description=$FileDescription",
    "--copyright=$Copyright",
    "--file-version=$WindowsVersion",
    "--product-version=$WindowsVersion",
    $Entrypoint
)
& $RunCmd @RunCmdArgs @NuitkaArgs
if ($LASTEXITCODE -ne 0) { throw "La compilacion con Nuitka fallo (codigo $LASTEXITCODE)." }

$DistDir = Join-Path $OutputDir "main.dist"
if (-not (Test-Path $DistDir)) {
    Write-Error "No se encontro la carpeta de salida esperada: $DistDir"
    exit 1
}

$FinalDirName = "$AppName-$Version-Windows-x86_64"
$FinalDir = Join-Path $OutputDir $FinalDirName
if (Test-Path $FinalDir) {
    Remove-Item -Recurse -Force $FinalDir
}
Move-Item -Path $DistDir -Destination $FinalDir

# ── Empaquetar en ZIP ──────────────────────────────────────────────────────
$ArchiveName = "$AppName-$Version-Windows-x86_64.zip"
$ArchivePath = Join-Path $ReleasesDir $ArchiveName
if (Test-Path $ArchivePath) {
    Remove-Item -Force $ArchivePath
}
Write-Host "==> Empaquetando en $ArchivePath..."
Compress-Archive -Path $FinalDir -DestinationPath $ArchivePath -CompressionLevel Optimal

Write-Host ""
Write-Host "==> Build de Windows completado."
Write-Host "    Carpeta standalone: $FinalDir"
Write-Host "    Archivo comprimido: $ArchivePath"
