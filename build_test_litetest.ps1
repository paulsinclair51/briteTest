param(
    [string]$Compiler = 'gcc',
    [string]$BuildDir = 'build',
    [string]$Output = 'test_litetest.exe'
)

# PowerShell build script for LiteTest on Windows POSIX toolchains.
# Intended for MSYS2 (UCRT64/Clang64) where gcc/clang/cc are on PATH.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

if (-not (Get-Command $Compiler -ErrorAction SilentlyContinue)) {
    throw "Compiler '$Compiler' was not found on PATH. Install MSYS2 UCRT64/Clang64 and add its bin directory to PATH."
}

$cppFlags = @('-Iinclude', '-D_POSIX_C_SOURCE=200809L')
$cFlags = @('-std=c11', '-Wall', '-Wextra', '-Wno-clobbered', '-O2')

$sources = @(
    'src/litetest_runner.c',
    'src/litetest_test.c',
    'tests/test_litetest.c',
    'tests/test_orchestrator.c',
    'tests/test_guard1.c',
    'tests/test_guard2.c'
)

if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
}

$objects = @()
foreach ($source in $sources) {
    if (-not (Test-Path $source)) {
        throw "Missing source file: $source"
    }

    $object = Join-Path $BuildDir (([System.IO.Path]::GetFileNameWithoutExtension($source)) + '.o')
    Write-Host "Compiling $source -> $object"
    & $Compiler @cppFlags @cFlags '-c' $source '-o' $object
    if ($LASTEXITCODE -ne 0) {
        throw "Compile failed for $source"
    }

    $objects += $object
}

Write-Host "Linking -> $Output"
& $Compiler @cFlags '-o' $Output @objects
if ($LASTEXITCODE -ne 0) {
    throw 'Link failed'
}

Write-Host "Build complete: $Output"
Write-Host "Run: .\$Output"
