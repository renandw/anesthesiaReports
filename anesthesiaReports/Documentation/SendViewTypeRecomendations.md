# Send View Type Recommendations

Padrão recomendado para views que enviam dados (create/update/delete/login) com foco em:
- feedback visual claro no botão
- prevenção de múltiplos envios
- redução de risco de `RATE_LIMITED`
- consistência de UX entre telas

## Objetivo

Padronizar um "SendView type" para qualquer tela com submit:
- `LoginView`
- `PatientFormView`
- `SurgeryFormView`
- `EditUserView` / `UserDetailsView`
- outras ações críticas (delete/share/revoke)

## Três Camadas do Padrão

Toda SendView deve tratar explicitamente três camadas:

1. **Payload**
   - normalização dos dados
   - transformação UI -> DTO de API
2. **Validação estrutural**
   - obrigatórios, tipos, ranges e coerência mínima
   - bloqueio de submit inválido com mensagem objetiva
3. **Comportamento visual/estado de envio**
   - estado do botão, feedback e cooldown
   - prevenção de múltiplos envios

## Estado da ação (state machine)

Toda view de envio deve ter um estado explícito:
- `idle`
- `submitting` (ou `authenticating`)
- `success`
- `failure`

Esse estado governa:
- título do botão
- cor do botão
- `disabled`
- feedback de erro/sucesso

## Padrão do botão de envio

- **Idle**
  - texto: ação principal (`Entrar`, `Salvar`, `Criar`, `Excluir`)
  - habilitado somente quando formulário for válido
- **Submitting**
  - texto: `Enviando...` / `Autenticando...`
  - botão desabilitado
  - opcional: `ProgressView` inline
- **Success**
  - texto: `Sucesso`
  - cor verde
  - transição curta para próxima tela ou reset
- **Failure**
  - texto: `Falha` / `Falha no login`
  - cor vermelha
  - mostrar `errorMessage`

## Delete (destrutivo) — recomendação

Quando houver ação de delete, usar o mesmo state machine (idle/submitting/success/failure) com:

- **Idle**: `Excluir ...` (vermelho)
- **Submitting**: `Excluindo...` (vermelho, disabled)
- **Success**: `Excluída` (verde) → fechar tela se `standalone`
- **Failure**: `Falha` (vermelho) + `errorMessage`

Regras:
- Confirmar com `alert` antes do delete.
- Não fechar tela em modo wizard.

## Regras anti-rate-limit

- Sempre bloquear toque duplo com `disabled` enquanto `submitting`.
- No erro `AuthError.rateLimited`:
  - aplicar cooldown local antes de reabilitar submit (mínimo 5s).
  - manter dados úteis já digitados (não limpar tudo).
- Nos demais erros:
  - cooldown curto de UX (1–1.5s) opcional.
- Se backend expor `Retry-After` no futuro, preferir esse valor.

## Payload (orientação de implementação)

- Definir um ponto único de montagem do payload (`buildPayload` / `normalizedInput`).
- Evitar montar payload em múltiplos lugares da mesma view.
- Converter valores de UI para formato de API antes do request:
  - `String` -> `Double` / `Date` / `Array`
  - `""` -> `nil` quando o contrato exigir campo opcional
- Aplicar normalização de domínio antes de enviar:
  - nomes (title case),
  - email (lowercase),
  - listas (trim por item),
  - datas em formato ISO.

## Validação estrutural (orientação de implementação)

- Separar validação em função dedicada (`validateBeforeSubmit`).
- Ordem recomendada:
  1. campos obrigatórios;
  2. formato/tipo (ex.: número válido);
  3. regras de domínio simples (ex.: tamanho mínimo de nome).
- Em erro:
  - definir `errorMessage` claro,
  - aplicar estado visual de falha,
  - não enviar request.
- Sempre manter alinhamento com validação do backend (fonte final de verdade).

## Normalização antes de enviar

Executar normalização no início do submit:
exemplo de dados:
- `email`: trim + lowercase
- campos de nome: `NameFormatHelper.normalizeTitleCase`
- arrays textuais: trim/normalização por item
- números: parse seguro (`"," -> "."` quando necessário)

Evitar alterar senha além de remoção de newline acidental.

## Estratégia de limpeza de campos

Não limpar todos os campos por padrão.
Recomendação:
- limpar apenas campos sensíveis em falha (`password`)
- limpar `email` apenas em cenários específicos de UX (ex.: `userNotRegistered`)
- manter dados já digitados em erros de rede/infra/rate limit

## Mensagens de erro

Usar sempre `AuthError.userMessage` (ou equivalente de domínio).
Objetivo: mensagens consistentes em todas as telas, evitando strings ad-hoc.

## Checklist de implementação por view

1. Criar estado de envio (`idle/submitting/success/failure`).
2. Ligar estado ao botão (texto/cor/disabled).
3. Limpar `errorMessage` no início do submit.
4. Montar payload em ponto único com normalização.
5. Executar validação estrutural antes de chamar session/API.
6. Tratar `AuthError` com cooldown adequado.
7. Evitar múltiplas `Task` simultâneas para o mesmo submit.
8. Em sucesso, navegar/fechar tela de forma previsível.

## Referência atual

`Startup/LoginView.swift` já implementa boa parte desse padrão:
- botão com estado visual
- bloqueio durante autenticação
- normalização de email/senha
- cooldown para `rateLimited`
- limpeza seletiva de campos

`Patient/PatientFormView.swift` e `Surgery/SurgeryFormView.swift` já aplicam:
- feedback visual de submit (`Enviando`, `Sucesso`, `Falha`)
- cooldown visual pós-falha
- bloqueio de múltiplos envios durante submit


## ONLY DATEPICKER
- para datas STRING ISO (YYYY-MM-DD) usar o DateOnlyPickerSheet.swift
- UTC


## SHIMMER

- para estados de loading: usar Helper/Shimmer
