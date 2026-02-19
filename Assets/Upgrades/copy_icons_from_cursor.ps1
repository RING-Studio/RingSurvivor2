# 将 Cursor 生成的图标从 Cursor 项目 assets 复制到本目录 (Assets/Upgrades)
# 在 PowerShell 中执行: .\copy_icons_from_cursor.ps1
$src = "$env:USERPROFILE\.cursor\projects\d-tools-godot-Projects-RingSurvivor2\assets"
$dst = $PSScriptRoot
if (-not (Test-Path $src)) { Write-Host "Source not found: $src"; exit 1 }
$count = 0
Get-ChildItem $src -Filter "*.png" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $dst $_.Name) -Force
    $count++
    Write-Host "Copied $($_.Name)"
}
Write-Host "Done. Copied $count files."
