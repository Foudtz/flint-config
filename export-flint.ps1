# export-flint.ps1
# Récupère la config du Flint (secrets masqués par /root/export-config.sh),
# la place dans .\config, puis commit et push.
# Usage : .\export-flint.ps1 -Message "Lot 1 : base 25.12.6"

param(
    [string]$Message = "Export config Flint $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    [string]$Router  = "root@10.10.10.1",
    [string]$Key     = "$env:USERPROFILE\.ssh\flint_ed25519",
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

# 1. Export côté routeur
ssh -i $Key $Router "/root/export-config.sh"
if ($LASTEXITCODE -ne 0) { throw "Export sur le Flint en échec" }

# 2. Copie locale (dossier recréé pour refléter aussi les fichiers supprimés)
if (Test-Path .\config) { Remove-Item .\config -Recurse -Force }
New-Item -ItemType Directory .\config | Out-Null
scp -O -i $Key "${Router}:/tmp/cfg-export/*" .\config\
if ($LASTEXITCODE -ne 0) { throw "Copie scp en échec" }

# 3. Garde-fou : aucun secret en clair ne doit partir
$suspects = Select-String -Path .\config\* -Pattern "^\s*(option|list)\s+(key|password|private_key|preshared_key|sae_password|auth_secret)\s+'(?!REDACTED')" 
if ($suspects) {
    $suspects | ForEach-Object { Write-Warning $_.Line }
    throw "Secret non masqué détecté, commit annulé"
}

# 4. Commit et push
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host "Aucun changement." ; exit 0 }
git diff --cached --stat
git commit -m $Message
if (-not $NoPush) { git push }