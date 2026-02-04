# Surgeries Views

Estado atual das views de cirurgia (iOS), responsabilidades, problemas identificados e soluções já aplicadas.

## Estado Atual

### SurgeryFormView
- Usa `cbhpms` como array (`[SurgeryCbhpmInput]`) sem campo legado singular.
- Organiza o formulário em blocos: dados básicos, dados da cirurgia, equipe cirúrgica e informações adicionais.
- `type` (`insurance`/`sus`) influencia UX de convênio e hospital.
- `DateOnlyPickerSheet` com correção de timezone para evitar deslocamento de dia.
- Auxiliares via `EditRowArray` (`[String]`) com normalização híbrida (onChange + onSubmit).
- `mainSurgeon` e `hospital` normalizados com `NameFormatHelper` (perda de foco e submit).
- Dedup de cirurgia via precheck + claim (`SurgeryDuplicatePatientSheet`).

### CBHPM no Form
- Busca no catálogo (`SurgeryCbhpmSearchView`) + adição manual.
- Resumo com lista de itens adicionados e remoção individual.
- Envio no payload como array, com deduplicação por `code+procedure+port`.

### SurgeryDetailView
- Seção CBHPM simplificada: total de itens + `NavigationLink` para lista dedicada.
- Ação de excluir cirurgia implementada no menu (com confirmação).

## Responsabilidades da SurgeryFormView

- Capturar e validar dados de criação/edição de cirurgia.
- Adaptar estados de UI para payload de API.
- Aplicar regras de normalização de nomes e auxiliares.
- Executar fluxos de deduplicação (precheck/claim).
- Montar payloads para create/update e submit com controle de erro.

## Problemas de Design/Código (Code Smells)

- `submit()` e `createSurgeryEvenWithDuplicate()` têm alta duplicação de lógica.
- View concentra muita regra de negócio (validação, normalização, dedup, montagem de payload).
- Dependência de strings literais para regra financeira (`"particular"`).
- Listas de convênio/hospitais hardcoded dentro da view.
- Arquivo grande e com muitos estados, dificultando manutenção e testes.

## Soluções Aplicadas

- Migração completa para `cbhpms` array.
- Melhor organização visual do formulário por seções.
- Normalização híbrida de nomes (foco + submit).
- Normalização de `auxiliarySurgeons` como array.
- Correção de timezone no seletor de data.
- UX de CBHPM com busca + resumo + remoção.
- Lista dedicada de CBHPM no detalhe para reduzir poluição visual.
- Botão de exclusão de cirurgia no detalhe com confirmação.

## Próximos Passos Recomendados

- Extrair builder/validator de payload para reduzir lógica na View.
- Unificar e reutilizar validação entre os dois fluxos de submit.
- Centralizar constantes (`"SUS"`, `"particular"`, mensagens e opções de listas).
- Mover catálogos de convênio/hospital para provider/config dedicado.
