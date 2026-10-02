#Requires -RunAsAdministrator
<#
  setup-dev-server.ps1
  Windows-Entwicklungsserver: Ollama (lokale GGUF-Dateien) + Open WebUI + Tailscale

  Voraussetzungen (vorher manuell installieren):
    - Ollama      (ollama.com)
    - Docker Desktop mit WSL2
    - Tailscale   (tailscale.com), angemeldet
  Aufruf (PowerShell als Administrator):
    .\setup-dev-server.ps1 -ModelDir "E:\models" -Ctx 16384
#>
param(
    [string]$ModelDir = "E:\models",   # Ordner mit deinen .gguf-Dateien
    [int]$Ctx = 16384,                 # Standard-Kontextlaenge pro Modell
    [int]$WebUiPort = 3000,
    [switch]$SkipWebUI
)

$ErrorActionPreference = "Stop"
function Step($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Warn($t) { Write-Host "WARNUNG: $t" -ForegroundColor Yellow }

# ---------------------------------------------------------------- 1. Pruefen
Step "Voraussetzungen pruefen"
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) { throw "ollama nicht gefunden. Bitte zuerst installieren." }
if (-not (Test-Path $ModelDir)) { throw "Modellordner '$ModelDir' existiert nicht." }
$hasTailscale = [bool](Get-Command tailscale -ErrorAction SilentlyContinue)
if (-not $hasTailscale) { Warn "tailscale nicht im PATH - Tailscale-Schritte werden uebersprungen." }
$hasDocker = $false
if (-not $SkipWebUI) {
    docker info *> $null
    $hasDocker = ($LASTEXITCODE -eq 0)
    if (-not $hasDocker) { Warn "Docker laeuft nicht - Open WebUI wird uebersprungen." }
}

# ------------------------------------------------- 2. Ollama-Umgebungsvariablen
Step "Ollama konfigurieren"
$envVars = @{
    OLLAMA_HOST              = "0.0.0.0:11434"
    OLLAMA_CONTEXT_LENGTH    = "$Ctx"
    OLLAMA_FLASH_ATTENTION   = "1"
    OLLAMA_KV_CACHE_TYPE     = "q8_0"
    OLLAMA_MAX_LOADED_MODELS = "1"
}
foreach ($k in $envVars.Keys) {
    [Environment]::SetEnvironmentVariable($k, $envVars[$k], "User")
    Set-Item -Path "Env:$k" -Value $envVars[$k]
}

# Ollama neu starten, damit die Variablen greifen
Get-Process -Name "ollama*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
$ollamaApp = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama app.exe"
if (Test-Path $ollamaApp) { Start-Process $ollamaApp }
else { Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden }

Write-Host "Warte auf Ollama ..."
$ok = $false
1..30 | ForEach-Object {
    if (-not $ok) {
        try { Invoke-RestMethod "http://127.0.0.1:11434/api/version" | Out-Null; $ok = $true }
        catch { Start-Sleep -Seconds 1 }
    }
}
if (-not $ok) { throw "Ollama antwortet nicht auf Port 11434." }

# ------------------------------------------------ 3. GGUF-Dateien importieren
Step "Lokale GGUF-Modelle in Ollama registrieren"

# Chat-Templates (Sonderzeichen werden per Code erzeugt, damit die Datei ASCII-only bleibt)
$bar = [char]0xFF5C; $us = [char]0x2581
$tUser   = "<${bar}User${bar}>"
$tAssist = "<${bar}Assistant${bar}>"
$tEos    = "<${bar}end${us}of${us}sentence${bar}>"

$r1Template = @'
{{- if .System }}{{ .System }}{{ end }}
{{- range $i, $_ := .Messages }}
{{- $last := eq (len (slice $.Messages $i)) 1}}
{{- if eq .Role "user" }}@USER@{{ .Content }}
{{- else if eq .Role "assistant" }}@ASSIST@{{ .Content }}{{- if not $last }}@EOS@{{- end }}
{{- end }}
{{- if and $last (ne .Role "assistant") }}@ASSIST@{{- end }}
{{- end }}
'@
$r1Template = $r1Template.Replace("@USER@", $tUser).Replace("@ASSIST@", $tAssist).Replace("@EOS@", $tEos)

$chatmlTemplate = @'
{{- range .Messages }}<|im_start|>{{ .Role }}
{{ .Content }}<|im_end|>
{{ end }}<|im_start|>assistant
'@

$existing = (ollama list) -join "`n"
$utf8 = New-Object System.Text.UTF8Encoding($false)

Get-ChildItem -Path $ModelDir -Recurse -Filter *.gguf | Where-Object { $_.Name -notmatch "mmproj" } | ForEach-Object {
    $name = ($_.BaseName.ToLower() -replace "[^a-z0-9._-]", "-")
    if ($existing -match "(?m)^$([regex]::Escape($name))(:latest)?\s") {
        Write-Host "[skip] $name existiert bereits"
        return
    }

    $lines = @("FROM `"$($_.FullName)`"", "PARAMETER num_ctx $Ctx")

    if ($_.Name -match "deepseek.*r1") {
        # R1: eigenes Template + empfohlene Temperatur
        $lines += "TEMPLATE `"`"`"$r1Template`"`"`""
        $lines += "PARAMETER stop `"$tEos`""
        $lines += "PARAMETER temperature 0.6"
    }
    elseif ($_.Name -match "qwen") {
        $lines += "TEMPLATE `"`"`"$chatmlTemplate`"`"`""
        $lines += "PARAMETER stop `"<|im_end|>`""
    }
    # alle anderen: Template aus den GGUF-Metadaten (Ollama-Standard)

    $mf = Join-Path $env:TEMP "Modelfile.$name"
    [IO.File]::WriteAllText($mf, ($lines -join "`n"), $utf8)

    Write-Host "[create] $name  <-  $($_.Name)"
    ollama create $name -f $mf
    Remove-Item $mf -Force
}

Write-Host "`nRegistrierte Modelle:"
ollama list

# --------------------------------------------- 4. Firewall (nur Tailscale-Netz)
Step "Firewall-Regel fuer Ollama (nur Tailscale 100.64.0.0/10)"
$rule = "Ollama Tailscale"
Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $rule -Direction Inbound -Protocol TCP -LocalPort 11434 `
    -RemoteAddress "100.64.0.0/10" -Action Allow | Out-Null
Warn "Pruefe in der Windows-Firewall, dass KEINE andere Regel Port 11434 fuers LAN oeffnet (z. B. die vom Ollama-Installer)."

# -------------------------------------------------------------- 5. Open WebUI
if ($hasDocker) {
    Step "Open WebUI starten (nur localhost:$WebUiPort)"
    docker rm -f open-webui *> $null
    docker run -d --name open-webui --restart always `
        -p "127.0.0.1:${WebUiPort}:8080" `
        --add-host=host.docker.internal:host-gateway `
        -e OLLAMA_BASE_URL=http://host.docker.internal:11434 `
        -v open-webui:/app/backend/data `
        ghcr.io/open-webui/open-webui:main
}

# --------------------------------------------------------------- 6. Tailscale
$dns = $null
if ($hasTailscale) {
    Step "Tailscale"
    try {
        $dns = ((tailscale status --json | ConvertFrom-Json).Self.DNSName).TrimEnd(".")
    } catch { Warn "Konnte Tailscale-Hostnamen nicht lesen (angemeldet?)." }

    if ($hasDocker) {
        tailscale serve --bg $WebUiPort    # NICHT 'funnel' verwenden (waere oeffentlich)
        tailscale serve status
    }
}

# ------------------------------------------------------------- 7. Zusammenfassung
Step "Fertig"
if ($dns) {
    Write-Host "Open WebUI (Tailnet):  https://$dns"
    Write-Host "Ollama-API (Tailnet):  http://${dns}:11434   (z. B. fuer Continue in VS Code)"
} else {
    Write-Host "Open WebUI (lokal):    http://localhost:$WebUiPort"
    Write-Host "Ollama-API (lokal):    http://localhost:11434"
}
Write-Host @"

Naechste Schritte:
  1. Open WebUI oeffnen, Admin-Konto anlegen, danach in den Admin-Einstellungen
     die Selbstregistrierung abschalten.
  2. Test: ollama run <modellname>   und   ollama ps  (Spalte Processor sollte 100% GPU zeigen)
  3. In Continue (VS Code) apiBase auf die Ollama-API-URL oben setzen,
     model = Name aus 'ollama list'.
"@
