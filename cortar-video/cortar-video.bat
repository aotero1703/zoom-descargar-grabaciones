@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Cortar video en dos partes

echo ================================================
echo   CORTAR VIDEO EN DOS PARTES  (sin perder calidad)
echo ================================================
echo.

rem --- 1. Verificar que ffmpeg esta instalado -------------------------------
where ffmpeg >nul 2>nul
if errorlevel 1 goto :instalar_ffmpeg

rem --- 2. Obtener el video (arrastrado sobre el .bat o escrito) -------------
set "VIDEO=%~1"
if defined VIDEO goto :tengo_video
echo Consejo: tambien puedes arrastrar el video encima de este archivo.
echo.
set /p "VIDEO=Arrastra aqui el video y presiona Enter: "
set "VIDEO=%VIDEO:"=%"

:tengo_video
if not exist "%VIDEO%" (
  echo.
  echo [ERROR] No encuentro el archivo: "%VIDEO%"
  goto :fin
)
for %%F in ("%VIDEO%") do (
  set "CARPETA=%%~dpF"
  set "EXT=%%~xF"
  set "BASE=%%~nF"
)
echo Video: %VIDEO%
echo.

rem --- 3. Pedir minuto de corte y nombres -----------------------------------
:pedir_corte
set "CORTE="
set /p "CORTE=Minuto de corte (ej. 50:43 o 1:05:20): "
if not defined CORTE goto :pedir_corte

set "PARTE1="
set /p "PARTE1=Nombre de la primera parte  [Enter = %BASE%_parte1]: "
if not defined PARTE1 set "PARTE1=%BASE%_parte1"

set "PARTE2="
set /p "PARTE2=Nombre de la segunda parte  [Enter = %BASE%_parte2]: "
if not defined PARTE2 set "PARTE2=%BASE%_parte2"

set "SALIDA1=%CARPETA%%PARTE1%%EXT%"
set "SALIDA2=%CARPETA%%PARTE2%%EXT%"

rem --- 4. Cortar -------------------------------------------------------------
echo.
echo Creando "%PARTE1%%EXT%"  (inicio a %CORTE%)...
ffmpeg -hide_banner -loglevel error -y -i "%VIDEO%" -t %CORTE% -map 0 -c copy "%SALIDA1%"
if errorlevel 1 goto :error_ffmpeg

echo Creando "%PARTE2%%EXT%"  (%CORTE% al final)...
ffmpeg -hide_banner -loglevel error -y -ss %CORTE% -i "%VIDEO%" -map 0 -c copy -avoid_negative_ts make_zero "%SALIDA2%"
if errorlevel 1 goto :error_ffmpeg

echo.
echo Listo. Los dos videos estan en:
echo   %CARPETA%
goto :fin

rem --- Subrutinas ------------------------------------------------------------
:instalar_ffmpeg
echo No se encontro ffmpeg. Instalandolo con winget (solo la primera vez)...
echo.
winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
echo.
echo Instalacion terminada. Cierra esta ventana y vuelve a abrir el archivo.
goto :fin

:error_ffmpeg
echo.
echo [ERROR] ffmpeg no pudo cortar el video. Revisa que el minuto este bien
echo         escrito (ej. 50:43) y que el video no este abierto en otro programa.
goto :fin

:fin
echo.
pause
endlocal
