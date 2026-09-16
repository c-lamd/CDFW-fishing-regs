# Copies bin\FishRegs.prg onto the watch over USB (MTP). From WSL:
#   powershell.exe -ExecutionPolicy Bypass -File "$(wslpath -w sideload.ps1)"
# Manual fallback: drag bin\FishRegs.prg into This PC > Descent G2 > (Primary) > GARMIN > APPS, then eject.
# Never delete the old .prg first: that pops a confirm dialog that blocks headlessly. CopyHere flag 16 = yes to all.
$prg = Join-Path $PSScriptRoot 'bin\FishRegs.prg'
if (-not (Test-Path $prg)) { throw "Build first: $prg not found" }
$shell = New-Object -ComObject Shell.Application
$dev = $shell.NameSpace(0x11).Items() | Where-Object { $_.Name -like '*Descent*' } | Select-Object -First 1
if (-not $dev) { throw 'Watch not found under This PC. Reseat the charging clip and wait for it to enumerate.' }
$folder = $dev.GetFolder
for ($depth = 0; $depth -lt 3; $depth++) {
    $garmin = $folder.Items() | Where-Object { $_.Name -eq 'GARMIN' } | Select-Object -First 1
    if ($garmin) { break }
    $folder = ($folder.Items() | Select-Object -First 1).GetFolder   # storage volume level, e.g. "Primary"
}
if (-not $garmin) { throw 'No GARMIN folder found on the watch' }
$apps = $garmin.GetFolder.Items() | Where-Object { $_.Name -eq 'APPS' } | Select-Object -First 1
$apps.GetFolder.CopyHere($prg, 16)
Start-Sleep -Seconds 4
Write-Host "Copied FishRegs.prg to GARMIN\APPS. Eject the watch; the app appears in the activity/app list."
