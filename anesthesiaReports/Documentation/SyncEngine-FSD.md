# SyncEngine — FSD (iOS)

Este documento descreve o **estado atual**, os **gaps existentes** e o **planejamento de evolução** do mecanismo de sincronização do app iOS, em conformidade com o **Contrato de Sync Mobile — Offline‑First (Event‑Driven)**.

---

## 1. Escopo do SyncEngine

O SyncEngine é responsável por:
- coordenar sincronização de dados
- respeitar o estado da sessão
- garantir que nenhuma alteração local seja perdida
- **não** decidir autenticação, logout ou invalidação

O SyncEngine **NÃO**:
- gerencia tokens
- decide estado de sessão
- executa logout
- resolve conflitos por conta própria

---

## 2. Estado Atual do App (O que já existe)

### 2.1 Fonte da Verdade

✔ Backend já é a única fonte da verdade  
✔ `/users/me` fornece `status_changed_at`  
✔ Soft delete é definitivo  

Compatível com:
- Contrato §1
- Contrato §2

---

### 2.2 Estado Local Persistido

✔ Existe `SyncState` em SwiftData  
Campos existentes:
- `lastSyncAt`
- `lastStatusChangedAt`

Compatível com:
- Contrato §3

---

### 2.3 Controle de Sessão

✔ Sessão tratada como estado (`authenticated`, `sessionExpired`, `unauthenticated`)  
✔ Expiração de token **não apaga dados**  
✔ Logout destrutivo é explícito  

Compatível com:
- Contrato §9

---

### 2.4 Persistência Local

✔ SwiftData já é utilizado como storage local  
✔ Dados sobrevivem a offline longo  
✔ Dados só são apagados em logout definitivo  

Compatível com:
- Contrato §10

---

### 2.5 HTTP / Auth Integration

✔ HTTPClient respeita sessão expirada  
✔ Refresh é tentado uma única vez  
✔ Falha de refresh gera `sessionExpired`  

Compatível com:
- Contrato §5
- Contrato §6 (parcial)

---

## 3. Gaps Atuais (O que ainda NÃO existe)

### 3.1 Local Change Log

✔ Existe `LocalChangeLog` persistido em SwiftData  
✔ Alterações locais são registradas como **intenções duráveis**  
✔ Criação de ChangeLog é centralizada em `ChangeLogFactory`  
✔ Entidades **singleton** (ex: `User`) são **deduplicadas**  
✔ Entidades de **coleção** acumulam operações  
✔ Change Log é a fonte da verdade local para upload  

Regras atuais:
- Singleton + update → 1 ChangeLog por `entityId` (last‑write‑wins)
- Coleção → múltiplos ChangeLogs (ordem preservada)
- Delete → sempre gera nova intenção

Compatível com:
- Contrato §4
- Contrato §11

### 3.1.1 ChangeLogFactory (Implementado)

O app utiliza uma `ChangeLogFactory` como ponto único de criação de intenções locais.

Responsabilidades:
- Classificar entidades como **singleton** ou **coleção**
- Deduplicar updates de entidades singleton
- Garantir consistência semântica do Change Log
- Evitar lógica de sync espalhada nas Views

A View **não cria** `LocalChangeLog` diretamente.
Ela apenas expressa a intenção de mutação.

---

### 3.2 Triggers de Sync

✘ Nenhum trigger automático de sync  
✘ Nenhuma reação a:
- foreground
- reconexão
- mutação local  

Necessário para:
- Contrato §5

---

### 3.3 Upload de Alterações (Push)

✔ Push manual de alterações implementado (via SyncManager)  
✔ Upload baseado em Change Log  
✔ Limpeza do Change Log após sucesso  
✔ Upload atualmente implementado apenas para o domínio `User`

✘ Retry automático ainda não implementado  
✘ Idempotência no client ainda não implementada  

Necessário para:
- Contrato §6.1

#### 3.3.1 Disciplina de Actor (Implementado)

O SyncEngine respeita as seguintes regras de concorrência:

- Acesso ao SwiftData (`fetch`, `insert`, `delete`) ocorre exclusivamente no `MainActor`
- Payloads de rede são extraídos como tipos `Sendable`
- Requests HTTP ocorrem fora do `MainActor`
- Reconciliação local e limpeza do Change Log retornam ao `MainActor`

Essas regras evitam violações de `Sendable` e garantem consistência do banco local.

---

### 3.4 Sync Incremental (Pull)

✘ Não existe pull incremental por `last_sync_at`  
✘ Dados locais não são reconciliados  

Necessário para:
- Contrato §6.2

---

### 3.5 Tratamento de Conflitos

✘ Nenhuma política de conflito implementada  
✘ Nenhuma comparação por `updated_at`  

Necessário para:
- Contrato §7

---

## 4. Modelo Híbrido (Planejado)

O app adotará um **modelo híbrido**:

### 4.1 Durante Sessão Válida

- Mutação local sempre grava no SwiftData
- Cada mutação gera um `LocalChangeLog`
- Upload ocorre apenas com sessão válida
- Sync pode ser manual ou automático (event‑driven)
- Deduplicação de ChangeLog aplicada conforme tipo da entidade

### 4.2 Bordas da Sessão

- Change Log preserva intenções durante offline ou sessão expirada
- Nenhuma mutação é descartada automaticamente
- Sync só ocorre após reautenticação válida
- Durante `sessionExpired`, novas mutações locais são bloqueadas

Compatível com:
- Contrato §4.1

---

## 5. Planejamento de Implementação

### 5.1 Fase 1 — Fundação
- Criar `LocalChangeLog` em SwiftData
- Registrar create/update/delete
- Bloquear mutações em `sessionExpired`
- NÃO implementar sync automático

---

### 5.2 Fase 2 — Sync Manual (CONCLUÍDA)

- Change Log consumido explicitamente via SyncManager
- Botão de sync manual no Dashboard
- Upload real ao backend com confirmação explícita
- Limpeza segura do Change Log

---

### 5.3 Fase 3 — Sync Automático (Planejado)

O SyncEngine passará a tentar sincronização automática nos seguintes eventos:

- App entra em foreground
- Conectividade é restabelecida
- Nova mutação local é registrada
- Login bem‑sucedido

Regras:
- Sync nunca bloqueia UI
- Falhas não causam logout
- Change Log nunca é apagado sem confirmação do backend

### 5.3.1 Downloads Automáticos (Pull Incremental)

Após upload bem‑sucedido:
- baixar alterações remotas desde `lastSyncAt`
- reconciliar dados locais
- backend prevalece em conflitos

### 5.4 Fase 4 — Robustez
- Retry
- Backoff
- Métricas

---

## 6. Uso de SyncState (Planejado e Existente)

Estado atual:
- `SyncState` ainda não é usado ativamente pelo SyncEngine
- Campos existem e são persistidos, mas não participam do fluxo de push/pull

O `SyncState` já existe no app e será utilizado como controle oficial de progresso de sincronização.

Para cada `SyncScope` (ex: `user`, `patient`, `surgery`):

- `lastSyncAt` indica o último sync bem‑sucedido
- `lastStatusChangedAt` indica a última invalidação global

Planejamento de uso:
- `lastStatusChangedAt` invalida todo o banco local do escopo
- `lastSyncAt` define o ponto de corte para pull incremental
- SyncState nunca é inferido, apenas atualizado após sucesso

## 7. Padrão para Outros @Models

Cada novo domínio sincronizável deve seguir o mesmo padrão:

- Persistência local via SwiftData
- Mutação local passa obrigatoriamente pela `ChangeLogFactory`
- Entidades singleton → deduplicação por `entityId`
- Entidades de coleção → acumulação de ChangeLogs
- Upload baseado em Change Log
- Reconciliação via `updated_at`
- Controle de progresso via `SyncState` por escopo

Esse padrão garante:
- Offline‑first real
- Não perda de dados
- Escalabilidade do SyncEngine

---

## 8. Regra de Ouro

> **O SyncEngine nunca deve violar as garantias do Contrato de Sync.**  
> **Sessão define quando sincronizar. Backend define o que é verdade.**

---

## Status

✅ Change Log implementado  
✅ Sync manual funcional  
📌 Sync automático e pull incremental planejados  
📌 SyncEngine pronto para escalar para múltiplos domínios