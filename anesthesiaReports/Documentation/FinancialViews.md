# Financial Views

Estado atual das telas financeiras no iOS (`FinancialDetailView` e `FinancialFormView`) após atualização para o contrato novo do backend.

## Contrato Atual (Backend)

- Campos usados no app:
  - `value_anesthesia`
  - `value_pre_anesthesia`
  - `glosa_anesthesia_value`
  - `glosa_preanesthesia_value`
  - `taxed_value`
  - `tax_percentage`
  - `final_surgery_value` (derivado no backend)
  - `value_partial_payment`
  - `remaining_value` (derivado no backend)
  - `paid`
  - `payment_date`
  - `notes`
- Campos removidos do fluxo:
  - `billing_date`
  - nomes legados `glosed_*` e `value_partial_paid`

## FinancialDetailView

- Responsável por leitura do agregado financeiro via endpoint dedicado.
- Mostra valores monetários com formatação BRL e fallback `"-"` quando campo ausente.
- Mantém destaque visual por tipo:
  - azul: valores brutos/base
  - vermelho: impostos
  - verde: valor líquido
  - laranja: pendente
- Abre `FinancialFormView` para adicionar/editar quando permissão permite (`owner`/`full_editor`).
- Em `404/notFound`, considera financeiro inexistente e exibe estado vazio (não trata como erro fatal).

## FinancialFormView

- Responsável por criar/atualizar/excluir financeiro.
- Fluxo de envio segue padrão de send view:
  - estados visuais: `idle`, `submitting`, `success`, `failure`
  - cooldown visual em falha (maior para rate limit)
  - bloqueio de múltiplos submits durante envio
- Validação local:
  - numéricos não negativos
  - `tax_percentage <= 100`
  - quando `paid = true`, `payment_date` obrigatório
  - `value_partial_payment <= final_surgery_value` (prévia local)
- Prévia local segue a lógica do backend:
  - base = (anestesia - glosas) + (pré - glosas)
  - imposto por `%` ou `valor` (sincronização bidirecional)
  - final = base - imposto
  - pendente:
    - `paid = false` -> final
    - `paid = true` e `value_partial_payment` vazio/`0` -> `0` (pagamento total)
    - `paid = true` com valor > 0 -> `final - value_partial_payment`

## Observações de Arquitetura

- `FinancialAPI` e `FinancialService` estão dedicados ao agregado financeiro (`/surgeries/:id/financial`).
- DTOs financeiros em `DTO/SurgeryDTO/SurgeryDTO.swift` usam somente nomenclatura nova.
- A view não recalcula regra de negócio final no servidor; a API continua como fonte da verdade.
