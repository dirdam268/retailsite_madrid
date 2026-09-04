# CLAUDE.md — Contexto para Claude Code

Este fichero orienta a Claude Code sobre el proyecto y las preferencias del autor.

## El proyecto

App web de análisis de expansión de supermercados. Vanilla JS + Leaflet + Chart.js. Sin build ni framework. Todo en un único `index.html` autocontenido más JSONs de datos en `data/`.

Version actual: v0.7 (multi-región)

### Multi-región

`state.region` (`"madrid"` | `"pv"` | `"cb"` | `"ri"` | `"nc"`) + `REGIONES_META`. Selector en la cabecera (`#regionSelect`, `setRegion()`).

**`REGIONES_META` es la ficha de cada región y la UI lee de ahí** (`regMeta()`): `label`, `tienedistritos`, `pobAnio`, `grupo`, `fuentePob`, `fuenteRenta`, `fuenteParo`, `listaFuentes` y `avisos`. Al añadir una región solo hay que rellenar su ficha — **no** encadenar más `state.region==="xx" ? … : …` por la UI (así estaba y se volvió ilegible con 3 regiones). Las 7 provincias sueltas se generan en un bucle al final del objeto, porque comparten estructura de fuentes.

**El selector es un `<select>` agrupado por `grupo`** (`renderRegionSelect()`), no botones: con 12 zonas no caben, menos en móvil. Las provincias van bajo "«Comunidad» — solo estas provincias" para no dar a entender que está la comunidad entera. `setRegion()` sincroniza el `value` porque también se llama desde la geolocalización.

**Municipios HOMÓNIMOS entre provincias: hay que desambiguarlos** con la provincia entre paréntesis, porque `MUNI_CENTERS` / `STORES_MUNI` / `SOCIO` se indexan por NOMBRE y uno machacaría al otro. Ya resueltos: Villanueva de los Infantes (CR/VA), Serrada (AV/VA), Sotillo (GU/SG). **Paréntesis, nunca coma**: `normZona()` corta en la primera coma, así que "Serrada, La (Ávila)" seguiría colapsando a "SERRADA". Hay que quitar el artículo final ANTES de añadir la provincia. Comprobar siempre las colisiones de nombre Y las de clave `normZona` (que son distintas: "Serrada" y "Serrada, La" son nombres distintos pero misma clave).

**La geolocalización tiene tres trampas ya resueltas, no las reintroduzcas** (`geolocalizarYBuscar()`):
1. Nominatim devuelve varios campos a la vez (`village:"Monte"` + `city:"Santander"`): se prueban todos y gana el primero que sea un municipio real.
2. Los nombres bilingües oficiales llevan barra (`Pamplona/Iruña`) y Nominatim manda solo una mitad: 2ª pasada comparando contra cada mitad. 89 municipios la necesitan; comprobado que ninguna mitad choca con el nombre completo de otro municipio.
3. **Un distrito solo vale si la ciudad es Madrid.** "Centro", "Salamanca" o "Retiro" son barrios comunes: Donostia devuelve `suburb:"Centro"` y seleccionaba el distrito Centro de MADRID.
   Y como último recurso, si nada casa por nombre (exónimos tipo `Guecho`/`Getxo`), respaldo por cercanía al centro del municipio (máx 12 km) avisando de que es aproximado.

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

**EL CRITERIO DEL NEGOCIO ES: mucha gente, con dinero, y pocos competidores.** No es un súper de descuento. Ponderaciones actuales:
```
sat_s     × 0.28   (mercado libre: menos m²/hab = mejor)
renta_s   × 0.25   (DIRECTA: más renta = mejor. Usa la renta real por persona del
                    entorno 2 km, INE secciones 2023 — ver computeRentaEntorno)
hab_s     × 0.22   (densidad poblacional)
ratio_s   × 0.20   (hab/tienda)
paro_s    × 0.05   (INVERTIDO: menos paro = mejor, es poder adquisitivo)
```

**Dos direcciones que estuvieron mal y NO hay que revertir** (ago-2026, corregido a petición del usuario):
- La renta iba **invertida** (rentas bajas puntuaban más). Premiaba los barrios pobres y hundía los ricos: Barrio de Salamanca era el PEOR distrito de Madrid con 18. Ahora va directa.
- El paro sumaba en positivo (más paro = mejor). Ahora va invertido.
- **El alquiler ya NO puntúa** (pesaba 0.16). Textualmente: *"que sea caro será un problema mío para buscar alquileres, solo me das la info, no lo discrimines"*. `alq_s` se sigue calculando y mostrando como información, pero no entra en `comps`.

**MASA CRÍTICA: `MIN_HAB_MUNICIPIO = 3000`, `state.soloMasaCritica` activo por defecto.** Sin este filtro el ranking lo copaban aldeas (46 de los 50 primeros con <3.000 hab): un pueblo de 160 personas sin ninguna tienda marca `sat_s = 100` ("100% mercado libre") cuando lo que pasa es que no hay mercado. **El 3.000 no es inventado: es el umbral que fijan los propios criterios de expansión para un municipio** (el mismo que usa el hueco especial). Es un interruptor visible y reversible bajo los filtros, no un cambio oculto en el score.

**REGLA GENERAL: un factor sin dato se excluye y su peso se reparte.** `calcScore` construye la lista `comps` de pares `[valor, peso]`, descarta los de valor `null`/`NaN` y divide por la suma de los pesos presentes. Nunca rellenar un hueco con 0 o con un valor por defecto: un `paro:-1` contaminaría el score.

**Los valores centinela (-1, 0) NO deben salir de los scripts de PowerShell al JSON.** Se emiten como `$null`. Este bug llegó a publicarse con Cantabria (Tresviso salió con `paro:-1` y `renta:0`).

**Consecuencia del punto anterior: `item.renta` puede ser `null`** (14 municipios; el INE no publica renta en los muy pequeños). Seleccionar uno reventaba el panel con `Cannot read properties of null (reading 'toLocaleString')` — la ficha, el modal de la métrica y el PDF lo tratan ya como "Sin dato". Al tocar cualquier plantilla nueva, guardar igual que con `item.paro`.

**Datos marcados como estimación.** `item.paro_estimado === true` (Cantabria y La Rioja) significa que la tasa de paro NO es oficial: se deriva de `parados / población 18-64` porque no existe tasa municipal vigente. La tarjeta pone "(est.)", el detalle muestra un aviso ámbar y el PDF lo dice. No es comparable con la de Madrid. Si en el futuro aparece una tasa oficial, quitar el flag.

**El SEPE censura los recuentos pequeños** escribiendo `"<5"` (privacidad). No es un número: esos municipios van con `paro:null` (74 de 174 en La Rioja) y la UI dice "Sin dato" explicando por qué.

**En las provincias con código INE < 10 (Ávila = 05) Excel se come el cero inicial** del código municipal en el XLS del SEPE: llega `"5001"` en vez de `"05001"`. Hay que rellenar a 5 dígitos o esa provincia se queda entera sin paro (pasó, y se detectó porque salieron 248 municipios sin dato y 0 censurados — un patrón imposible).

**POBLACIÓN ALREDEDOR DE UN PUNTO: reparto por área, nunca la sección entera.** Solo tenemos el centroide de cada sección censal. Sumar la sección completa porque su centroide cae dentro del radio funciona en ciudad (sección de 120-170 m) pero MIENTE en el campo (secciones de km). `radioSecciones()` calcula una vez el tamaño real de cada sección = mitad de la distancia a la sección vecina más próxima (índice por celdas de 0,02°, ~430 ms) y lo guarda **en `se[4]`** — no en un array aparte, porque los bucles usan copias filtradas y se perdería el índice. `fraccionDentro(d, rs, r)` da el solape de dos círculos. Lo usan `evalHuecoEspecial` y `detectGaps`; **llamar a `radioSecciones()` antes de leer `se[4]`**.

**El hueco tiene que estar DONDE VIVE LA GENTE, no solo cerca.** Un punto en el monte de El Escorial cumplía "3.400 hab a 3 min" con CERO vecinos a 300 m. Se exige `p500 >= 3000 × (500/r3)²` — el propio criterio de población repartido por igual: **333 en municipio, 926 en distrito**. No es un número inventado.

**Urbano/Rural lo decide la DENSIDAD del punto (`esTramaUrbana`), no `isDistrito`.** Los criterios distinguen Urbano (radios 900/1.600) de Rural (1.500/2.600). Traducirlo como "distrito de Madrid = urbano" valía con la app solo-Madrid, pero metía a Bilbao (348k) y Fuenlabrada (190k) en el saco rural: un círculo de 2.600 m en ciudad densa abarca 143.000 personas y 40 súpers, y hace IMPOSIBLE cumplir los topes de competencia. Corte en `DENSIDAD_URBANA = 3000` hab/km² medidos a 1 km del punto (datos: pueblos 14-200, distritos Madrid 7.000-10.000, ciudades 17.000-28.000). **Solo cambian los RADIOS**; los umbrales de población de zona (barrio ≥20.000 / pueblo ≥3.000) siguen atados a `isDistrito`, que es propiedad de la unidad administrativa. Desbloqueó Alcobendas y Leganés, antes excluidas estructuralmente.

**Hay TRES sitios que generan huecos y los tres necesitan la comprobación** (se me escapó uno en el primer intento y la auditoría lo destapó):
1. `evalHuecoEspecial` — hueco especial.
2. `detectGaps`, bucle de candidatos — huecos verdes normales.
3. `detectGaps`, **rama de `stores.length < 6`** — colocaba 2 puntos por GEOMETRÍA pura alrededor del centroide, sin mirar población. Salían huecos a 2 km del pueblo con cero residentes (Villalbilla, Colmenar de Oreja) aunque fueran `lowConfidence`.

Cuidado también con la guarda: la primera versión eximía el caso `densZona === 0`, y por ahí colaba un hueco en Oñati con **cero habitantes** en todo el radio. Auditoría final: 0 de 1.074 huecos verdes y 0 de 25 especiales en descampado.

**El umbral de 333 no bastaba en la rama de `<6` tiendas: hay que ELEGIR el punto por población, no filtrarlo.** En Villanueva del Pardillo uno de los dos ángulos fijos caía en un prado y aun así pasaba (613 vecinos a 500 m) porque la sección censal que lo cubre mezcla casco y campo, así que el disco uniforme le "presta" la densidad del pueblo. Ahora la rama barre **16 ángulos × 4 radios (300/450/600/800 m)**, descarta los que estén a <150 m de una tienda o bajo el umbral, ordena por población a 500 m y se queda con los 2 mejores separados ≥400 m entre sí. Resultado en Villanueva: 1.578 y 1.127 vecinos, ambos dentro del casco. Auditoría de la rama: 343 huecos en 716 municipios de <6 tiendas, mínimo 335 vecinos a 500 m (Mendaro); 535 municipios se quedan **sin ningún hueco**, que es la respuesta honesta cuando no hay sitio con gente suficiente.

### Los TRES tipos de hueco

| | Color | Cuándo sale | Qué mira |
|---|---|---|---|
| **Huecos** | verde | siempre (hasta 5 por zona) | mejor hueco relativo dentro de la zona |
| **Hueco especial** | negro | solo si cumple los criterios de expansión | gente **y** poca competencia a 3 y 5 min |
| **Hueco Henry** | morado | solo en ciudad densa sin competencia a la vuelta de la manzana | 500 m alrededor del punto |

**El hueco Henry (ago-2026, pedido por el usuario a partir del caso de Fuenlabrada).** El hueco especial es **estructuralmente imposible** en una ciudad grande: exige poquísima competencia en 1.600-2.600 m y ahí siempre hay 20 súpers. Pero Fuenlabrada tenía un punto con miles de vecinos y **cero metros de súper a 500 m**. Eso es el Henry: `evalHuecoHenry` exige (a) `esTramaUrbana` — en un pueblo "sin tiendas a 500 m" es lo normal y no dice nada; (b) **0 m² de competencia** en 500 m; (c) ≥120 m a la tienda más cercana; (d) **≥7.000 vecinos a 500 m** y **≥2.000 a 250 m**.

Las dos constantes de población están calibradas, no inventadas: 7.000 es el propio caso de Fuenlabrada (7.677) y deja la señal en **34 de las 906 zonas con tiendas (4%)** — con 4.000 saltaba en 79, incluidos 20 de los 21 distritos de Madrid, y una etiqueta que se lleva todo el mundo no informa de nada. El **mínimo a 250 m** es lo que impide que el marcador se pegue al borde del casco: a 500 m basta con que la mitad del círculo esté poblada, y así el punto acababa mirando al campo.

`detectHuecoHenry(stores, isDistrito)` se monta su propio bbox (margen 1.200 m) y usa `getAllStores()`, para que cuente la competencia del municipio o distrito de al lado. Rejilla 29×29, máximo `maxFromZone` (800 m distrito / 1.600 m municipio) de una tienda de la zona para no salirse de la huella urbana.

**La recomendación ejecutiva se pinta ANTES que el mapa.** `renderCenter` llama a `generateRecommendation` y solo después lanza `renderMap` (con `setTimeout`), que es quien calcula `currentSpecialGap` y `currentHenryGap`. Por eso `renderMap` **reescribe `#recomBox`** al terminar. Sin eso la nota del Henry (y la del hueco especial) usa los valores de la zona ANTERIOR.

**Geolocalización: Nominatim a `zoom: 16`, NO 14.** A 14 devuelve a veces un pueblo VECINO: en el centro de Sevilla la Nueva contestaba "Navalagamella", a 13 km, y como Navalagamella existe en nuestros datos el match exacto la daba por buena (el respaldo por cercanía ni se activaba). Comprobado que a 16 acierta el municipio Y sigue dando el distrito en Madrid capital, que era lo único para lo que hacía falta el 14. Zoom 12 y 13 también fallan.

**Ranking de huecos (los dos tipos).** `escanearHuecosEspeciales()` y `escanearHuecosHenry()` recorren distritos + municipios y cachean en `_rankingHuecos` / `_rankingHenry` (datos estáticos). `filasRanking()` los une añadiendo `tipo` y, sobre todo, `pobRef`/`pobRefLbl`: **las dos cifras NO son la misma medida** (el especial cuenta gente a 3 min, el Henry vecinos a 500 m), así que la columna lleva su propia etiqueta y el modo "los dos" avisa de que el orden mezclado es orientativo. No unificarlas en una sola columna sin etiqueta. `abrirRankingHuecos()` pinta el progreso en dos fases y cede el hilo con `setTimeout` entre ellas; sin esa cesión el modal sale en blanco. `detectSpecialGap` acepta un 3er parámetro `habOverride` **obligatorio para el barrido**: sin él usaría `state.selected.hab`, que no es el municipio que se está evaluando. El Henry solo se busca en zonas CON tiendas: una zona sin ninguna ya la recoge el especial, que es justo su caso.

**El barrido tardaba 1:50 y el README decía "~5 s": esa cifra era de la época solo-Madrid y nunca se volvió a medir.** Con 12 regiones (2.559 municipios, 10.532 secciones) el coste real era 73 s el especial + 36 s el Henry. Tres cambios, todos verificados **sin alterar ni un resultado** (28 especiales y 35 Henry antes y después, mismas cifras en las primeras filas):
1. **Descarte barato antes del haversine.** El coste no es recorrer la lista, es la trigonometría. `ventana(lat, r)` da el margen en grados y dos restas descartan la inmensa mayoría. Al filtrar SECCIONES hay que sumar `SEC_R_MAX` (3.000 m): una sección de 3 km de radio aporta población aunque su centroide esté lejos del borde del círculo — con menos margen los resultados CAMBIAN en el campo.
2. **Banda por fila.** Los 25 puntos de una fila de la rejilla comparten latitud, así que la banda de secciones y tiendas que les puede afectar se calcula una vez por fila, no 25 veces.
3. **Un solo recorrido de secciones por punto.** `evalHuecoEspecial` calculaba el haversine tres veces contra las mismas secciones (trama urbana a 1 km, zonas de 3/5 min, vecinos a 500 m). Ahora se calculan las distancias una vez en `cerca[]`/`dist[]` y se reutilizan; por eso la comprobación de trama urbana está *inline* ahí y `esTramaUrbana()` queda solo para el Henry.

Queda en ~21 s + 8 s, cacheado. **Un índice espacial por celdas fue un callejón sin salida**: reasignaba un array por cada punto de la rejilla y salía más lento que el filtro que pretendía sustituir.

Para los municipios sin tienda (1.691, un punto cada uno) se usa `seccionesBanda`/`tiendasBanda`, que hacen búsqueda binaria sobre copias ordenadas por latitud (`_secOrd`/`_stoOrd`) en vez de recorrer las listas enteras.

**El índice y el hueco especial responden a preguntas distintas y hay que decirlo.** 39 de las 45 zonas con hueco puntúan BAJO: el índice valora el municipio entero como mercado (renta alta y alquiler caro lo hunden), el hueco valora un punto concreto. Cuando `sc.total < 45 && currentSpecialGap`, el detalle añade el aviso "⭐ Matiz importante". No quitar ese aviso: sin él el informe se lee como una contradicción.

**Ventas: JERARQUÍA de tres niveles, en `mergeVentasEstimadas()`.** Nunca se pisa un escalón superior:
1. `s.ventas` — venta REAL del censo (verde).
2. `s.ventasNiel` — cifra del panel Nielsen **para esa tienda** (azul). Lookup `VENTAS_NIELSEN` `"lat,lon"` → €/año, de `scratchpad/build_nielsen_match.ps1`: cruce por **CP + calle normalizada sin el tipo de vía**; si varias comparten clave, desempate por cadena y luego por m² más parecido.
3. `s.ventasEst` — estimación por comparables (ámbar). Lookup `VENTAS_EST` `"lat,lon"` → `[€/año, nº comparables]`, de `build_nielsen_est.ps1`.

Reglas que NO se pueden romper: ni el azul ni el ámbar entran en `totalSales`, ni en el benchmark de zona, ni en la canibalización — esos filtran por `s.ventas`. Al añadir regiones hay que regenerar ambos lookups (necesitan CP, dirección, categoría y m² del censo; Madrid sale de `DATA.madrid` de la otra app).

**El cruce por m² NO funciona** (4 coincidencias de 3.575): Nielsen mide sala de ventas y el censo superficie total. Hay que cruzar por CP+calle.

**El fichero "Datos Nielsen.xlsx" tiene mucho más que lo que extrae la otra app** (que solo lee superficie, tipo y €/m²): 28 columnas con código, cadena, rótulo, dirección, CP, provincia, municipio, **código INE**, m², tipo, apertura y ventas por familia de producto. Columnas útiles: A=código, D=rótulo, F=dirección, J=CP, N=municipio, Q=COD_INE, R=superficie, S=tipo, Z=Vta Alim. (anual), AA=€/m².

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
