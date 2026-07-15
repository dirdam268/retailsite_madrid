# RetailSite Madrid

Herramienta web para análisis de expansión de supermercados en la Comunidad de Madrid. Cruza el censo real de distribución alimentaria con datos socioeconómicos y detecta huecos de mercado con validación urbana.

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

## App instalable (PWA)

La app es una PWA: se puede instalar en el móvil (Android/iOS, "Añadir a pantalla de inicio") y en el ordenador (Chrome/Edge, icono de instalar en la barra de direcciones). Funciona offline tras la primera carga gracias a `sw.js`.

- `manifest.json` — nombre, iconos, color de tema
- `sw.js` — cachea `index.html`, los JSON de `data/` y los iconos
- `icons/` — generados con `gen-icons.ps1` (System.Drawing, sin dependencias externas)
- El layout es responsive por debajo de 860px: panel de búsqueda/detalle/enseñas se navegan con una barra inferior en vez de verse los tres a la vez

## Estructura

```
retailsite_madrid/
├── index.html              # App completa (single file)
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
