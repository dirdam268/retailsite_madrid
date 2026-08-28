# RetailSite

Herramienta web para análisis de expansión de supermercados. Cruza el censo real de distribución alimentaria con datos socioeconómicos y detecta huecos de mercado con validación urbana.

## Regiones cubiertas

Selector de región en la cabecera:

| Región | Zonas | Tiendas del censo | Alquiler |
|---|---|---|---|
| **Comunidad de Madrid** | 21 distritos + 122 municipios | 2.331 | ✅ precios reales 2024 |
| **País Vasco** | 251 municipios (Álava, Bizkaia, Gipuzkoa) | 1.079 | ❌ sin datos todavía |
| **Cantabria** | 102 municipios | 407 | ❌ sin datos todavía |
| **La Rioja** | 174 municipios | 171 | ❌ sin datos todavía |
| **Navarra** | 272 municipios | 419 | ❌ sin datos todavía |
| **Ávila** (provincia) | 248 municipios | 107 | ❌ |
| **Salamanca** (provincia) | 362 municipios | 178 | ❌ |
| **Segovia** (provincia) | 209 municipios | 98 | ❌ |
| **Valladolid** (provincia) | 225 municipios | 281 | ❌ |
| **Ciudad Real** (provincia) | 102 municipios | 281 | ❌ |
| **Guadalajara** (provincia) | 288 municipios | 123 | ❌ |
| **Toledo** (provincia) | 204 municipios | 428 | ❌ |

**Total: 2.559 municipios (+ 21 distritos de Madrid) y 10.532 secciones censales.**

Las siete últimas son **provincias sueltas, no comunidades enteras**. En el selector aparecen agrupadas bajo "Castilla y León — solo estas provincias" y "Castilla-La Mancha — solo estas provincias" para que quede claro. Se filtraron por los dos primeros dígitos del código INE dentro de la geometría de cada comunidad; el número de municipios coincide exactamente con el de la tabla de renta del INE en las siete.

**Fuentes de las 7 provincias** (idénticas en todas): censo 2024; población, % 65+ y % <18 del INE (Atlas, **una tabla de demografía por provincia**, 2023); renta por persona y por hogar (Atlas ADRH, **una tabla por provincia**, 2023); paro registrado del SEPE (enero 2026); estudios del Censo INE 2021-2024. Tablas del INE (renta/demografía): Ávila `30869`/`30877`, Ciudad Real `30971`/`30979`, Guadalajara `31034`/`31042`, Salamanca `31178`/`31186`, Segovia `31196`/`31204`, Toledo `31241`/`31249`, Valladolid `31259`/`31267`.

## Ventas de las tiendas: tres niveles

El censo trae ventas **solo para 862 de las 5.908 tiendas** (15%), y de vintages muy distintos (DIA 2011-2012, Carrefour 2018/2019, Supercor feb-2021, Eroski mensual). El resto se rellena con el fichero **"Datos Nielsen"** (24.971 tiendas con rótulo, dirección, CP, código INE, m² y venta anual de alimentación), en dos escalones:

| | Qué es | Tiendas |
|---|---|---|
| 🟢 **Verde** | Venta **real** del censo, con su año | 862 |
| 🔵 **Azul 📊** | Cifra del **panel Nielsen para esa tienda**, cruzada por CP + calle normalizada | 1.798 |
| 🟠 **Ámbar "est."** | **Estimación**: media del €/m² de tiendas Nielsen de igual categoría, mismo carácter (capital o no) y m² ±15% | 2.634 |

Cobertura total: **90%**. Las 614 restantes son cash & carry (categoría que Nielsen no cubre) o tamaños sin comparables.

**Nunca se pisa un escalón superior**, verificado: 0 tiendas tienen más de uno. Ni el azul ni el ámbar entran en el recuento de tiendas con ventas, ni en el benchmark de la zona, ni en la canibalización — esos siguen filtrando por venta real.

**Cruce directo (azul)**: por CP + calle sin el tipo de vía; si varias tiendas Nielsen comparten esa clave se desempata por cadena y luego por m² más parecido. Contrastado contra las ventas reales del censo:

| Cadena | n | Mediana Nielsen/real | Dentro de un factor 2 |
|---|---|---|---|
| DIA | 147 | 1,10× | 79% |
| Carrefour | 22 | 1,16× | 73% |
| Mercadona | 20 | 1,22× | 80% |

El sesgo al alza de ~×1,1-1,2 es coherente con que Nielsen sea actual y las del censo de 2011-2019, no con un error de cruce.

**Estimación por comparables (ámbar)**, contrastada contra 457 tiendas de Madrid con venta real: mediana **0,85×**, 71% dentro de un factor 2 (82% entre 400 y 999 m², 72% por debajo de 400, 53% entre 1.000 y 2.499). En hipermercados no hay contraste fiable: las 5 cifras "reales" disponibles son implausibles (1,9 M€/año para 12.000 m²), así que ahí el dato sospechoso es la referencia.

Ambos van precalculados (`VENTAS_NIELSEN` 62 KB, `VENTAS_EST` 177 KB) con `scratchpad/build_nielsen_match.ps1` y `build_nielsen_est.ps1`, en vez de embeber las 24.971 filas del fichero.

**Municipios homónimos.** La app indexa por nombre, así que tres pares que se repetían llevan la provincia entre paréntesis: **Villanueva de los Infantes** (Ciudad Real / Valladolid), **Serrada** (Ávila / Valladolid) y **Sotillo** (Guadalajara / Segovia).

**Navarra — fuentes:**
- Tiendas: Censo de Distribución Alimentaria 2024 (420 filas → 419 tiendas; 1 descartada porque el censo no trae coordenadas).
- Geometría: secciones censales INE 2019 (562 secciones).
- Población, % de 65+ y % menor de 18: INE, Atlas, tabla `31132`, **año 2023**.
- Renta 2023 (por persona y por hogar): INE Atlas ADRH, tabla `31124`.
- Paro registrado por municipio: SEPE, XLS nacional de municipios, **enero 2026**.
- % estudios superiores: Censo INE 2021-2024, tabla `66621` (120 de 272 municipios).

**Limitaciones honestas de Navarra:** tasa de paro estimada (igual que Cantabria y La Rioja), **64 municipios sin paro publicado** (el SEPE censura los recuentos pequeños), población de 2023 y sin datos de alquiler.

**La Rioja — fuentes:**
- Tiendas: Censo de Distribución Alimentaria 2024 (171, todas asignadas).
- Geometría: secciones censales INE 2019 (343 secciones).
- Población, % de 65+ y % menor de 18: INE, Atlas, tabla `31177`, **año 2023**.
- Renta 2023 (por persona y por hogar): INE Atlas ADRH, tabla `31169`.
- Paro registrado por municipio: SEPE, XLS nacional de municipios, **enero 2026**.
- % estudios superiores: Censo INE 2021-2024, tabla `66621` (41 de 174 municipios: la tabla solo cubre municipios de ≥500 hab y La Rioja tiene muchos pueblos pequeños).

**Limitaciones honestas de La Rioja:**
- **La tasa de paro es una estimación propia**, igual que en Cantabria (`parados / población 18-64`). Marcada con "(est.)" y con aviso en el detalle. No comparable con Madrid.
- **74 de los 174 municipios no tienen tasa de paro en absoluto**: el SEPE sustituye los recuentos pequeños por "&lt;5" para no permitir identificar personas. No se inventa un número — esos municipios muestran "Sin dato" y el índice se calcula sin ese factor.
- Población de 2023 y sin datos de alquiler, como Cantabria.

**Cantabria — fuentes:**
- Tiendas: Censo de Distribución Alimentaria 2024 (407, todas asignadas a municipio).
- Geometría y centroides: secciones censales INE 2019 (467 secciones).
- Población, % de 65+ y % menor de 18: INE, Atlas, tabla `30961`, **año 2023**.
- Renta 2023 (por persona y por hogar): INE Atlas ADRH, tabla `30953`.
- Paro registrado por municipio: ICANE/SEPE, julio 2026.
- % estudios superiores: Censo INE 2021-2024, tabla `66621` (84 de 102 municipios).

**Limitaciones honestas de Cantabria:**
- **La tasa de paro es una estimación propia, no un dato oficial.** No existe tasa de paro municipal vigente para Cantabria: ICANE dejó de calcularla en 2012, y SEPE e INE solo publican el *número* de parados. Se deriva como `parados registrados / población 18-64` y se marca en la app con "(est.)" más un aviso en el detalle. **No es comparable con la de Madrid**, que usa otra definición — sirve para comparar municipios *dentro* de Cantabria.
- **La población es de 2023**, no de 2025 como Madrid y País Vasco: es el dato más reciente disponible por sección censal para esta región.
- Sin datos de alquiler, igual que en País Vasco (el índice se calcula sin ese factor).
- Tresviso (5 hab) y Pesquera (70 hab) no tienen renta: el INE la suprime en municipios tan pequeños.

**País Vasco — fuentes (todas reales, ninguna inventada):**
- Tiendas: Censo de Distribución Alimentaria 2024 (filtrado a País Vasco: 1.081 filas, 1.079 asignadas a municipio; 2 descartadas porque el propio censo no trae municipio).
- Geometría y centroides: secciones censales INE 2019 (1.711 secciones).
- Población por sección censal a 01/01/2025: Diputaciones Forales de Álava, Bizkaia y Gipuzkoa.
- Renta 2023 (por persona y por hogar): INE Atlas de Distribución de Renta de los Hogares — **una tabla por provincia**: Álava `30851`, Bizkaia `30917`, Gipuzkoa `31007`.
- Paro registrado municipal (dic-2025): Lanbide / Open Data Euskadi.
- % estudios superiores: Censo INE 2021-2024, tabla `66621` (solo municipios ≥500 hab → 189 de 251 tienen dato; el resto queda vacío, no se rellena).

**Limitaciones honestas del País Vasco:**
- **Sin datos de alquiler.** No se inventa ningún valor: el índice orientativo se calcula **sin ese componente** y su 16% se reparte proporcionalmente entre los otros 5 factores. Las tarjetas y el PDF muestran "Sin dato", y el filtro "Alquiler ≤8€" se oculta.
- **Bilbao, Vitoria-Gasteiz y Donostia van sin desglose por distrito**, como municipios grandes. Existen límites oficiales de barrio ([Vitoria](https://opendata.euskadi.eus/catalogo/-/barrios-vitoria-gasteiz-limites-territoriales/), [Bilbao](https://github.com/BilbaoDataLab/zonificacion-escolar-bilbao/blob/master/data/distritos-bilbao.geojson), [Donostia](https://www.donostia.eus/datosabiertos/catalogo/wms-limites_administrativos)) pero en 3 formatos y proyecciones distintos; queda pendiente si algún día se quiere afinar.
- La búsqueda global por calle sigue siendo **solo de Madrid** (está acotada a la CAM en Nominatim); en País Vasco no se muestra, en vez de dar resultados falsos.
- El m² medio por enseña se calculó sobre las tiendas de Madrid; en País Vasco solo se usa como respaldo cuando el censo no trae el m² real de esa tienda concreta.

## Arranque rápido

```powershell
# Servir en local (necesario para que fetch() de los JSON funcione)
powershell -ExecutionPolicy Bypass -File serve.ps1 -Port 8000
# o, si tienes python/node instalados:
python3 -m http.server 8000
npx serve .
```

Abrir `http://localhost:8000` en el navegador.

No hace falta build ni instalación — vanilla JS + Leaflet + Chart.js desde CDN.

## Huecos verdes (los 5 normales)

El score de cada punto candidato combina 3 factores, todos con datos reales:
1. **Densidad de competidores × distancia** (estilo Unistead, como siempre): premia zonas con mercado (≥3-5 competidores en 500m) pero con hueco propio (≥150m a la tienda más cercana).
2. **Densidad comercial real en 500m** (m²/1.000 hab), con bandas reales de referencia (fuente: Abacus, geomarketing retail): `<200` muy baja saturación · `200-260` · `260-300` · `300-320` · `>320` muy saturado. Menos densidad puntúa más.
3. **Población real cercana** (INE por sección censal, radio de 3 min: 900 m distrito / 1.500 m municipio), usando como referencia los 3.000 hab del criterio "zona 3 min sin competencia" (ver Hueco especial) al mismo radio para el que se definió.

El popup de cada hueco muestra la densidad comercial y la población reales de esa zona.

## Hueco especial (negro)

Además de los 5 huecos verdes, en cada distrito/municipio se busca **un "hueco especial"** (marcador negro), siguiendo el documento **"EG — Métricas expansión formato de proximidad"** (Urbano/Rural). Dos bloques, cada uno exige **mínimo 2 de 3 criterios**:

**Población** (mínimo 2 de 3):
- Zona 3 min: ≥3.000 hab si no hay competencia ahí, ≥4.000 si la hay
- Zona 5 min: ≥6.000/5.000 hab (distrito/municipio) sin competencia, ≥8.000/6.000 con ella
- Barrio (distrito) ≥20.000 hab total, o pueblo (municipio) >3.000 hab total

**Competencia** (mínimo 2 de 3, techo en m² — no solo presencia/ausencia):
- Zona 3 min: ≤600 m² de competencia
- Zona 5 min: ≤2.000 m² de competencia
- Zona 5 min: ≤1 supermercado

Solo se marca si pasan **ambos bloques**. El popup muestra qué sub-criterios concretos se cumplen (✅/❌) para que sea auditable.

Los tiempos 3/5 min se **aproximan por radio** (no isócronas reales): distrito 900 m / 1,6 km; municipio 1,5 km / 2,6 km. La población es **real**: INE Censo Anual 2023 por sección censal (4.417 secciones de la CAM, geometría INE 2019, unidas por CUSEC; cubre ~97% de la población). Datos embebidos y cifrados en `SECCIONES` dentro de `index-src.html`.

## Municipios sin supermercado (lista)

Filtro **"🚫 Sin súper"** (pestaña Municipios): lista los municipios sin ningún supermercado real (solo tiendas pequeñas o sin datos), ordenados por población. Distingue con honestidad:
- **Sin súper (confirmado)**: el censo tiene el dato y solo hay tienda pequeña (p. ej. Quijorna, Valdilecha, Villamantilla).
- **Sin datos**: municipios sin datos en el censo 2024 (probable hueco, sin confirmar).

## Aperturas manuales (fuera del censo)

`const MANUAL_STORES` en `index-src.html` permite añadir aperturas nuevas que aún no están en el censo 2024 (`origen:"manual"`, con año de apertura). Se fusionan con el censo al iniciar: cuentan como competencia y m², y quitan al municipio de la lista "sin súper" si procede. En el mapa se marcan con la nota "📌 Apertura reciente (fuera del censo 2024)".

Fuente de aperturas: **revistainforetail.com** (alimentación, CAM). Incluidas: Eroski City El Vellón (Abarejo 1, 305 m², 2026) · Lidl Navalcarnero (Constitución 154, 1.520 m², 2025) · Lidl Getafe (Carpinteros 1C, 1.500 m², 2026) · Ahorramás Parla (Avda. Estrellas 47, 1.190 m², 2025) · BM Chamberí (Galileo 25, 900 m², 2026). Pendientes de coordenadas: Carrefour City Plaza Elíptica, Carrefour Express Márquez 44 y Antonio López 193; Aldi Leganés/Las Rozas sin dirección publicada.

Para nuevas aperturas: añadir la entrada a `MANUAL_STORES` (enseña, `ensena_key`, dom, cp, m², apertura, lat, lon) y reconstruir con `build-secure.ps1`. OpenStreetMap suele ir con retraso en aperturas muy recientes, así que lo manual es lo fiable.

## Búsqueda global por calle (solo distritos)

En la pestaña **Distritos** hay un buscador de calle que consulta **todas las tiendas de todos los distritos de Madrid a la vez** (no hace falta elegir distrito antes). Al pulsar un resultado, selecciona el distrito correspondiente y centra el mapa exactamente en esa tienda con un resaltado morado. Solo distritos — en Municipios queda oculto (el buscador por calle dentro de una zona ya seleccionada, "Tiendas por calle", sigue funcionando igual en ambas pestañas; de paso se arregló un bug donde ese buscador no filtraba porque le faltaba la función `onStreetSearch`).

**Buscar cualquier calle, tenga o no tienda cerca**: la búsqueda anterior solo encuentra calles donde ya hay una tienda del censo (busca en sus direcciones). Debajo de esos resultados hay un botón **"🌐 Buscar en el mapa"** que geocodifica la calle con Nominatim, acotado con `viewbox`+`bounded` a la Comunidad de Madrid (sin esto, "Calle Serrano, Madrid" puede encontrar una calle en Benidorm por una pedanía que se llama "Colònia Madrid"). El distrito se identifica leyendo `address.city_district` **o** `address.suburb` de la respuesta de Nominatim (Madrid usa uno u otro según la calle, no es consistente) y comparándolo con los 21 distritos; si no coincide con ninguno, se descarta (así se cumple "solo distritos" sin tener que comprobar polígonos). Si una calle existe en más de un distrito (p. ej. Serrano cruza Chamartín y Salamanca), se listan todas las coincidencias para que el usuario elija — no se adivina cuál es "la buena". Deduplicado por calle+distrito (no por coordenada exacta), para no repetir la misma calle larga varias veces por tener varios tramos en OSM. Búsqueda manual (botón o Enter), no en cada tecla, por respeto al límite de uso de Nominatim.

Dos trampas de Nominatim a tener en cuenta si se toca esto: (1) nombres ambiguos como "Serrano" (que también es una estación de Metro y un hotel en Madrid) hacen que devuelva esos POIs en vez de la calle — se soluciona anteponiendo "Calle " a la búsqueda si el usuario no puso ya un tipo de vía (avenida/plaza/paseo/etc.); (2) por eso mismo hay un filtro de sanidad que descarta cualquier resultado cuyo nombre de calle no contenga literalmente lo buscado.

Dos detalles que costó encontrar en pruebas: (1) si el nombre buscado coincide con un lugar conocido (p. ej. "Serrano" es también una estación de Metro y un hotel), Nominatim puede devolver esos sitios en vez de la calle — se antepone "Calle " a la búsqueda cuando el usuario no especifica ya un tipo de vía (calle/avenida/plaza/paseo/...), lo que prioriza la vía sobre el lugar homónimo; (2) hay un filtro de sanidad que descarta cualquier resultado cuyo nombre de calle no contenga literalmente lo buscado, por si aun así Nominatim devuelve algo no relacionado.

Todos los buscadores de texto (calle global, calle por zona, y el buscador principal de distrito/municipio) ignoran tildes: `normText()` compara en minúsculas y sin diacríticos, así que "Alcala" encuentra "Alcalá". Y el resaltado del mapa al elegir un resultado de calle usa `fitBounds({animate:false})` cuando hay un punto pendiente que resaltar — si se anima, Leaflet puede ignorar el `setView` posterior por tener ya una animación en curso (pasaba sobre todo en móvil).

## Generar PDF

Botón **"📄 Generar PDF"** en el detalle de cada zona: genera y descarga directamente un archivo `.pdf` (con `jsPDF`, vía CDN — sin diálogo de impresión de por medio). Incluye: métricas principales, renta real del entorno, perfil socioeconómico (municipios), desglose de competencia por enseña, huecos de mercado detectados, hueco especial, y el listado de tiendas de la zona (hasta 40, con aviso si hay más). Paginación automática.

No incluye una captura del mapa: los tiles satélite/calles son de servidores externos (Esri/OpenStreetMap) que el navegador puede bloquear al capturarlos por CORS de forma no siempre predecible — mejor un PDF que funcione siempre con todos los datos en texto que uno que a veces salga con el mapa roto.

## Geolocalización

Dos botones distintos, para dos usos distintos:

- **📍 junto a la búsqueda principal** (`geolocalizarYBuscar()`) — el más útil: localiza al usuario y **abre directamente** su distrito o municipio, con todos sus datos. Usa reverse geocoding de Nominatim (`address.city_district`/`suburb` → los 21 distritos; `address.town`/`village`/`municipality`/`city` → los 122 municipios) para identificar la zona real, cambia de pestaña si hace falta y selecciona la zona. Si no reconoce la zona (fuera de la CAM) o el navegador deniega el permiso, lo dice en un mensaje bajo el buscador (no un `alert()` bloqueante).
- **📍 Mi ubicación en los controles del mapa** (`locateMe()`) — más simple: solo coloca un marcador azul en tu posición real dentro de la zona que ya tienes abierta, sin cambiar de zona. Útil si ya estás viendo tu distrito y quieres ver dónde caes tú exactamente respecto a los huecos.

Ambos piden permiso al navegador (`navigator.geolocation`, requiere HTTPS y gesto explícito del usuario — nunca se piden solos) y comparten la misma variable `userLocation`. Una vez fijada, **cada popup de hueco** (verde y especial) muestra la distancia real en línea recta desde ahí. El marcador se recalcula en cada `renderMap()` (el mapa se recrea entero al cambiar de zona), así que persiste al navegar sin volver a pedir permiso.

## Perfil socioeconómico por municipio

En el detalle de cada municipio aparece un bloque "Perfil socioeconómico" con: **% con estudios superiores** y **% población de 65+ años** (Censo 2021, INE) y **paro registrado** (nº personas, SEPE junio 2026). Datos embebidos en `const SOCIO` (clave = nombre de municipio normalizado; `normZona()` / `getSocio()`). Solo municipios (no distritos de Madrid ciudad, que son nivel municipal en estas fuentes). Descartados por no aportar a nivel de zona: renta duplicada (ya integrada) y precio de vivienda (solo disponible a nivel provincial).

## Renta por sección en el score

El componente de renta del score (renta inversa, 10%) usa la **renta real por persona del entorno de 2 km** de cada zona (`computeRentaEntorno`, media ponderada por población de las secciones INE ADRH 2023), en vez del agregado por hogar del municipio. Zonas rurales (secciones muy grandes sin centroide en 2 km) caen a la sección con renta más cercana. Ambas rentas (por hogar agregada y por persona del entorno) se ven al pulsar la tarjeta de renta.

## Seguridad / contraseña

La app se sirve **cifrada**: `index.html` es una pantalla de acceso que descifra la app (AES-256, Web Crypto) solo con la contraseña correcta. Los datos nunca están en claro en el sitio público.

La contraseña **solo se pide la primera vez** en cada dispositivo: tras una entrada correcta queda recordada (localStorage) y las siguientes veces entra directo. Si se introduce mal, se olvida y vuelve a pedirla. Nota: cualquiera con acceso físico al dispositivo desbloqueado podrá abrir la app.

**Para editar la app:**
1. Editar **`index-src.html`** (la fuente en claro). NUNCA editar `index.html` a mano.
2. Regenerar el `index.html` cifrado:
   ```powershell
   powershell -ExecutionPolicy Bypass -File build-secure.ps1 -Password 'LA_CONTRASEÑA'
   ```
3. `git add -A && git commit && git push`

`index-src.html` está en `.gitignore` — no se sube. Guárdalo tú a buen recaudo: es la única copia en claro.

## App instalable (PWA)

La app es una PWA: se puede instalar en el móvil (Android/iOS, "Añadir a pantalla de inicio") y en el ordenador (Chrome/Edge, icono de instalar en la barra de direcciones). Funciona offline tras la primera carga gracias a `sw.js`.

- `manifest.json` — nombre, iconos, color de tema
- `sw.js` — cachea `index.html`, los JSON de `data/` y los iconos
- `icons/` — generados con `gen-icons.ps1` (System.Drawing, sin dependencias externas)
- El layout es responsive por debajo de 860px: panel de búsqueda/detalle/enseñas se navegan con una barra inferior en vez de verse los tres a la vez

## Estructura

```
retailsite_madrid/
├── index-src.html          # FUENTE editable en claro (NO se publica, gitignored)
├── build-secure.ps1        # Cifra index-src.html -> index.html con contraseña
├── index.html              # GENERADO: pantalla de acceso + app cifrada (AES-256)
├── manifest.json           # Metadatos PWA (nombre, iconos, color)
├── sw.js                   # Service worker (caché offline)
├── serve.ps1               # Servidor estático local (PowerShell, sin dependencias)
├── gen-icons.ps1            # Genera los PNG de icons/ (System.Drawing)
├── icons/                  # Iconos PWA (192, 512, maskable, apple-touch, favicon)
├── data/                   # Datos separados en JSON editables
│   ├── m2_por_ensena.json      # m² medio por enseña (calculado del censo)
│   ├── distritos.json          # 21 distritos Madrid ciudad
│   ├── municipios.json         # 122 municipios CAM > 1.800 hab
│   ├── stores_distritos.json   # 1.111 tiendas de Madrid ciudad (con lat/lon)
│   └── stores_municipios.json  # 1.220 tiendas de municipios CAM
├── README.md
└── CLAUDE.md               # Contexto para Claude Code
```

Actualmente los datos están **también embebidos** en `index.html` para funcionar con doble clic. Ver sección "Refactor a datos externos" abajo.

## Datos incluidos

- **21 distritos** de Madrid ciudad con población 2025 (Ayto. Madrid)
- **122 municipios CAM** con población > 1.800 hab (Padrón INE 2025)
- **2.331 establecimientos** activos del censo de distribución alimentaria 2024
- **m² medios por enseña** calculados sobre las 2.331 tiendas reales (Mercadona 1.527m², Lidl 1.236m², DIA 409m², BM 921m²…)
- **Alquileres €/m²/mes** reales para 25 municipios + estimados para el resto (fórmula por renta y zona)
- **453 tiendas con ventas reales** conocidas del fichero fuente (Mercadona, DIA, Carrefour, Hiperusera, Eroski)

## Funcionalidades actuales (v0.6)

1. **Búsqueda** por CP o nombre de distrito/municipio
2. **Filtros**: con hueco, alta densidad, alquiler ≤8€, zona geográfica
3. **Score de viabilidad** 0-99 ponderando 6 factores (saturación 28%, hab/tienda 18%, densidad pobl. 18%, alquiler 16%, renta inversa 10%, paro 10%)
4. **Radar de perfil** — 6 dimensiones
5. **Buscador de tiendas por calle** — filtrable por enseña, muestra ventas reales cuando existen
6. **Mapa satélite (Esri) + calles (OSM)** con marcadores etiquetados por enseña
7. **Detección de huecos estilo Unistead**:
   - Rejilla de 1.600 puntos dentro del bbox P10-P90 de las tiendas
   - Radio de validación urbana 500m (mismo que Unistead)
   - Score = densidad urbana × min(distancia, 400m)
   - Filtros: ≥150m a competencia, ≤600-800m a cualquier tienda, ≥3-5 competidores en 500m
   - Devuelve exactamente 5 huecos por zona
8. **Reverse geocoding** de huecos vía Nominatim (OpenStreetMap)
9. **Recomendación ejecutiva** generada por reglas (formato, enseña, saturación, riesgo, veredicto)

## Fórmulas clave

**Score de viabilidad**
```
total = 0.28·saturación + 0.18·(hab/tienda) + 0.18·densidad_pobl
      + 0.16·(1/alquiler) + 0.10·(1/renta) + 0.10·paro
```

**Saturación de mercado**
```
m2_por_hab = m2_totales_abiertos / habitantes
saturación_pts = max(0, 1 - m2_por_hab / 0.40) * 100
# Benchmark: 0.15 m²/hab en España, 0.40 techo
```

**m² totales abiertos**
```
Σ (nº_tiendas_enseña × m²_medio_enseña)
```

**Coste alquiler**
```
alq_pts = 100 - (alq_grande - 5) / 20 * 100
# 5€/m²/mes = 100 pts, 25€/m²/mes = 0 pts
```

**Ratio hab/tienda**
```
ratio_pts = min(100, habitantes/tienda / 12000 * 100)
```

**Detección de huecos (score interno)**
```
score = tiendas_en_500m × min(dist_tienda_más_cercana, 400m)
```

## Refactor a datos externos (siguiente paso natural)

`index.html` sigue teniendo los datos hardcodeados. Los JSON en `data/` ya están extraídos y listos, pero la app aún no los lee. Para migrar:

1. Reemplazar en `index.html` los bloques `const M2_POR_ENSENA = {...}`, `const DISTRITOS = [...]`, `const MUNICIPIOS = [...]`, `const STORES_DIST = {...}`, `const STORES_MUNI = {...}` por variables vacías
2. Añadir al inicio del script:
   ```javascript
   let M2_POR_ENSENA, DISTRITOS, MUNICIPIOS, STORES_DIST, STORES_MUNI;
   Promise.all([
     fetch('data/m2_por_ensena.json').then(r=>r.json()),
     fetch('data/distritos.json').then(r=>r.json()),
     fetch('data/municipios.json').then(r=>r.json()),
     fetch('data/stores_distritos.json').then(r=>r.json()),
     fetch('data/stores_municipios.json').then(r=>r.json()),
   ]).then(([m2, d, m, sd, sm]) => {
     M2_POR_ENSENA = m2; DISTRITOS = d; MUNICIPIOS = m;
     STORES_DIST = sd; STORES_MUNI = sm;
     init();
   });
   ```
3. Envolver la inicialización actual en `function init() { ... }`

Ventaja: podrás editar los JSON sin tocar HTML.
Inconveniente: dejará de abrirse con doble clic (necesitas servidor local).

## Ideas pendientes / roadmap

- [ ] Buscador por coordenadas (lat/lon) para analizar un punto exacto estilo Unistead
- [ ] Cálculo Huff completo integrado en la app (cuota, canibalización sobre competidores con venta conocida)
- [ ] Añadir tiendas manualmente (fuente "manual") para los 8 municipios sin datos del censo
- [ ] Exportar a Excel el ranking de zonas con score
- [ ] Filtro de enseñas: "buscar zonas sin Mercadona"
- [ ] Isócronas / áreas de influencia reales por vía pública (OSRM) en vez de círculos
- [ ] Layer de renta por sección censal (INE)
- [ ] Modo comparación entre 2-3 zonas lado a lado
- [x] Modo móvil optimizado (PWA instalable + layout responsive con barra de navegación inferior)

## Fuentes de datos

- **Censo Distribución Alimentaria 2024** — 25.472 establecimientos nacionales, 2.367 en Madrid
- **Padrón CAM 2025** (INE + Ayto. Madrid)
- **Precios Alquiler Comercial 2024** (fichero interno + estimaciones por renta/zona)
- **Ventas reales** — 1.801 tiendas con dato del censo (DIA 2011-2012, Mercadona, Hiperusera, Carrefour Express 2018-2019, Carrefour Market 2019, Eroski)

## Convenciones de código

- Sin build ni bundler: JS plano en un solo `<script>` dentro de `index.html`
- Sin frameworks: manipulación DOM directa
- Comentarios en español (mismo idioma que la UI)
- Naming: variables/funciones en camelCase, constantes globales en UPPER_SNAKE_CASE
- Estilo: sin punto y coma cuando no hace falta, comillas simples en JS
