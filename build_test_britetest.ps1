#-----------------------------------------------------------------
# Build Powershell script for test_britetest (Linux/macOS)
#
# test_liteteest.exe is an executable that uses the BriteTest
# framework and APIs to test itself.
#
#-----------------------------------------------------------------
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see the LICENSE file in the root directory.
#-----------------------------------------------------------------
#
# test_britetest can be run by submitting a command line of the
# following form to a shell:
#
#   [<directory_path>/]test_britetest [<option>],,, [<arg>]...
#
# For usage information about the options and args, submit the
# follpwing to a shell:
#
#   [<directory_path>/]test_britetest --help
#
# For an introduction to BriteTest, see README.md in ghe root
# directory.
#----------------------------------------------------------------

param(
    [string]$Compiler = 'gcc',
    [string]$BuildDir = 'build',
    [string]$Output = 'test_britetest.exe'
)

# PowerShell build script for BriteTest on Windows POSIX toolchains.
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
    'src/runnerapi.c',
    'src/testapi.c',
    'tests/src/test_runner.c',
    'tests/src/orchestrator_tests.c',
    'tests/src/file_compare_tests.c',
    'tests/src/guard1_tests.c',
    'tests/src/guard2_tests.c'
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
