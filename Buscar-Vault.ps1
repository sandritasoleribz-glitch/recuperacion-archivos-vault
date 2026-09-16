$ErrorActionPreference = "SilentlyContinue"
$FechaActual = Get-Date -Format "yyyyMMdd_HHmmss"

$RutasBuscar = @(
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads"
)

# Nuevas extensiones objetivo (Copias de WhatsApp y Comprimidos)
$Filtros = @("*.crypt14", "*.crypt15", "*.zip", "*.rar")

# Creamos la carpeta de resultados en la raíz del repositorio
$CarpetaResultados = Join-Path (Get-Location) "resultados"
if (-not (Test-Path $CarpetaResultados)) { New-Item -ItemType Directory -Path $CarpetaResultados | Out-Null }

Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     ESCANEO: COPIAS WHATSAPP Y COMPRIMIDOS       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "[*] Buscando archivos .crypt14, .crypt15, .zip y .rar..." -ForegroundColor Yellow

$Resultados = @()
$Contador = 0

foreach ($Ruta in $RutasBuscar) {
    if (Test-Path $Ruta) {
        foreach ($Filtro in $Filtros) {
            $Archivos = Get-ChildItem -Path $Ruta -Filter $Filtro -Recurse -File -Force
            
            foreach ($Archivo in $Archivos) {
                $Contador++
                Write-Host "[+] Encontrado ($Contador): $(.Name) [$Filtro]" -ForegroundColor Green
                
                $HashSHA256 = "Error"
                try {
                    $HashCrypto = Get-FileHash -Path $Archivo.FullName -Algorithm SHA256
                    $HashSHA256 = $HashCrypto.Hash
                } catch {}
                
                $Resultados += [PSCustomObject]@{
                    ID            = $Contador
                    Nombre        = $Archivo.Name
                    RutaCompleta  = $Archivo.FullName
                    TamanoMB      = [Math]::Round($Archivo.Length / 1MB, 2)
                    SHA256        = $HashSHA256
                }
            }
        }
    }
}

if ($Resultados.Count -eq 0) {
    Write-Host "
[-] No se encontró ningún archivo con estas extensiones." -ForegroundColor Red
    exit
}

# Guardar informes localmente
$Resultados | Export-Csv -Path (Join-Path $CarpetaResultados "auditoria_backups_$FechaActual.csv") -NoTypeInformation -Encoding UTF8
$Resultados | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $CarpetaResultados "auditoria_backups_$FechaActual.json") -Encoding UTF8

Write-Host "
==================================================" -ForegroundColor Cyan
Write-Host " [✓] Escaneo de backups completado con éxito." -ForegroundColor Green
Write-Host " Informes generados en la carpeta 'resultados/'" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan
