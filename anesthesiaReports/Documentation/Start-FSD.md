

# StartSwift-FSD — Fundação do App iOS

Este documento define as **bases arquiteturais do app iOS**, servindo como referência inicial para desenvolvimento, evitando divergências de modelo, responsabilidades duplicadas e decisões inconsistentes ao longo do projeto.

---

## 1. Objetivo do App

Aplicativo iOS **offline-first**, integrado a um AuthServer externo, com foco em:
- consistência de dados
- segurança
- sincronização previsível
- uso de SwiftData como storage local

O app **não é a fonte da verdade**.  
O backend define estado; o app reflete e reage.

---

## 2. Princípios Arquiteturais

### 2.1 Offline-first
- O app deve funcionar sem conexão
- Sincronização ocorre quando online
- Nenhum dado crítico depende de estado inferido

### 2.2 Backend como Fonte da Verdade
- Estado de usuário nunca é calculado localmente
- Campos como `active`, `isDeleted`, `statusChangedAt` vêm do backend
- O app nunca reativa contas

### 2.3 Clareza > Conveniência
- Modelos espelham o backend
- Campos não são omitidos “por simplicidade”
- Decisões de sync dependem de dados explícitos

---

## 3. SwiftData — Diretrizes

### 3.1 Uso do `@Model`
- Cada entidade persistida deve ser anotada com `@Model`
- Models representam **estado persistido**, não DTOs de rede
- Não incluir lógica de negócio nos models

### 3.2 Identidade
- Cada model possui um identificador vindo do backend (`userId`)
- Identificadores nunca são alterados após criação
- Deleção local ocorre apenas por decisão explícita de sync

---

## 4. Modelo Inicial — User

O primeiro modelo do app é o **User**, representando o usuário autenticado.

### Responsabilidades do Model
- Representar fielmente o estado retornado por `/users/me`
- Suportar decisões de sync e invalidação de cache
- Servir como âncora para o restante do banco local

### Campos obrigatórios
- `userId`
- `name`
- `emailAddress`
- `crm`
- `rqe`
- `active`
- `isDeleted`
- `createdAt`
- `updatedAt`
- `statusChangedAt`

📌 Campos como `active` e `isDeleted` **não são opcionais**.

---

## 5. Sincronização de Estado

### 5.1 Atualização
- Se `statusChangedAt` mudar → banco local é invalidado
- Se `updatedAt` mudar → dados podem ser atualizados

### 5.2 Soft Delete
- `isDeleted = true` implica:
  - limpeza do banco local
  - logout forçado
  - bloqueio de uso offline

### 5.3 Regra Clara de Lifecycle (Estado)

Este projeto adota uma **regra explícita de lifecycle**, definida em documentação e seguida pelo código.

A regra é:

> Estados **só podem ser criados, alterados ou destruídos em resposta a eventos claramente definidos**.

Nenhum estado muda por conveniência, heurística ou inferência local.

#### Eventos que podem alterar estado

- **Criação de estado**
  - Login bem-sucedido

- **Atualização de estado**
  - Resposta válida do backend (`/users/me`)
  - Conclusão bem-sucedida de um sync

- **Invalidação de estado**
  - `statusChangedAt` do backend maior que o valor local

- **Destruição de estado**
  - Logout explícito
  - Reset total do app

Se uma mudança de estado não puder ser explicada por um desses eventos, **ela não deve ocorrer**.

📌 O lifecycle é uma **regra mental + documental**, não um detalhe de implementação.

### 5.4 Uso de Tempo — Regra Crítica

O app **nunca utiliza `Date()` para decidir estado ou sincronização**.

Regras:

- Timestamps usados para decisão **sempre vêm do backend**
  - `updatedAt`
  - `statusChangedAt`

- `Date()` pode ser usado apenas para:
  - UI
  - loading
  - métricas técnicas
  - timeouts

📌 O relógio do dispositivo não é confiável para decisões de verdade.

---

## 6. O que NÃO fazer

- ❌ Inferir estado do usuário
- ❌ Reativar conta localmente
- ❌ Alterar `userId`
- ❌ Omitir campos “porque não usa agora”
- ❌ Misturar DTOs de rede com `@Model`

---

## 7. Organização do Código (diretriz inicial)

```text
Models/        → SwiftData @Model
Networking/    → DTOs + API client
Sync/          → regras de sincronização
Auth/          → sessão, tokens, estado do usuário
UI/            → SwiftUI Views
```

---

## 8. Objetivo deste Documento

- Servir como **fundação**
- Guiar decisões futuras
- Evitar refatorações estruturais
- Facilitar onboarding

---

## Status

✅ Documento inicial definido  
📌 Deve evoluir junto com o app, mas **nunca contradizer o backend**

---