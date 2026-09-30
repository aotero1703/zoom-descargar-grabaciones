# Descargar todas las grabaciones de Zoom

Script de PowerShell que descarga automáticamente todas las grabaciones en la nube de una cuenta de Zoom (video, audio, chat, transcripciones y subtítulos) y las ordena por año y mes.

No requiere instalar nada: funciona con el PowerShell que ya trae Windows.

## Resultado

```
Descargas\zoom_grabaciones\
└── 2026\
    ├── 2026-08\
    │   └── 2026-08-12_10-00 - Reunión de equipo\
    │       ├── shared_screen_with_speaker_view_1a2b3c4d.mp4
    │       ├── audio_only_5e6f7a8b.m4a
    │       └── chat_file_9c0d1e2f.txt
    └── 2026-09\
        └── ...
```

## 1. Crear la app en Zoom (una sola vez)

1. Entra en https://marketplace.zoom.us/ → **Develop → Build App** → **Server-to-Server OAuth**.
2. **App Credentials**: copia *Account ID*, *Client ID* y *Client Secret*.
3. **Information**: completa nombre de empresa, nombre y email de contacto.
4. **Scopes**: agrega solo permisos de lectura:
   - `cloud_recording:read:list_user_recordings:admin`
   - `cloud_recording:read:recording:admin`
   - `cloud_recording:read:list_recording_files:admin`
5. **Activation** → **Activate your app**.

## 2. Configurar credenciales

Copia `zoom_credenciales.example.txt` como `zoom_credenciales.txt` y completa los valores:

```
ACCOUNT_ID=...
CLIENT_ID=...
CLIENT_SECRET=...
```

> `zoom_credenciales.txt` está en `.gitignore`: **nunca subas tus credenciales al repositorio.**

## 3. Ejecutar

```powershell
powershell -ExecutionPolicy Bypass -File .\zoom_descargar.ps1
```

O indicando otro archivo de credenciales:

```powershell
powershell -ExecutionPolicy Bypass -File .\zoom_descargar.ps1 -CredFile "C:\ruta\credenciales.txt"
```

## Características

- Recorre el historial en ventanas de 30 días (límite de la API) hasta 3 años atrás.
- Reanudable: si se interrumpe, al volver a ejecutarlo solo descarga lo que falta.
- Renueva el token automáticamente (caduca cada hora).
- Descarga a un archivo `.part` y lo renombra al terminar, para no dejar archivos corruptos.

## Configuración (dentro del script)

| Variable   | Por defecto                      | Descripción                                   |
|------------|----------------------------------|-----------------------------------------------|
| `$Usuario` | `me`                             | Email de otro usuario (si eres admin)         |
| `$Desde`   | hace 3 años                      | Fecha más antigua a revisar                   |
| `$Destino` | `Descargas\zoom_grabaciones`     | Carpeta de destino                            |
| `$Tipos`   | MP4, M4A, TRANSCRIPT, CHAT, CC   | Tipos de archivo a descargar                  |

## Limitaciones

- Solo grabaciones **en la nube**; las grabaciones locales no están en Zoom.
- Crear una app Server-to-Server OAuth requiere ser admin de la cuenta (o tener ese permiso).
