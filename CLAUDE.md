# CLAUDE.md — Contexto para Claude Code

Este fichero orienta a Claude Code sobre el proyecto y las preferencias del autor.

## El proyecto

App web de análisis de expansión de supermercados en Madrid. Vanilla JS + Leaflet + Chart.js. Sin build ni framework. Todo en un único `index.html` autocontenido más JSONs de datos en `data/`.

Version actual: v0.6

## Regla número uno

**NO INVENTAR DATOS.** Si un dato no está en los ficheros fuente, se deja en blanco o se marca como estimación explícita. Nunca fabricar ventas, m², direcciones, coordenadas ni conteos de tiendas. Los datos vienen del censo real de distribución alimentaria 2024, del Padrón CAM 2025 (INE) y del fichero de alquileres. Todo lo demás es cálculo derivado o estimación explícitamente etiquetada como tal.

## Convenciones de estilo

- **Idioma UI**: español (informal, directo)
- **Formato Excel/PPT/PDF**: si se genera algo, usar `pptxgenjs` o `python-pptx` para PPT, `openpyxl` para XLSX, `ReportLab`/`pikepdf` para PDF
- **JS**: plano, sin frameworks, sin bundler, comillas simples, comentarios en español
- **Cálculos estadísticos**: siempre **media aritmética** (AVERAGE), nunca median/mode, salvo petición explícita
- **Cambios pequeños**: preferir `str_replace` a reescrituras completas del fichero
- **Respuestas al autor**: concisas y directas. Nada de "voy a hacer X, Y y Z" antes de hacerlo — hazlo y ya está

## Datos en `data/`

| Fichero | Contenido |
|---|---|
| `m2_por_ensena.json` | m² medio calculado del censo por enseña (mercadona, lidl, dia, bm, ahorramas, carrefour, alcampo, aldi, primaprix, hiperusera, coviran, spar, simply, froiz, elcorteingles, eroski, sqrups, udaco, unide, otros) |
| `distritos.json` | 21 distritos con `nombre`, `cp[]`, `hab`, `renta`, `paro`, `alquiler_pequeño`, `alquiler_grande`, `competidores{}`, `n_establecimientos`, `m2_real` |
| `municipios.json` | 122 municipios CAM > 1.800 hab con misma estructura + `zona` (Norte/Sur/Este/Oeste/Noroeste/Suroeste/Sureste), `alq_estimado` (bool) |
| `stores_distritos.json` | Dict `{distrito: [tienda...]}` — cada tienda: `ensena`, `ensena_key`, `dom`, `calle`, `cp`, `m2`, `apertura`, `lat`, `lon`, `ventas{}` |
| `stores_municipios.json` | Igual pero por municipio |

Las claves de enseña normalizadas son: `mercadona`, `lidl`, `carrefour`, `dia`, `alcampo`, `aldi`, `ahorramas`, `elcorteingles`, `coviran`, `bm`, `primaprix`, `hiperusera`, `simply`, `spar`, `froiz`, `eroski`, `sqrups`, `udaco`, `unide`, `otros`.

## Estado del refactor

**Los datos siguen embebidos en `index.html`.** Los JSON en `data/` están extraídos pero la app aún no los carga por `fetch`. Ver sección "Refactor a datos externos" en `README.md` para migrar.

Prioridad: si vamos a añadir funcionalidad nueva importante, migrar primero a datos externos. Si son cambios menores (colores, textos, umbrales), tocar directamente el HTML es más rápido.

## Convenciones específicas de esta app

### Detección de huecos

El algoritmo actual en `detectGaps(stores)`:
- Grid 40×40 dentro del bbox P10-P90 de las tiendas
- `score = tiendas_en_500m × min(dist_tienda_más_cercana, 400m)`
- Umbrales adaptativos según densidad (Madrid centro exige ≥5 tiendas en 500m; pueblos ≥2)
- Devuelve exactamente 5 huecos

**No cambiar la firma** — el resto de la UI depende de que cada hueco tenga `{lat, lon, distanceM, radius, nearestStore, nearbyCount, addrResolved}`.

### Score de viabilidad (`calcScore`)

Devuelve `{total, hab_s, renta_s, paro_s, sat_s, ratio_s, alq_s, totalComps, m2_abiertos, habPerComp, m2PerHab, alq_grande}`. Ponderaciones actuales:
```
sat_s     × 0.28
ratio_s   × 0.18   (hab/tienda)
hab_s     × 0.18   (densidad poblacional)
alq_s     × 0.16
(100-renta_s) × 0.10   (renta inversa: rentas bajas ⇒ más necesidad de súper barato)
paro_s    × 0.10
```

Si cambian los pesos, actualizar también el bloque en el panel derecho de la app y el `README.md`.

### Colores del score

- Verde `#16a34a` para score ≥65
- Ámbar `#d97706` para 45-64
- Rojo `#dc2626` para <45

### Colores del alquiler €/m²/mes

- Verde ≤10€ (bajo)
- Ámbar 11-18€ (medio)
- Rojo >18€ (alto)

## Cosas que NO hacer

- No usar librerías pesadas (React, Vue, Angular). Se ha elegido vanilla a propósito.
- No mover a build system (webpack, vite) salvo que sea imprescindible.
- No dividir el HTML en múltiples ficheros JS hasta que sea imposible mantenerlo. Preferible mantenerlo autocontenido.
- No cambiar el idioma de la UI de español.
- No inventar coordenadas, ventas ni tiendas. Si falta un dato: se deja en blanco y se marca como faltante.

## Cosas a tener en cuenta al añadir features

- Los popups de Leaflet no aceptan CSS externo con clases custom si no se registran como class, hay que usar estilo inline
- Nominatim tiene rate limit de ~1 req/segundo — usar `addrCache` para no repetir consultas
- Los tooltips permanentes de Leaflet saturan visualmente si hay >80 marcadores — actualmente se activan solo para `stores.length <= 80`
- El HTML actual pesa ~570 KB por los datos embebidos; separarlos en JSON externos lo baja a ~40 KB

## Contexto de las ideas pendientes

Ver `README.md` sección "Ideas pendientes". Las siguientes están medio-diseñadas mentalmente:

- **Buscador por coordenadas**: input lat/lon → detecta distrito/municipio automáticamente (bbox + point-in-polygon simplificado usando el centroide de tiendas) → carga esa zona + centra el mapa en el punto exacto con marcador morado especial
- **Cálculo Huff integrado**: replicar exactamente lo que hace Unistead (peso = m²/dist^1.8, cuota = peso_mio / (peso_mio + Σ pesos competidores)). Radio de influencia 1500m, gasto per cápita 1700€/año.
- **Añadir tienda manual**: para los 8 municipios sin datos en el censo (Valdeolmos-Alalpardo, Villar del Olmo, Batres, Fresnedillas de la Oliva, Valdeavero, Navalagamella, Santos de la Humosa, Chapinería). Marcar con etiqueta `origen: "manual"` para diferenciar del censo.
