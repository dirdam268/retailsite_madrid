# CLAUDE.md — Contexto para Claude Code

Este fichero orienta a Claude Code sobre el proyecto y las preferencias del autor.

## El proyecto

App web de análisis de expansión de supermercados. Vanilla JS + Leaflet + Chart.js. Sin build ni framework. Todo en un único `index.html` autocontenido más JSONs de datos en `data/`.

Version actual: v0.7 (multi-región)

### Multi-región

`state.region` (`"madrid"` | `"pv"` | `"cb"` | `"ri"`) + `REGIONES_META`. Selector en la cabecera (`#regionSelect`, `setRegion()`). `POB_ANIO` guarda el año de la población de cada región (no todas tienen el mismo dato más reciente por sección: Madrid/PV 2025, Cantabria/La Rioja 2023) y se muestra en la tarjeta.

**Fuentes ya localizadas para lo que queda.** El XLS nacional de municipios del SEPE (`ESTADISTICA_MUNICIPIOS.xls`, una hoja `PARO <PROVINCIA>` por provincia) cubre el paro de TODAS las provincias pendientes; ya está volcado en el scratchpad para Navarra, Toledo, Ciudad Real, Segovia, Valladolid, Ávila y Guadalajara. Las tablas del INE van **por provincia** y en pares consecutivos `renta` / `demografía` (+8): Álava 30851, Bizkaia 30917, Gipuzkoa 31007, Cantabria 30953/30961, La Rioja 31169/31177, Toledo 31241/31249. Para encontrar el par de una provincia nueva: listar `TABLAS_OPERACION/353` y consultar `DATOS_TABLA/<id>?nult=1`, que devuelve el nombre de un municipio de esa provincia.

**Al añadir una región nueva, comprobar SIEMPRE (cada uno pilló un fallo real):**
1. Colisiones de nombre de municipio contra TODAS las regiones ya cargadas (las claves de `STORES_MUNI`/`MUNI_CENTERS`/`SOCIO` son el nombre).
2. Que `sum(n_establecimientos)` coincide con las filas del censo de esa región.
3. Un municipio grande a mano (Bilbao, Santander): habitantes, renta, nº de tiendas. Un desfase de columnas en el TSV se ve al instante aquí — pasó con Cantabria, que no tiene columna `provincia` y desplazaba todo un índice.
4. Que los scores de Madrid siguen idénticos (no debe cambiar ninguno).
5. Geolocalización con coordenadas reales de la región nueva.

**Nombres de municipio: el censo y la geometría INE no coinciden siempre.** `NormName` ya quita el artículo final en sus dos formas (`Astillero (El)` del censo vs `Astillero, El` de la geometría). Lo que NO resuelve son los exónimos (`Guecho`/`Getxo`), que afectan a la geolocalización — ver el respaldo por cercanía en `geolocalizarYBuscar()`.

- **Los municipios llevan `region`**; los que no la llevan se tratan como `"madrid"` (`d.region||"madrid"`), así los datos antiguos siguen valiendo sin tocarlos.
- Los datos de una región nueva se **añaden** a las estructuras existentes (`Object.assign(MUNI_CENTERS,…)`, `MUNICIPIOS.push(…)`, etc.), NO se reemplazan. Los distritos son solo de Madrid.
- Al añadir una región: comprobar **colisiones de nombre de municipio** con las que ya existen (las claves de `STORES_MUNI`/`MUNI_CENTERS`/`SOCIO` son el nombre). Madrid y País Vasco no colisionan en ninguno; verificado.
- Las claves de `SOCIO` usan `normZona()` — si se generan desde PowerShell, hay que portar esa función **exactamente** (mayúsculas, sin acentos, sin artículo inicial, texto antes de la primera coma).
- `REGIONES_META[r].tienedistritos` controla si se muestra la pestaña Distritos y la búsqueda global por calle (que está acotada a la CAM en Nominatim).

**Trampas de PowerShell al generar los datos** (todas encontradas y corregidas al montar País Vasco):
- Parsear decimales con `[double]::TryParse($s,[ref]$n)` usa la **cultura española** y destroza los números: usar siempre `InvariantCulture`.
- Los CSV del INE traen **varios indicadores por municipio** (neta/bruta, por persona/por hogar): hay que filtrar por la columna del indicador o la última fila pisa a la buena.
- Las cifras en euros del INE usan `.` como separador de **miles**, no decimal: quitar los puntos antes de parsear.
- PowerShell **desenvuelve los arrays de un elemento**: `$lista.Count` sobre una lista de 1 tienda devuelve el nº de claves del objeto. Usar `@(...)` siempre.
- Un `if` que devuelve `@()` se colapsa a `$null`, y `@($null)` es un array de un elemento nulo. Construir el array explícitamente.
- Comparar categorías con acentos entre el script y un CSV UTF-8 falla por codificación: comparar con patrones ASCII (`-like '*grado superior*'`).

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
(100-renta_s) × 0.10   (renta inversa: rentas bajas ⇒ más necesidad de súper barato; usa la renta real por persona del entorno 2 km, INE secciones 2023 — ver computeRentaEntorno / d.rentaEntorno)
paro_s    × 0.10
```

**REGLA GENERAL: un factor sin dato se excluye y su peso se reparte.** `calcScore` construye la lista `comps` de pares `[valor, peso]`, descarta los de valor `null`/`NaN` y divide por la suma de los pesos presentes. Con los 6 factores el resultado es idéntico al de siempre (verificado: los 21 distritos de Madrid no cambian ni un punto). Nunca rellenar un hueco con 0 o con un valor por defecto: un `renta:0` daría el MÁXIMO de "renta inversa" y un `paro:-1` contaminaría el score.

**Los valores centinela (-1, 0) NO deben salir de los scripts de PowerShell al JSON.** Se emiten como `$null`. Este bug llegó a publicarse con Cantabria (Tresviso salió con `paro:-1` y `renta:0`).

**Datos marcados como estimación.** `item.paro_estimado === true` (Cantabria y La Rioja) significa que la tasa de paro NO es oficial: se deriva de `parados / población 18-64` porque no existe tasa municipal vigente. La tarjeta pone "(est.)", el detalle muestra un aviso ámbar y el PDF lo dice. No es comparable con la de Madrid. Si en el futuro aparece una tasa oficial, quitar el flag.

**El SEPE censura los recuentos pequeños** escribiendo `"<5"` (privacidad). No es un número: esos municipios van con `paro:null` (74 de 174 en La Rioja) y la UI dice "Sin dato" explicando por qué.

**Si falta el alquiler** (`hasAlq(d)` falso, p.ej. País Vasco, Cantabria y La Rioja): NO se usa un valor por defecto. Se excluye `alq_s` y su 0.16 se reparte proporcionalmente entre el resto (`/(1-0.16)`), `sc.alq_s` queda `null` y `sc.sinAlq` a `true`. La UI y el PDF muestran "Sin dato". Ojo: `getAlq()` sigue teniendo un `|| 10` interno — **comprobar `hasAlq()` antes de mostrar nada al usuario**.

Si cambian los pesos, actualizar también el bloque en el panel derecho de la app (que ya distingue 6 factores / 5 factores según región) y el `README.md`.

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
