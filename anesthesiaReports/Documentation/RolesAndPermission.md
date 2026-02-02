# Roles and Permissions (Paciente)

Este documento explica como a UI identifica **papel (role)** e **permissão (permission)** de usuários em pacientes, por que parte disso é **computada no app**, e o que o backend precisaria expor para evitar esses cálculos.

---

## 1) O que vem do backend

A API retorna dois campos principais por paciente:

- `my_permission`: **read | write**
- `my_role`: **owner | editor | shared**

`my_role` é o **papel do usuário autenticado** no paciente.

---

## 2) Por que a UI precisa computar o role em listas de compartilhamento

Na tela **Compartilhado com**, a UI lista *outros usuários* que têm acesso ao paciente.
O backend retorna os shares como:

```
user_id
user_name
permission
granted_by
granted_at
```

Esses dados **não trazem o role pronto** do usuário listado. Por isso, a UI precisa **inferir** o papel daquele usuário com base em:

- `patient.createdBy` (criador do paciente)
- `share.grantedBy` (quem concedeu o acesso)
- `share.userId` (usuário listado)

### Regra de inferência usada

- **owner**: `share.userId == patient.createdBy`
- **editor**: `share.grantedBy == share.userId` (auto‑grant / claim)
- **shared**: qualquer outro caso

Essa regra é necessária porque `my_role` é **apenas do usuário logado**, não dos usuários listados nos shares.

---

## 3) O que deveria existir para evitar a computação no app

Para a UI não precisar deduzir o papel, o backend poderia **explicitar o role** para cada share, por exemplo:

### Opção A — adicionar `role` em cada share

```json
{
  "user_id": "...",
  "user_name": "...",
  "permission": "read",
  "role": "shared",
  "granted_by": "...",
  "granted_at": "..."
}
```

### Opção B — adicionar `share_origin`/`granted_via`

```json
{
  "user_id": "...",
  "permission": "write",
  "granted_via": "claim" | "share"
}
```

Com isso a UI não precisaria inferir `editor` pela regra `granted_by == user_id`.

---

## 4) Resumo rápido

- `my_role` **já vem pronto** do backend, mas **só para o usuário logado**.
- Para listar o papel de outras pessoas no share, a UI precisa inferir.
- Se o backend expuser `role` em shares, a inferência não seria necessária.

---
