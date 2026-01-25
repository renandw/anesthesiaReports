

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

✘ Não existe fila de operações locais  
✘ Alterações offline não são registradas como intenções  
✘ Não há durabilidade formal de mutações  

Necessário para:
- Contrato §4
- Contrato §11

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

✘ Não existe push de alterações locais  
✘ Não há retry controlado  
✘ Não há idempotência no client  

Necessário para:
- Contrato §6.1

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
- Sync baseado em entidades
- `needsSync`, `lastModified`
- Push/Pull incremental

### 4.2 Bordas da Sessão
- Change Log como rede de segurança
- Proteção contra perda de dados
- Nenhum sync sem autenticação válida

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

### 5.2 Fase 2 — Sync Manual
- Detectar pendências após login
- Permitir sync explícito
- Implementar push básico

---

### 5.3 Fase 3 — Sync Automático
- Triggers event‑driven
- Pull incremental
- UX não bloqueante

---

### 5.4 Fase 4 — Robustez
- Retry
- Backoff
- Métricas

---

## 6. Regra de Ouro

> **O SyncEngine nunca deve violar as garantias do Contrato de Sync.**  
> **Sessão define quando sincronizar. Backend define o que é verdade.**

---

## Status

📌 SyncEngine **documentado**, gaps claros e pronto para implementação incremental.