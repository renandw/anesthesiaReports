# Auth Swift — Functional Specification Document (FSD)

## 1. Objetivo

Este documento define a arquitetura, responsabilidades e regras do módulo de autenticação no app iOS, alinhado ao AuthServer e ao modelo offline-first.

O módulo de Auth Swift é responsável por:
- criação de sessão
- manutenção segura da sessão
- detecção de mudanças de estado do usuário
- invalidação e limpeza de dados locais quando necessário

---

## 2. Princípios Arquiteturais

### 2.1 Separação de Responsabilidades

| Camada          | Responsabilidade |
|-----------------|------------------|
| DTO             | Espelhar JSON do backend |
| AuthAPI         | Comunicação HTTP |
| TokenManager    | Gestão de tokens e validade da sessão |
| AuthSession     | Estado da sessão (authenticated / sessionExpired / unauthenticated) |
| AuthService     | Orquestração de fluxo |
| SwiftData       | Persistência local |
| ChangeLog       | Registro de intenções locais |
| ChangeLogFactory| Semântica e deduplicação de intenções |
| SyncManager     | Execução de sincronização |

Nenhuma camada executa responsabilidades de outra.

### 2.2 Regra de Ouro

> AuthService nunca executa refresh diretamente.  
> Refresh é responsabilidade exclusiva do TokenManager.

---

## 3. Componentes

### 3.1 AuthAPI

Responsável por executar chamadas HTTP para endpoints de autenticação.

Características:
- Métodos estáticos
- Não armazena tokens
- Não decide lifecycle
- Não acessa SwiftData

Endpoints cobertos:
- POST /auth/login
- POST /auth/register
- POST /auth/refresh
- POST /auth/logout
- GET /users/me

`fetchMe` recebe o access token por parâmetro para evitar dependência circular.

---

### 3.2 TokenManager

Responsável por gerenciar a sessão autenticada.

Responsabilidades:
- armazenar tokens (Keychain)
- fornecer access token válido quando disponível
- executar refresh **explícito e controlado**
- sinalizar sessão expirada quando refresh falha

Regras críticas:
- no máximo 1 tentativa de refresh
- refresh falhou → sessão inválida
- nunca chamar accessToken() dentro do refresh

TokenManager não conhece SwiftData nem UI.

---

### 3.3 AuthService

Responsável por orquestrar o fluxo de autenticação e estado do usuário.

Responsabilidades:
- login
- register
- carregar estado do usuário
- reagir a mudanças de estado (inactive/deleted)
- logout
- limpar dados locais quando necessário

AuthService não executa refresh manual nem armazena tokens.

---

### 3.4 AuthSession (Implementado)

AuthSession representa o **estado atual da sessão** como uma máquina de estados explícita.

Estados possíveis:
- `unauthenticated`
- `authenticated`
- `sessionExpired`

Responsabilidades:
- refletir o estado real da sessão
- permitir UI reagir sem apagar dados
- bloquear mutações quando necessário
- integrar-se com o SyncManager

AuthSession **não executa** login, refresh ou logout.
Ela apenas representa estado.

## 4. Fluxos de Autenticação

### 4.1 Register

- Chama AuthAPI.register
- Não cria sessão
- Não salva tokens
- Usuário deve fazer login explicitamente

Usuário criado ≠ sessão criada.

---

### 4.2 Login

1. Chama AuthAPI.login
2. Tokens são salvos via TokenManager
3. Estado do usuário é carregado (/users/me)
4. User local é criado ou atualizado
5. SyncState(scope: user) é criado/atualizado

---

### 4.3 Startup do App (Sessão Existente)

1. App verifica AuthSession
2. Se estado for `authenticated`:
   - tenta validar access token
3. Se access token estiver expirado:
   - AuthSession → `sessionExpired`
   - dados locais são preservados
4. Se refresh for bem-sucedido:
   - AuthSession permanece `authenticated`
5. AuthService chama `/users/me`
6. Estado do usuário é validado
7. SyncManager pode operar se sessão válida

---

### 4.4 Logout (Duas Fases)

#### Fase 1 — Sessão Expirada (Não Destrutiva)
- Tokens de acesso são invalidados
- Dados locais são preservados
- Novas mutações são bloqueadas
- Usuário deve reautenticar ou encerrar sessão

#### Fase 2 — Logout Definitivo
- Executado apenas por ação explícita do usuário
- Remove tokens
- Limpa SwiftData
- Encerra sessão local independentemente do backend

---

### 4.5 Relação entre Sessão e Sincronização (Modelo Híbrido)

Auth define **se** o sync pode ocorrer.
SyncManager define **como** o sync ocorre.

Regras:
- Sessão válida → sync permitido
- `sessionExpired` → sync bloqueado, dados preservados
- Logout definitivo → dados removidos
- Soft delete → limpeza imediata

Auth **nunca** executa sync.
Sync **nunca** decide estado de sessão.

---

## 5. Tratamento de Erros

### 5.1 APIErrorResponse

Espelha o backend no formato:
```json
{
  "error": {
    "code": "...",
    "message": "..."
  }
}
```

---

### 5.2 AuthError

AuthError representa decisões de domínio no app.

Casos relevantes:
- notAuthenticated
- invalidCredentials
- sessionExpired
- userInactive
- userDeleted
- serverError
- rateLimited
- conflict
- dbUnavailable
- dbTimeout

Erros de token do backend (`TOKEN_EXPIRED`, `TOKEN_INVALID`)
são mapeados para `sessionExpired`.

Somente AuthService e AuthSession reagem a esses erros.

Novos códigos de backend com mapeamento explícito:
- `RATE_LIMITED` -> `rateLimited`
- `ALREADY_DELETED` -> `alreadyDeleted`
- `CONFLICT` -> `conflict`
- `DB_UNAVAILABLE` -> `dbUnavailable`
- `DB_TIMEOUT` -> `dbTimeout`

Política de sessão:
- Fatais: `sessionExpired`, `unauthorized`, `userInactive`, `userDeleted`
- Não fatais: `rateLimited`, `alreadyDeleted`, `conflict`, `dbUnavailable`, `dbTimeout`

---

## 6. Persistência Local

### 6.1 User (@Model)

- Espelha o backend
- Não contém estado de sync
- Atualizado exclusivamente via /users/me

---

### 6.2 SyncState (@Model)

- Estado local do app
- Um por SyncScope
- Para scope user:
  - lastStatusChangedAt

lastSyncAt não é atualizado no fluxo de auth.

SyncState não executa sincronização.  
Ele apenas fornece contexto para decisões de invalidação e integração com o mecanismo de sync definido em `sync.md`.

---

## 7. Limpeza de Dados

### 7.1 clearLocalData

- Remove User
- Remove dados de domínio
- Não remove SyncState automaticamente

SyncState só é removido em reset total do app.

---

## 8. Regras Críticas (Resumo)

- AuthService não faz refresh
- AuthAPI não guarda tokens
- DTO não contém lógica
- TokenManager decide validade da sessão
- Backend é fonte da verdade
- Lifecycle é definido em documentação
- Auth nunca decide conflitos de dados nem executa sync

---

## 9. Conclusão

O módulo de Auth já suporta expiração de sessão sem perda de dados locais, permitindo recuperação segura após reautenticação.

O módulo de Auth Swift é previsível, testável e alinhado ao backend.

Nenhuma decisão crítica é implícita ou mágica.

---

## 10. Sessão e Logout (Implementado)

Esta seção descreve o comportamento atual do módulo de autenticação para suportar sincronização offline robusta, evitando perda de dados locais quando a sessão expira.

---

### 10.1 Situação Atual (Estado Base)

O comportamento atual é:

- Expiração de sessão → estado `sessionExpired`
- Dados locais são preservados
- Sync é bloqueado até reautenticação
- Logout definitivo é explícito

---

### 10.2 Princípio da Evolução

A evolução do Auth **NÃO deve**:

- Inferir identidade sem backend
- Permitir sync sem autenticação válida
- Manter dados após soft delete

A evolução **DEVE**:

- Separar “sessão inválida” de “encerramento definitivo”
- Preservar dados locais até decisão explícita
- Permitir recuperação após reautenticação

---

### 10.3 Sessão como Estado

A expiração de token **DEVE** ser tratada como um estado intermediário, e não como logout imediato.

Estado:
- `sessionExpired`

Neste estado:
- Tokens são considerados inválidos
- Novas mutações são bloqueadas
- Dados locais permanecem disponíveis
- Sync fica suspenso até reautenticação

---

### 10.4 Logout em Duas Fases

O logout passará a ocorrer em duas fases:

#### Fase 1 — Sessão Expirada
- Sessão inválida
- Dados preservados
- Change Log preservado
- Usuário deve reautenticar

#### Fase 2 — Encerramento Definitivo
Executada somente quando:
- sync pendente foi concluído **OU**
- usuário confirmou descarte de dados

Ações:
- limpar tokens
- limpar SwiftData
- encerrar sessão local

---

### 10.5 Integração com Sync (Implementado)

- Expiração de sessão **NÃO** apaga dados
- ChangeLog é preservado
- SyncManager é bloqueado enquanto sessão inválida
- Após reautenticação:
  - AuthSession → `authenticated`
  - SyncManager pode executar sync pendente

---

### 10.6 Limites Deliberados

Mesmo após a evolução:

- Sessão inválida **NÃO** permite sync
- Soft delete invalida tudo imediatamente
- Backend continua sendo a única fonte da verdade

---

### 10.7 Regra de Evolução

> **Nenhuma evolução de UX pode violar as garantias de segurança já definidas neste documento.**

---
