$ErrorActionPreference = "SilentlyContinue"
$FechaActual = Get-Date -Format "yyyyMMdd_HHmmss"

$RutasBuscar = @(
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads"
)

# Definimos las dos extensiones objetivo
$Filtros = @("*.vault", "*.enc")

$CarpetaResultados = Join-Path $PSScriptRoot "..\resultados"
if (-not (Test-Path $CarpetaResultados)) { New-Item -ItemType Directory -Path $CarpetaResultados | Out-Null }

Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "         ESCANEO FILTRADO: .VAULT Y .ENC          " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "[*] Buscando contenedores cifrados y vaults..." -ForegroundColor Yellow

$Resultados = @()
$Contador = 0

foreach ($Ruta in $RutasBuscar) {
    if (Test-Path $Ruta) {
        foreach ($Filtro in $Filtros) {
            # Búsqueda nativa ultra veloz por cada extensión
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
[-] No se encontró ningún archivo .vault ni .enc en las rutas especificadas." -ForegroundColor Red
    exit
}

# Guardar los nuevos informes unificados
$Resultados | Export-Csv -Path (Join-Path $CarpetaResultados "auditoria_vault_enc_$FechaActual.csv") -NoTypeInformation -Encoding UTF8
$Resultados | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $CarpetaResultados "auditoria_vault_enc_$FechaActual.json") -Encoding UTF8

Write-Host "
==================================================" -ForegroundColor Cyan
Write-Host " [✓] Escaneo unificado completado con éxito." -ForegroundColor Green
Write-Host " Informes generados en 'resultados/'" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan
