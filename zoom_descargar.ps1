# Descarga todas las grabaciones en la nube de Zoom.
# Uso: powershell -ExecutionPolicy Bypass -File .\zoom_descargar.ps1 [-CredFile ruta.txt]
param([string]$CredFile = (Join-Path $PSScriptRoot "zoom_credenciales.txt"))

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'   # acelera mucho Invoke-WebRequest

# --- Configuracion ---
# Cada linea debe contener la etiqueta (account id / client id / client secret) y el valor, en cualquier orden.
$cred = @{}
if (Test-Path $CredFile) {
    foreach ($linea in Get-Content $CredFile) {
        $clave = if ($linea -match 'account') { 'ACCOUNT_ID' } elseif ($linea -match 'secret') { 'CLIENT_SECRET' } elseif ($linea -match 'client') { 'CLIENT_ID' } else { $null }
        $valor = ($linea -replace '(?i)account[ _]?id|client[ _]?id|client[ _]?secret|[=:]', ' ').Trim()
        if ($clave -and $valor) { $cred[$clave] = $valor }
    }
}
$AccountId    = if ($cred.ACCOUNT_ID)    { $cred.ACCOUNT_ID }    else { Read-Host "Account ID" }
$ClientId     = if ($cred.CLIENT_ID)     { $cred.CLIENT_ID }     else { Read-Host "Client ID" }
$ClientSecret = if ($cred.CLIENT_SECRET) { $cred.CLIENT_SECRET } else { Read-Host "Client Secret" }
$Usuario      = "me"                                   # o el email de otro usuario (si eres admin)
$Desde        = (Get-Date).AddYears(-3).Date           # hasta donde mirar hacia atras
$Destino      = Join-Path $env:USERPROFILE "Downloads\zoom_grabaciones"
$Tipos        = @("MP4", "M4A", "TRANSCRIPT", "CHAT", "CC")

$script:Token = $null
function Get-ZoomToken {
    $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${ClientId}:${ClientSecret}"))
    $r = Invoke-RestMethod -Method Post -Headers @{ Authorization = "Basic $basic" } `
        -Uri "https://zoom.us/oauth/token?grant_type=account_credentials&account_id=$AccountId"
    $script:Token = $r.access_token
    $script:TokenHora = Get-Date
}
function Update-TokenSiHaceFalta {
    if (((Get-Date) - $script:TokenHora).TotalMinutes -gt 50) { Get-ZoomToken }
}
function Limpiar($s) {
    if (-not $s) { return "sin_titulo" }
    $s = $s -replace '[<>:"/\\|?*\x00-\x1f]', '_'
    $s = $s.Trim(' ', '.')
    if ($s.Length -gt 100) { $s = $s.Substring(0, 100) }
    return $s
}

try { Get-ZoomToken } catch { Write-Host "No se pudo obtener el token. Revisa Account ID / Client ID / Client Secret y que la app este activada." -ForegroundColor Red; exit 1 }
Write-Host "Conectado a Zoom." -ForegroundColor Green
New-Item -ItemType Directory -Force $Destino | Out-Null

$total = 0
$fin = (Get-Date).Date
while ($fin -ge $Desde) {
    $inicio = $fin.AddDays(-29); if ($inicio -lt $Desde) { $inicio = $Desde }
    $pag = ""
    do {
        Update-TokenSiHaceFalta
        $url = "https://api.zoom.us/v2/users/$Usuario/recordings?page_size=300" +
               "&from=$($inicio.ToString('yyyy-MM-dd'))&to=$($fin.ToString('yyyy-MM-dd'))&next_page_token=$pag"
        $data = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Bearer $script:Token" }
        Write-Host "Revisando $($inicio.ToString('yyyy-MM-dd')) a $($fin.ToString('yyyy-MM-dd')): $($data.meetings.Count) reuniones"

        foreach ($m in $data.meetings) {
            # Estructura: Destino\AAAA\AAAA-MM\AAAA-MM-DD_HH-mm - Tema
            $inicioReunion = [datetime]$m.start_time
            $fecha = $inicioReunion.ToString("yyyy-MM-dd_HH-mm")
            $mes = Join-Path $Destino ($inicioReunion.ToString("yyyy") + "\" + $inicioReunion.ToString("yyyy-MM"))
            $carpeta = Join-Path $mes "$fecha - $(Limpiar $m.topic)"
            foreach ($f in $m.recording_files) {
                if ($Tipos -notcontains $f.file_type -or $f.status -ne "completed") { continue }
                $ext = if ($f.file_extension) { $f.file_extension.ToLower() } else { $f.file_type.ToLower() }
                $nombre = "$(Limpiar $f.recording_type)_$($f.id.Substring(0,8)).$ext"
                $ruta = Join-Path $carpeta $nombre
                if (Test-Path $ruta) { Write-Host "  ya existe: $nombre"; continue }
                New-Item -ItemType Directory -Force $carpeta | Out-Null
                Write-Host ("  Descargando ({0:N1} MB): {1}\{2}" -f ($f.file_size / 1MB), (Split-Path $carpeta -Leaf), $nombre)
                try {
                    Update-TokenSiHaceFalta
                    Invoke-WebRequest -Uri "$($f.download_url)?access_token=$script:Token" -OutFile "$ruta.part" -UseBasicParsing
                    Move-Item "$ruta.part" $ruta -Force
                    $total++
                } catch {
                    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
                    Remove-Item "$ruta.part" -ErrorAction SilentlyContinue
                }
            }
        }
        $pag = $data.next_page_token
    } while ($pag)
    $fin = $inicio.AddDays(-1)
}

Write-Host "`nListo. $total archivos nuevos en $Destino" -ForegroundColor Green
