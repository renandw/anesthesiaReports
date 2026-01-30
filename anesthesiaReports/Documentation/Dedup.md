# Dedup — iOS App (Plano de Implementação)

Este documento descreve o plano de implementação do fluxo de deduplicação no app iOS.

---

## ✅ Objetivo
Evitar duplicidade de pacientes sugerindo candidatos antes da criação, sem bloquear autonomia.

---

## ✅ Fluxo esperado (app)
1. Usuário preenche formulário do paciente.
2. Ao tocar em **Salvar**, o app chama `POST /patients/precheck`.
3. Se não houver candidatos → cria normalmente.
4. Se houver candidatos → abre `DuplicatePatientSheet`.
5. Ações no sheet:
   - **Criar novo** → `POST /patients`
   - **Atualizar existente** → `POST /patients/:id/claim` + `PATCH /patients/:id` com dados do form
   - **Usar existente** → `POST /patients/:id/claim` + navega para `PatientDetailView`

---

## ✅ DTOs necessários
- `PrecheckMatchDTO`
  - patient_id
  - patient_name
  - sex
  - date_of_birth
  - cns
  - created_by
  - created_by_name
  - match_level (strong / weak)
  - fingerprint_match (bool)

---

## ✅ API methods (PatientAPI)
- `precheck(input) -> [PrecheckMatchDTO]`
- `claim(patientId) -> Void`

---

## ✅ PatientSession
- Expor `precheck` e `claim`
- Opcional: armazenar últimos candidatos

---

## ✅ UI/UX (PatientFormView)
- Antes de criar, executar precheck.
- Se `matches` vazio → cria paciente.
- Se houver `matches` → mostrar sheet com lista.
- Cada item deve mostrar:
  - Nome
  - Data
  - Sexo
  - CNS (se não placeholder)
  - Badge “Match forte/fraco”

---

## ✅ Navegação
| Ação | Resultado |
|---|---|
| Usar existente | claim + abre Detail |
| Atualizar existente | claim + PATCH |
| Criar novo | POST /patients |

---

## ✅ Observações
- Score interno não é exibido.
- Autonomia total: qualquer match permite claim write.

---

## ✅ UX — Owner no compartilhamento
Quando o paciente é **claimed** por outro usuário, o criador original pode aparecer na lista de compartilhamento.

Decisão: manter o criador visível, porém **sem interação**:
- Exibir ícone de checkmark verde na linha do criador.
- Desabilitar o picker para o criador (sem ações).

---

## ✅ Observação — “Selecionar existente”
O botão **Selecionar existente** será utilizado em uma etapa futura para fluxos adicionais.
No momento, ele apenas executa o `claim` e carrega o paciente para navegação padrão.
