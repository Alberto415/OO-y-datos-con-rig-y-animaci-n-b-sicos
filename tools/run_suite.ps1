param(
    [string]$Godot = "godot",
    [string]$Output = "res://results"
)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
& $Godot --headless --path $projectRoot --import
if ($LASTEXITCODE -ne 0) { throw "Fallo de importación." }
& $Godot --headless --path $projectRoot --script scripts/verify.gd
if ($LASTEXITCODE -ne 0) { throw "Fallo de equivalencia." }
& $Godot --path $projectRoot -- --suite "--out=$Output"
if ($LASTEXITCODE -ne 0) { throw "Fallo de medición." }
Write-Output "Suite terminada. Analizar los CSV con tools/analyze.py."
