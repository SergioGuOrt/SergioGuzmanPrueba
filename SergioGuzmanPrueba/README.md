# SergioGuzmanPrueba

Aplicación iOS nativa que consume la API pública de [Rick and Morty](https://rickandmortyapi.com).

---

## Características Implementadas

- Listado de personajes con scroll infinito (paginación).
- Búsqueda por nombre en tiempo real con debounce.
- Filtros combinados por estado (Alive / Dead / Unknown) y especie (Human / Alien).
- Pull to refresh.
- Detalle de personaje con imagen, datos y lista de episodios.
- Favoritos persistidos en CoreData con toggle desde el detalle.
- Pantalla de favoritos con swipe-to-delete.
- Episodios vistos con persistencia local y toggle visual.
- Mapa interactivo con MapKit mostrando ubicación simulada del personaje.
- Autenticación biométrica (Face ID / Touch ID) para acceder a favoritos.
- Caché local de personajes con estrategia Network First y fallback offline.
- Logging estructurado con os.Logger por categorías.
- Pruebas unitarias (30 tests) con mocks de red y CoreData in-memory.
- Pruebas de UI automatizadas con XCUITest.

---

## Arquitectura

### MVVM (Model-View-ViewModel)

- **Model:** Structs Swift puros (`Character`, `Episode`) conformes a `Codable`.
- **View:** `UIViewController` con layout en Storyboards físicos. Solo UI, sin lógica.
- **ViewModel:** Gestiona estado, lógica de presentación y comunicación con servicios. Expone datos mediante `@Published` + Combine. No importa UIKit.

### Coordinator Pattern

Cada módulo tiene su propio Coordinator que gestiona la navegación. Los ViewControllers nunca hacen `push` ni `present` directamente. Los ViewModels señalizan intenciones de navegación mediante closures que el Coordinator suscribe.

```
SceneDelegate → AppCoordinator → HomeCoordinator → DetailCoordinator → MapCoordinator
                                                  → FavoritesCoordinator → DetailCoordinator
```

### Swinject (Inyección de Dependencias)

Un único `AppAssembly` registra todas las dependencias del proyecto. Cada servicio, repositorio y ViewModel se resuelve del container. Los Coordinators reciben el container y resuelven las dependencias de sus módulos.

### Async/Await

La capa de red usa `async/await` nativo de Swift para un call site limpio. `APIClient` ejecuta requests con `URLSession.data(for:)` async. Los ViewModels lanzan `Task` para operaciones asíncronas.

---

## Persistencia Local (CoreData)

| Entidad | Propósito |
|---------|-----------|
| `CachedCharacter` | Caché local de personajes descargados de la API. Estrategia upsert por characterId. |
| `FavoriteCharacter` | Personajes marcados como favoritos por el usuario. |
| `ViewedEpisode` | Episodios marcados como vistos para cada personaje. |

### Estrategia de Caché

- **Network First:** Si hay conexión, los personajes se obtienen de la API y se guardan/actualizan en CoreData (upsert por `characterId`).
- **Fallback Offline:** Si la red falla, se leen personajes del caché local aplicando los mismos filtros (nombre, estado, especie) sobre CoreData.
- **Lightweight Migration:** Habilitada automáticamente para soportar evolución del modelo sin pérdida de datos.

---

## Tecnologías Utilizadas

| Tecnología | Uso |
|------------|-----|
| Swift 5 | Lenguaje principal |
| UIKit | Framework de UI con Storyboards |
| CoreData | Persistencia local |
| MapKit | Mapa interactivo con anotaciones |
| LocalAuthentication | Face ID / Touch ID |
| Combine | Bindings reactivos ViewModel → View |
| Swinject | Inyección de dependencias |
| SwiftLint | Linting de código (pod instalado, disponible para configuración) |
| CocoaPods | Gestión de dependencias |
| XCTest | Unit Tests y UI Tests |
| os.Logger | Logging estructurado nativo |

---

## Instalación

This project does not include development certificates or provisioning profiles.
To run the application on a physical device: 
1. Open `SergioGuzmanPrueba.xcworkspace`. 
2. Select the `SergioGuzmanPrueba` target. 
3. Go to **Signing & Capabilities**. 
4. Select your own Apple Developer Team. 
5. Update the Bundle Identifier if necessary. 
6. Build and run the application. No additional configuration is required to run the project on the iOS Simulator.

```bash
git clone https://github.com/tu-usuario/SergioGuzmanPrueba.git
cd SergioGuzmanPrueba
pod install
open SergioGuzmanPrueba.xcworkspace
```

Requisitos:
- Xcode 16.4 o superior
- iOS 17.0 deployment target
- CocoaPods 1.16+
- macOS con soporte para simulador iOS

---

## Ejecución de Pruebas

### Unit Tests

```bash
xcodebuild test \
  -workspace SergioGuzmanPrueba.xcworkspace \
  -scheme SergioGuzmanPrueba \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:SergioGuzmanPruebaTests
```

30 tests cubriendo:
- `HomeViewModel`: carga, error, filtros, paginación, closures de navegación.
- `DetailViewModel`: favorito, episodios, toggle visto, navegación.
- `FavoriteRepository`: CRUD completo con CoreData in-memory.
- `ViewedEpisodeRepository`: CRUD completo con CoreData in-memory.

### UI Tests

```bash
xcodebuild test \
  -workspace SergioGuzmanPrueba.xcworkspace \
  -scheme SergioGuzmanPrueba \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:SergioGuzmanPruebaUITests
```

Flujo automatizado: Home → Detail → Toggle Favorito → Back.

---

## Logging

Logging estructurado con `os.Logger` nativo de Apple. Visible en Console.app filtrando por subsistema `com.sergioguzman.SergioGuzmanPrueba`.

| Categoría | Qué registra |
|-----------|--------------|
| Network | Requests HTTP: inicio, éxito, errores, decoding failures |
| Persistence | Operaciones CoreData: favoritos guardados/eliminados, episodios marcados |
| Navigation | Transiciones de pantalla: Detail, Favorites, Map |
| Biometric | Autenticación: solicitud, éxito, fallo, cancelación, disponibilidad |

---

## Flujo Principal

```
Home (listado + búsqueda + filtros)
  ├── Tap personaje → Detail
  │     ├── Toggle favorito (CoreData)
  │     ├── Toggle episodio visto (CoreData)
  │     └── Ver en mapa → Map (MapKit + pin)
  │
  └── Tap ❤️ → Face ID → Favorites
        ├── Lista de favoritos desde CoreData
        └── Tap favorito → Detail
```

---

## Consideraciones

- **Coordenadas del mapa simuladas:** La API de Rick and Morty no proporciona coordenadas geográficas reales. Se generan coordenadas determinísticas basadas en el ID del personaje para que el mismo personaje siempre aparezca en la misma ubicación.
- **Face ID en simulador:** La autenticación biométrica requiere dispositivo físico para validación completa. En simulador, el flujo degrada mostrando un alert informativo.
- **Rate limiting (429):** La API tiene límite de requests. La app incluye protección contra requests duplicados (debounce, cancelación de tasks, supresión de errores 429).
- **Caché offline:** Los personajes se muestran desde caché local cuando no hay conexión a internet. Los filtros funcionan offline sobre los datos almacenados.

---

## Estructura del Proyecto

```
SergioGuzmanPrueba/
├── Application/          → AppDelegate, SceneDelegate, DI/AppAssembly
├── Coordinators/         → Coordinator protocol, BaseCoordinator, AppCoordinator
├── Modules/
│   ├── Home/             → HomeCoordinator, HomeViewController, HomeViewModel, CharacterTableViewCell
│   ├── Detail/           → DetailCoordinator, DetailViewController, DetailViewModel, EpisodeTableViewCell
│   ├── Favorites/        → FavoritesCoordinator, FavoritesViewController, FavoritesViewModel
│   └── Map/              → MapCoordinator, MapViewController, MapViewModel
├── Services/
│   ├── Network/          → APIClient, CharacterService, EpisodeService, NetworkError
│   ├── Persistence/      → PersistenceController, Repositories, CoreData entities
│   ├── AppLogger.swift
│   └── BiometricAuthService.swift
├── Models/               → Character, Episode
├── Common/               → BaseViewController
└── Resources/            → Constants, Assets, LaunchScreen
```

## Author

**Sergio Guzmán Ortiz**

iOS Developer
