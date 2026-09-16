$ErrorActionPreference = "SilentlyContinue"
$FechaActual = Get-Date -Format "yyyyMMdd_HHmmss"

# CONFIGURACIÓN: Escaneo completo de los discos C: y P:
$RutasBuscar = @("C:\", "P:\")

# Filtros unificados: Notas, Textos, Logs, Markdown, PDFs y Word
$Filtros = @("*.txt", "*.log", "*.md", "*.pdf", "*.docx")

$CarpetaResultados = Join-Path (Get-Location) "resultados"
if (-not (Test-Path $CarpetaResultados)) { New-Item -ItemType Directory -Path $CarpetaResultados | Out-Null }

Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     SÚPER ESCANER GLOBAL: DISCOS C: Y P:        " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "[*] Analizando discos completos... Esto puede tomar tiempo." -ForegroundColor Yellow

$Resultados = @()
$Contador = 0

foreach ($Ruta in $RutasBuscar) {
    if (Test-Path $Ruta) {
        Write-Host "
[*] Iniciando análisis en unidad: $Ruta" -ForegroundColor Focus
        foreach ($Filtro in $Filtros) {
            # Búsqueda selectiva en todo el árbol de directorios del disco
            $Archivos = Get-ChildItem -Path $Ruta -Filter $Filtro -Recurse -File -Force
            
            foreach ($Archivo in $Archivos) {
                $Contador++
                # Muestra el nombre real del archivo en pantalla
                Write-Host "[+] Encontrado ($Contador): $(.Name)" -ForegroundColor Green
                
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
[-] No se encontró ningún documento con estas extensiones en C: o P:" -ForegroundColor Red
    exit
}

# Guardar los informes de la auditoría global
$Resultados | Export-Csv -Path (Join-Path $CarpetaResultados "auditoria_global_documentos_$FechaActual.csv") -NoTypeInformation -Encoding UTF8
$Resultados | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $CarpetaResultados "auditoria_global_documentos_$FechaActual.json") -Encoding UTF8

Write-Host "
==================================================" -ForegroundColor Cyan
Write-Host " [✓] ¡Súper escaneo global completado!" -ForegroundColor Green
Write-Host " Informes consolidados generados en 'resultados/'" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Cyan
