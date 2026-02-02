# Patient API — FSD (iOS)

## Objetivo
Documentar o uso real da API de pacientes pelo app iOS (contrato esperado, campos e regras de UI).

---

## Base URL
```txt
http://localhost:7362
```

---

## Autenticação
Todas as rotas requerem `Authorization: Bearer <access_token>`.

---

## Conceitos essenciais

### `my_permission`
Permissão efetiva do **usuário autenticado** no paciente.

- `write`: pode editar, excluir e compartilhar
- `read`: apenas visualiza
- `null/ausente`: sem acesso (não deve acontecer nos endpoints listados)

### `my_role`
Origem do acesso do **usuário autenticado** no paciente.

- `owner`: criou o paciente (`created_by`)
- `editor`: obteve `write` via auto‑grant/claim (`granted_by == user_id`)
- `shared`: acesso concedido por outro usuário

> **Observação:** `my_role` é **apenas do usuário logado**. Para exibir o papel de terceiros em “Compartilhado com”, a UI precisa inferir (ver seção específica abaixo).

---

## Endpoints usados pelo app (com exemplos)

### 1) Listar pacientes (meus + compartilhados)
**GET `/patients`**

**Query params:**
```
search=<nome_parcial>
```

**Exemplo de resposta (200):**
```json
{
  "patients": [
    {
      "patient_id": "uuid",
      "patient_name": "Nome",
      "sex": "female",
      "date_of_birth": "1991-02-14",
      "fingerprint": "sha256",
      "cns": "000000000000000",
      "my_permission": "read",
      "my_role": "shared",
      "created_by": "uuid",
      "created_by_name": "Nome do usuário",
      "created_at": "...",
      "updated_by": "uuid",
      "updated_by_name": "Nome do usuário",
      "updated_at": "...",
      "last_activity_at": "...",
      "last_activity_by": "uuid",
      "last_activity_by_name": "Nome do usuário",
      "deleted_at": null,
      "deleted_by": null,
      "deleted_by_name": null,
      "is_deleted": false,
      "version": 1,
      "sync_status": "dirty",
      "last_sync_at": null
    }
  ]
}
```

**Uso no app:**
- Lista principal de pacientes
- Mostra `my_role` (badge) e usa `my_permission` para ações

---

### 2) Listar pacientes compartilhados comigo
**GET `/patients/shared-with-me`**

**Query params:**
```
search=<nome_parcial>
```

**Exemplo de resposta (200):**
```json
{
  "patients": [
    {
      "patient_id": "uuid",
      "patient_name": "Nome",
      "sex": "female",
      "date_of_birth": "1991-02-14",
      "fingerprint": "sha256",
      "cns": "000000000000000",
      "my_permission": "read",
      "my_role": "shared",
      "created_by": "uuid",
      "created_by_name": "Nome do usuário",
      "created_at": "...",
      "updated_by": "uuid",
      "updated_by_name": "Nome do usuário",
      "updated_at": "...",
      "last_activity_at": "...",
      "last_activity_by": "uuid",
      "last_activity_by_name": "Nome do usuário",
      "deleted_at": null,
      "deleted_by": null,
      "deleted_by_name": null,
      "is_deleted": false,
      "version": 1,
      "sync_status": "dirty",
      "last_sync_at": null
    }
  ]
}
```

**Uso no app:**
- Aba/lista “Compartilhados comigo”
- `my_role` normalmente será `shared` ou `editor`

---

### 3) Listar pacientes compartilhados por mim
**GET `/patients/shared-by-me`**

**Query params:**
```
search=<nome_parcial>
```

**Exemplo de resposta (200):**
```json
{
  "patients": [
    {
      "patient_id": "uuid",
      "patient_name": "Nome",
      "sex": "female",
      "date_of_birth": "1991-02-14",
      "fingerprint": "sha256",
      "cns": "000000000000000",
      "my_permission": "write",
      "my_role": "owner",
      "created_by": "uuid",
      "created_by_name": "Nome do usuário",
      "created_at": "...",
      "updated_by": "uuid",
      "updated_by_name": "Nome do usuário",
      "updated_at": "...",
      "last_activity_at": "...",
      "last_activity_by": "uuid",
      "last_activity_by_name": "Nome do usuário",
      "deleted_at": null,
      "deleted_by": null,
      "deleted_by_name": null,
      "is_deleted": false,
      "version": 1,
      "sync_status": "dirty",
      "last_sync_at": null
    }
  ]
}
```

**Uso no app:**
- Aba/lista “Compartilhados por mim”
- `my_role` normalmente será `owner`

---

### 4) Detalhar paciente
**GET `/patients/:patientId`**

**Exemplo de resposta (200):**
```json
{
  "patient": {
    "patient_id": "uuid",
    "patient_name": "Nome",
    "sex": "female",
    "date_of_birth": "1991-02-14",
    "fingerprint": "sha256",
    "cns": "000000000000000",
    "my_permission": "write",
    "my_role": "owner",
    "created_by": "uuid",
    "created_by_name": "Nome do usuário",
    "created_at": "...",
    "updated_by": "uuid",
    "updated_by_name": "Nome do usuário",
    "updated_at": "...",
    "last_activity_at": "...",
    "last_activity_by": "uuid",
    "last_activity_by_name": "Nome do usuário",
    "deleted_at": null,
    "deleted_by": null,
    "deleted_by_name": null,
    "is_deleted": false,
    "version": 1,
    "sync_status": "dirty",
    "last_sync_at": null
  }
}
```

**Uso no app:**
- Tela de detalhe
- `my_permission` controla botões de editar/excluir/compartilhar
- `my_role` exibido como badge “Criador/Editor/Compartilhado”

---

### 5) Criar paciente
**POST `/patients`**

**Body:**
```json
{
  "patient_name": "Nome",
  "sex": "male",
  "date_of_birth": "1991-02-14",
  "cns": "000000000000000"
}
```

**Exemplo de resposta (201):**
```json
{
  "patient": {
    "patient_id": "uuid",
    "patient_name": "Nome",
    "sex": "male",
    "date_of_birth": "1991-02-14",
    "fingerprint": "sha256",
    "cns": "000000000000000",
    "my_permission": "write",
    "my_role": "owner",
    "created_by": "uuid",
    "created_by_name": "Nome do usuário",
    "created_at": "...",
    "updated_by": "uuid",
    "updated_by_name": "Nome do usuário",
    "updated_at": "...",
    "last_activity_at": "...",
    "last_activity_by": "uuid",
    "last_activity_by_name": "Nome do usuário",
    "deleted_at": null,
    "deleted_by": null,
    "deleted_by_name": null,
    "is_deleted": false,
    "version": 1,
    "sync_status": "dirty",
    "last_sync_at": null
  }
}
```

**Uso no app:**
- Formulário de criação
- Resposta já vem com `my_permission = write` e `my_role = owner`

---

### 6) Atualizar paciente
**PATCH `/patients/:patientId`**

**Body parcial:**
```json
{
  "patient_name": "Novo nome",
  "sex": "female",
  "date_of_birth": "1991-02-14",
  "cns": "000000000000000"
}
```

**Exemplo de resposta (200):**
```json
{
  "patient": {
    "patient_id": "uuid",
    "patient_name": "Novo nome",
    "sex": "female",
    "date_of_birth": "1991-02-14",
    "fingerprint": "sha256",
    "cns": "000000000000000",
    "my_permission": "write",
    "my_role": "owner",
    "created_by": "uuid",
    "created_by_name": "Nome do usuário",
    "created_at": "...",
    "updated_by": "uuid",
    "updated_by_name": "Nome do usuário",
    "updated_at": "...",
    "last_activity_at": "...",
    "last_activity_by": "uuid",
    "last_activity_by_name": "Nome do usuário",
    "deleted_at": null,
    "deleted_by": null,
    "deleted_by_name": null,
    "is_deleted": false,
    "version": 2,
    "sync_status": "dirty",
    "last_sync_at": null
  }
}
```

**Uso no app:**
- Formulário de edição
- Só permitido se `my_permission == write`

---

### 7) Deletar paciente (soft delete)
**DELETE `/patients/:patientId`**

**Resposta:** `204 No Content`

**Uso no app:**
- Ação “Excluir”
- Só permitido se `my_permission == write`

---

### 8) Precheck de duplicidade
**POST `/patients/precheck`**

**Body:**
```json
{
  "patient_name": "Nome",
  "sex": "male",
  "date_of_birth": "1991-02-14",
  "cns": "000000000000000"
}
```

**Exemplo de resposta (200):**
```json
{
  "matches": [
    {
      "patient_id": "uuid",
      "patient_name": "Nome",
      "sex": "male",
      "date_of_birth": "1991-02-14",
      "cns": "000000000000000",
      "created_by": "uuid",
      "created_by_name": "Nome do usuário",
      "fingerprint_match": true,
      "name_similarity": 0.982,
      "date_score": 35,
      "cns_distance": 0,
      "score": 100,
      "match_level": "strong"
    }
  ]
}
```

**Uso no app:**
- Antes de criar, consulta duplicados
- Retorna lista de candidatos com `match_level` e score interno

---

### 9) Auto‑grant (claim)
**POST `/patients/:patientId/claim`**

**Resposta:** `204 No Content`

**Uso no app:**
- Quando usuário escolhe “Usar existente” no dedup
- Concede `write` imediato ao usuário (sem aprovação)

---

### 10) Listar compartilhamentos do paciente
**GET `/patients/:patientId/share`**

**Exemplo de resposta (200):**
```json
{
  "shares": [
    {
      "user_id": "uuid",
      "user_name": "Nome do usuário",
      "permission": "read",
      "granted_by": "uuid",
      "granted_at": "..."
    }
  ]
}
```

**Uso no app:**
- Tela “Compartilhado com”
- Só permitido se `my_permission == write`

**Importante:** esta resposta **NÃO** retorna `my_role`.

---

### 11) Conceder/atualizar compartilhamento
**POST `/patients/:patientId/share`**

**Body:**
```json
{
  "user_id": "uuid",
  "permission": "read"
}
```

**Resposta:** `204 No Content`

**Uso no app:**
- Ação de compartilhar com usuário
- `permission`: `read` | `write`

---

### 12) Atualizar permissão
**PATCH `/patients/:patientId/share/:userId`**

**Body:**
```json
{
  "user_id": "uuid",
  "permission": "write"
}
```

**Resposta:** `204 No Content`

**Uso no app:**
- Upgrade/downgrade de permissão

---

### 13) Revogar acesso
**DELETE `/patients/:patientId/share/:userId`**

**Resposta:** `204 No Content`

**Uso no app:**
- Ação “Revogar acesso” na tela de compartilhamento

---

## APIs que NÃO retornam `my_role`

- `GET /patients/:patientId/share` (retorna apenas shares)
- `POST /patients/:patientId/share`
- `PATCH /patients/:patientId/share/:userId`
- `DELETE /patients/:patientId/share/:userId`
- `POST /patients/:patientId/claim`
- `POST /patients/precheck`
- `DELETE /patients/:patientId`

> Essas rotas não retornam `patient` no payload, então não há `my_role`.

---

## Regras de UI derivadas

### Ações por permissão
- `write`: editar, compartilhar e excluir habilitados
- `read`: apenas visualizar

### Badge por role (usuário autenticado)
- `owner`: Criador
- `editor`: Editor (auto‑grant/claim)
- `shared`: Compartilhado

---

## Role dos usuários em “Compartilhado com”

O backend **não retorna role por share**. Para mostrar o papel de terceiros, a UI infere:

- **owner:** `share.userId == patient.createdBy`
- **editor:** `share.grantedBy == share.userId`
- **shared:** caso contrário

Esse cálculo é necessário porque `my_role` só vale para o usuário autenticado.

---
