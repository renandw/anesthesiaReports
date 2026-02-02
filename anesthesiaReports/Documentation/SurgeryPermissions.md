# Surgery Permissions — Backend & UI

Este documento descreve **como as permissões de cirurgia funcionam no backend** e **como a UI aplica essas regras**. Inclui trechos de código relevantes para referência.

---

## 1) Permissões disponíveis

Permissões válidas em `sharing_surgeries_with_users.permission`:

- `read`
- `pre_editor`
- `ane_editor`
- `srpa_editor`
- `full_editor`
- `owner`

No app, essas permissões são representadas por `SurgeryPermission`.

---

## 2) Regras no backend (fonte da verdade)

### 2.1 Visibilidade (regra de bloqueio)
A cirurgia só é retornada se o usuário tiver:
- share na surgery **e**
- share no patient (`read` ou `write`) **ou** for criador do patient.

Isso está implementado nos `JOIN`s de:
- `getSurgeryById`
- `listSurgeries`
- `listSurgeriesByPatient`

Exemplo (trecho simplificado):
```
JOIN sharing_surgeries_with_users sh
  ON sh.surgery_id = s.surgery_id AND sh.user_id = $userId
JOIN patients p ON p.patient_id = s.patient_id
LEFT JOIN sharing_patients_with_users sp
  ON sp.patient_id = s.patient_id AND sp.user_id = $userId
WHERE (p.created_by = $userId OR sp.permission IN ('read','write'))
```

### 2.2 Atualização
- Qualquer permissão **diferente de `read`** consegue atualizar dados da cirurgia.

### 2.3 Financeiro
- Apenas `owner` pode ver/editar `financial` (ex.: `value_anesthesia`).

### 2.4 Compartilhamento
- Somente `full_editor` ou `owner` podem compartilhar cirurgia.

### 2.5 Cascata (revogação)
- Ao revogar share no patient, todas as shares de surgery daquele patient são removidas para o usuário.

---

## 3) Regras na UI (aplicação no app)

### 3.1 Menu de edição / compartilhar
No `SurgeryDetailView`:

- **Editar** aparece para qualquer permissão diferente de `read`.
- **Compartilhar** aparece apenas para `full_editor` ou `owner`.

Trecho real (UI):
```
if let surgery, canEdit(surgery.resolvedPermission) {
  Menu { ... }
}

private func canEdit(_ permission: SurgeryPermission) -> Bool {
  permission != .read
}
```

### 3.2 Lista de compartilhamentos
A lista “Compartilhado com” só aparece se:

- `permission == full_editor` **ou** `permission == owner`.

Trecho real (UI):
```
if canShare(surgery.resolvedPermission) {
  Section { ... }
}

private func canShare(_ permission: SurgeryPermission) -> Bool {
  permission == .full_editor || permission == .owner
}
```

### 3.3 Tela de compartilhamento
A `CanShareSurgeryWithView` bloqueia alteração de permissão para o owner:

- Se o usuário listado for `createdById`, exibe apenas o ícone.

Trecho real (UI):
```
if isOwner {
  Image(systemName: "checkmark.circle.fill")
} else {
  Menu { ... }
}
```

### 3.4 Financial no formulário
- O campo **Valor anestesia** só aparece para `owner`.
- No update, a UI **não envia** `financial` se o usuário não for `owner`.

Trecho real (UI):
```
if insuranceName.lowercased() == "particular" && canEditFinancial {
  EditRow(label: "Valor anestesia", value: $valueAnesthesia)
}

financial: canEditFinancial
  ? SurgeryFinancialInput(value_anesthesia: valueAnesthesiaDouble)
  : nil
```

---

## 4) Observações importantes

- As permissões `pre_editor`, `ane_editor` e `srpa_editor` **já existem**, mas ainda não há campos específicos no schema para aplicá-las. Hoje, no backend, esses níveis não liberam update.
- A UI reflete essa regra, mostrando opções de permissão mas bloqueando edição real para esses níveis.

---
