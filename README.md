# Rick & Morty

Aplikacja w SwiftUI przeglądająca API [Rick and Morty](https://rickandmortyapi.com),
zbudowana w oparciu o The Composable Architecture (TCA).

- Trzy ekrany: lista postaci → szczegóły postaci → szczegóły odcinka
- Wyszukiwanie po nazwie (z debounce i anulowaniem w locie)
- Paginacja (infinite scroll)
- Pull-to-refresh 
- Obsługa stanów: ładowanie / dane / pusty wynik / błąd
- Swift 6, `nonisolated` jako domyślna izolacja, minimalny target iOS 18.0
- Klient API oparty o Swift Concurrency (`async/await`)
- Możliwość dodania postaci do ulubionych.
- Testy jednostkowe
- Podstawowe testy snapshot'owe


Aplikacja jest podzielona na osobne moduły (targety) w jednym pakiecie SPM:

- `Models` — czyste typy domenowe (Decodable, Sendable), bez zależności
- `Networking` — `Endpoint` + `APIClient` (klient jako `@DependencyClient`)
- `SharedUI` — współdzielone elementy (np. `LoadingState`, klucz `@Shared`)
- `CharactersListFeature`, `CharacterDetailFeature`, `EpisodeDetailFeature` 
- `Root` — hostuje listę

## Uruchomienie

Otworzyć projekt w Xcode (Xcode 26, symulator iOS 18+). Zależności pobiorą się
automatycznie przez SPM.

Dependencies: 
[swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) (1.26.0+).
[swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) (1.19.0+).
