# cortar-video

Divide un video en **dos partes** en Windows, en segundos y **sin perder calidad**.
Ideal para grabaciones largas de Zoom, clases o reuniones.

## Cómo usarlo

1. Descarga [`cortar-video.bat`](cortar-video.bat) (botón **Download raw file** en GitHub).
2. **Arrastra tu video encima** del archivo (o dale doble clic y arrastra el video a la ventana).
3. Escribe el minuto de corte, por ejemplo `50:43` o `1:05:20`.
4. Escribe el nombre de cada parte, o presiona Enter para usar los nombres por defecto.

Las dos partes se guardan **en la misma carpeta que el video original**, con la misma extensión.
El original no se modifica.

```
Minuto de corte (ej. 50:43 o 1:05:20): 50:43
Nombre de la primera parte  [Enter = video_parte1]: ENARES
Nombre de la segunda parte  [Enter = video_parte2]: CLAUDE CODE

Creando "ENARES.mp4"  (inicio a 50:43)...
Creando "CLAUDE CODE.mp4"  (50:43 al final)...
Listo.
```

## Primera vez

El script usa [ffmpeg](https://ffmpeg.org/). Si no lo tienes, lo instala solo con `winget`
(viene incluido en Windows 10/11). Cuando termine, cierra la ventana y vuelve a abrir el archivo.

Si Windows muestra **"Windows protegió su PC"**, haz clic en **Más información → Ejecutar de todas formas**.

## Detalles

- **Sin recodificar** (`-c copy`): el corte tarda segundos aunque el video dure horas, y la calidad es idéntica.
- **Precisión**: como no recodifica, el corte cae en el fotograma clave más cercano, así que puede
  moverse uno o dos segundos respecto al minuto indicado.
- Funciona con `.mp4`, `.mkv`, `.mov` y otros formatos que soporte ffmpeg.

## Licencia

[MIT](../LICENSE)
