# Consolidação de estados de loading em Views SwiftUI

## Objetivo
Padronizar o comportamento de loading por seção para evitar:
- “pulos” de UI
- empty state aparecendo antes do carregamento terminar
- múltiplos booleans difíceis de manter

## Padrão recomendado (granular, substituição por seção)
Use um `Set` para controlar **o carregamento** e flags `hasLoaded` para controlar **o empty state**.

```swift
private enum LoadingScope: Hashable {
    case patient
    case shares
    case surgeries
}

@State private var loadingScopes: Set<LoadingScope> = []
@State private var hasLoadedPatient = false
@State private var hasLoadedShares = false
@State private var hasLoadedSurgeries = false
```

### Regra de UI (substituição correta)
- **Carregando** → shimmer
- **Carregou** e **vazio** → empty state
- **Carregou** e **tem dados** → lista

Exemplo no `body`:

```swift
if !hasLoadedPatient {
    infoShimmerSection
} else {
    infoContentSection
}

if !hasLoadedSurgeries {
    surgeriesShimmerSection
} else {
    surgeriesContentSection
}
```

### Controle do lifecycle (carregar e marcar)
```swift
private func loadPatient(trackLoading: Bool = true) async {
    hasLoadedPatient = false
    if trackLoading { loadingScopes.insert(.patient) }
    defer {
        if trackLoading { loadingScopes.remove(.patient) }
        hasLoadedPatient = true
    }

    // fetch...
}

private func loadSurgeries(trackLoading: Bool = true) async {
    hasLoadedSurgeries = false
    if trackLoading { loadingScopes.insert(.surgeries) }
    defer {
        if trackLoading { loadingScopes.remove(.surgeries) }
        hasLoadedSurgeries = true
    }

    // fetch...
}
```

### Evitar empty state antes do load
O empty state só deve aparecer quando `hasLoadedX == true`. Esse é o principal ponto que evita o comportamento “carregando → empty → lista”.

## Observações importantes
- **Nunca** mostre empty state antes de `hasLoadedX == true`.
- Se um `.onChange` dispara um segundo fetch, **não** remova o `loadingScopes` antes do fetch principal terminar.
- Em load geral (primeiro acesso), é normal iniciar `hasLoaded* = false` e os shimmers aparecerem imediatamente.

## Preview
```swift
init(initialLoading: Bool = false) {
    _loadingScopes = State(initialValue: initialLoading ? [.patient, .shares, .surgeries] : [])
    _hasLoadedPatient = State(initialValue: !initialLoading)
    _hasLoadedSurgeries = State(initialValue: !initialLoading)
    _hasLoadedShares = State(initialValue: !initialLoading)
}
```

## Benefícios
- Substituição limpa (shimmer → conteúdo)
- Estado previsível
- Escala bem quando novas seções são adicionadas
