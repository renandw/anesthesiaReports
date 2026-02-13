# Validações e Helpers — Padrões do App

Este documento consolida **a abordagem atual**, críticas e um plano de evolução para validações no app.

---

## ✅ Estado atual (implementado)
- Validações feitas localmente em `RegisterView` e `UserDetailsView`.
- Erros aparecem **por campo**, apenas após o campo perder foco (blur).
- `showValidationErrors` + `touchedFields` controlam quando exibir mensagens.
- Ao tentar salvar, todos os campos são marcados como tocados.
- Normalizações no blur:
  - Nome → `NameFormatHelper.normalizeTitleCase`
  - E‑mail → trim + lowercase
  - CRM → uppercase
- Telefone é formatado visualmente, mas enviado somente com dígitos.

---

## ✅ Regras implementadas
- Nome: 2 palavras, 3 letras cada.
- E‑mail: regex simples (`nome@dominio.com`).
- Senha: mínimo 8 caracteres (Register).
- CRM: formato `0000-UF`.
- Telefone: 11 dígitos.
- Empresas: pelo menos 1 (Register).

---

## ✅ Validações por tipo

### Nome de pessoa
- **Obrigatório**
- Deve ter **pelo menos 2 palavras**
- Normalização: capitalizar palavras, mantendo partículas em minúsculo (`de`, `da`, `do`, `das`, `dos`, `e`)
- Helper: `NameFormatHelper`

### Sexo
- Campo obrigatório (não pode ser `nil`)
- Enum: `Sex`

### CNS
- Somente números
- Exatamente **15 dígitos**
- Placeholder permitido: `"000000000000000"`

### Data (YYYY‑MM‑DD)
- Obrigatória quando exigida pelo backend
- Deve ser validada via `DateFormatterHelper.normalizeISODateString`

---

## ✅ FocusState

Para inputs de texto:
- Usar `@FocusState` para aplicar normalizações no **blur** (quando sai do campo).
- Exemplo usado em `PatientFormView`.

---

## ✅ Helpers recomendados

### `DateOnlyPickerSheet`
Usar sempre que o backend exigir `yyyy-MM-dd`.
Evita problemas de fuso horário e input inválido.

### `NameFormatHelper`
Usar em campos que recebem nomes ou títulos:
- `patientName`
- `proposedSurgery`
- `realizedSurgery`
- `mainSurgeon`
- `auxiliarySurgeon`

---

## ⚠️ Críticas / limitações
- Regex de e‑mail é simples e pode aceitar falsos positivos.
- CRM fixo em 4 dígitos pode não cobrir todos os formatos reais.
- Telefone exige 11 dígitos (não cobre fixo com 10).
- `touchedFields` não cobre fluxos sem foco (ex: seleção de empresa) sem evento explícito.
- Validações duplicadas por view (não centralizadas).

---

## ✅ Plano de melhoria — `ValidationHelper`

### Objetivo
Centralizar regras e mensagens para reduzir duplicação e garantir consistência.

### Responsabilidades sugeridas
- Validar campos comuns:
  - `isValidName`, `isValidEmail`, `isValidPhone`, `isValidCRM`, `isValidCNS`
- Retornar **mensagens padronizadas** por tipo.
- Definir **regexs oficiais** para CRM/e‑mail.
- Suportar **telefone 10 ou 11 dígitos**.

### API sugerida (conceitual)
- `ValidationHelper.validateName(_:) -> ValidationResult`
- `ValidationHelper.validateEmail(_:) -> ValidationResult`
- `ValidationHelper.validatePhone(_:) -> ValidationResult`
- `ValidationHelper.validateCRM(_:) -> ValidationResult`

Onde:
- `ValidationResult` contém `isValid` + `message`.

### Benefícios
- Menos validação duplicada em views.
- Mensagens consistentes no app.
- Evolução fácil das regras sem tocar em múltiplas telas.



codex resume 019c1bea-6a31-77a1-8d15-4e18a836a31b
