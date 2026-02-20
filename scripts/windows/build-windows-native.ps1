# Build FFmpeg natively on Windows using MSYS2/MinGW
#
# Usage: .\build-windows-native.ps1 [-Force] [-Clean] [-SkipMsys2Setup]
#
# Prerequisites:
#   - MSYS2 installed (https://www.msys2.org/) or this script will install it
#   - ~2GB free disk space for build
#
# Output: output/windows/ (DLLs with DXVA2 + D3D11VA hardware acceleration)

param(
    [switch]$Force,
    [switch]$Clean,
    [switch]$SkipMsys2Setup
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================

$MSYS2_DEFAULT_PATH = "C:\msys64"
$MSYS2_INSTALLER_URL = "https://github.com/msys2/msys2-installer/releases/download/2024-01-13/msys2-x86_64-20240113.exe"
$REQUIRED_PACKAGES = @(
    "mingw-w64-x86_64-toolchain",
    "mingw-w64-x86_64-yasm",
    "mingw-w64-x86_64-nasm",
    "make",
    "diffutils",
    "pkg-config",
    "git"
)

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Info($msg)    { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Warn($msg)    { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)     { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Find-Msys2 {
    # Check common locations
    $paths = @(
        $env:MSYS2_HOME,
        "C:\msys64",
        "C:\msys32",
        "$env:USERPROFILE\msys64",
        "$env:LOCALAPPDATA\msys64"
    ) | Where-Object { $_ -and (Test-Path "$_\usr\bin\bash.exe") }

    if ($paths.Count -gt 0) {
        return $paths[0]
    }
    return $null
}

function Install-Msys2 {
    Write-Info "MSYS2 not found. Installing to $MSYS2_DEFAULT_PATH..."

    $installerPath = "$env:TEMP\msys2-installer.exe"

    Write-Info "Downloading MSYS2 installer..."
    Invoke-WebRequest -Uri $MSYS2_INSTALLER_URL -OutFile $installerPath -UseBasicParsing

    Write-Info "Running MSYS2 installer (silent)..."
    Start-Process -FilePath $installerPath -ArgumentList "install", "--root", $MSYS2_DEFAULT_PATH, "--confirm-command" -Wait -NoNewWindow

    Remove-Item $installerPath -ErrorAction SilentlyContinue

    if (-not (Test-Path "$MSYS2_DEFAULT_PATH\usr\bin\bash.exe")) {
        Write-Err "MSYS2 installation failed"
        exit 1
    }

    # Initialize MSYS2 (first run)
    Write-Info "Initializing MSYS2..."
    & "$MSYS2_DEFAULT_PATH\usr\bin\bash.exe" -lc "exit 0"

    return $MSYS2_DEFAULT_PATH
}

function Install-Msys2Packages($msys2Path) {
    Write-Info "Installing required MSYS2 packages..."
    $packageList = $REQUIRED_PACKAGES -join " "
    & "$msys2Path\usr\bin\bash.exe" -lc "pacman -Syu --noconfirm && pacman -S --needed --noconfirm $packageList"
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to install MSYS2 packages"
        exit 1
    }
    Write-Success "All packages installed"
}

# ============================================================================
# Main
# ============================================================================

Write-Info "=========================================="
Write-Info "FFmpeg Native Windows Build"
Write-Info "=========================================="

# Step 1: Find or install MSYS2
$msys2Path = Find-Msys2
if (-not $msys2Path) {
    if ($SkipMsys2Setup) {
        Write-Err "MSYS2 not found and -SkipMsys2Setup was specified"
        Write-Err "Install MSYS2 from https://www.msys2.org/ or run without -SkipMsys2Setup"
        exit 1
    }
    $msys2Path = Install-Msys2
} else {
    Write-Info "Found MSYS2 at: $msys2Path"
}

# Step 2: Install packages
if (-not $SkipMsys2Setup) {
    Install-Msys2Packages $msys2Path
}

# Step 3: Run the bash build script inside MSYS2 MINGW64 environment
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path "$scriptDir\..\..").Path
# Convert Windows path to MSYS2 path
$msysProjectRoot = $projectRoot -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'

$buildArgs = @()
if ($Force) { $buildArgs += "--force" }
if ($Clean) { $buildArgs += "--clean" }

$argsString = $buildArgs -join " "

Write-Info "Starting FFmpeg build in MSYS2 MINGW64 environment..."
Write-Info "Project root: $msysProjectRoot"

$env:MSYSTEM = "MINGW64"
$env:CHERE_INVOKING = "1"
& "$msys2Path\usr\bin\bash.exe" -lc "cd '$msysProjectRoot' && chmod +x scripts/windows/build-native.sh && ./scripts/windows/build-native.sh $argsString"

if ($LASTEXITCODE -ne 0) {
    Write-Err "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Success "=========================================="
Write-Success "Windows build complete!"
Write-Success "Output: $projectRoot\output\windows\"
Write-Success "=========================================="
