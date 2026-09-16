# 1. Buscar la carpeta Media de WhatsApp
$carpetaMedia = Get-ChildItem -Path "C:\Users\sandr\Desktop\Carpeta DIGI storage\" -Directory -Filter "Media" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($carpetaMedia) {
    $destinoMedia = "$Home\Desktop\Recuperacion_WhatsApp\Media"
    New-Item -ItemType Directory -Force -Path $destinoMedia | Out-Null
    
    # Obtener archivos multimedia
    $archivosMedia = Get-ChildItem -Path $carpetaMedia.FullName -Recurse -File -ErrorAction SilentlyContinue
    $totalMedia = $archivosMedia.Count
    $j = 0
    
    foreach ($archivo in $archivosMedia) {
        $j++
        $porcentaje = [Math]::Round(($j / $totalMedia) * 100)
        Write-Progress -Activity "Copiando Fotos y Videos de WhatsApp" -Status "Archivo $j de $totalMedia : $($archivo.Name)" -PercentComplete $porcentaje
        
        $rutaRelativa = $archivo.FullName.Substring($carpetaMedia.FullName.Length)
        $rutaDestinoFinal = Join-Path $destinoMedia $rutaRelativa
        $null = New-Item -ItemType File -Path $rutaDestinoFinal -Force
        
        Copy-Item -Path $archivo.FullName -Destination $rutaDestinoFinal -Force
    }
    Write-Host "¡Fotos y videos copiados con éxito!" -ForegroundColor Green
} else {
    Write-Host "No se encontró ninguna carpeta 'Media' en la ruta especificada." -ForegroundColor Red
}

