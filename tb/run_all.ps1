# Запуск всех тестбенчей ЛР4 (Icarus Verilog).
#   cd done/lab4
#   powershell -File tb/run_all.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$lab2 = Join-Path $root "..\lab2"
$lab3 = Join-Path $root "..\lab3\rtl"
$rtl  = Join-Path $root "rtl"
$tb   = Join-Path $root "tb"

function Run-Tb([string]$name, [string[]]$sources) {
    Write-Host "=== $name ===" -ForegroundColor Cyan
    $out = Join-Path $tb "$name.vvp"
    & iverilog -o $out @sources
    if ($LASTEXITCODE -ne 0) { throw "iverilog failed: $name" }
    $log = & vvp $out 2>&1 | Out-String
    Write-Host $log
    if ($log -notmatch "${name}: PASS") { throw "$name did not PASS" }
}

Run-Tb "lfsr8_tb" @(
    "$rtl\lfsr8.v", "$tb\lfsr8_tb.v"
)

Run-Tb "crc8_tb" @(
    "$rtl\crc8.v", "$tb\crc8_tb.v"
)

Run-Tb "bist_tb" @(
    "$lab2\addr.v", "$lab2\mult.v", "$lab2\cbrt.v", "$lab2\sqrt.v", "$lab2\func_calc.v",
    "$lab3\btn_sync.v", "$lab3\hex_to_7seg_dynamic.v",
    "$rtl\lfsr8.v", "$rtl\crc8.v", "$rtl\bist_control.v", "$rtl\bist_top.v",
    "$tb\bist_tb.v"
)

Write-Host "ALL PASS" -ForegroundColor Green
