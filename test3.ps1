Stop-Process -processname msedge

$isOneNoteOpen = Get-Process OneNote*
Get-Process OneNote* | ForEach-Object {$_.CloseMainWindow() | Out-Null }

$pkg = get-appxpackage *Calculator*
$manifest = [xml](get-content "$($pkg.InstallLocation)/AppxManifest.xml")
$id = $manifest.Package.Applications.Application.id
if ($id.count -gt 1) {Write-Error "Found more than one app ID in package!: $id";break}
$test = Start-Process explorer.exe -ArgumentList "shell:appsfolder\$($pkg.PackageFamilyName)!$id" -PassThru


Write-Host "Test"

$stopProcessResult = $process | Stop-Process -ErrorAction SilentlyContinue -PassThru

Write-Host "Test"