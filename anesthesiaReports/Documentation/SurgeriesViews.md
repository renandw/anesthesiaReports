# Surgeries Views

Este documento resume os ajustes recentes nas telas de cirurgia (iOS), com foco no novo fluxo de `cbhpms` (array) e na melhoria de navegação para listas longas.

## SurgeryFormView

- O formulário passou a trabalhar com `cbhpms` como lista (`[SurgeryCbhpmInput]`), sem compatibilidade com campo legado singular.
- A sheet de CBHPM foi reorganizada para:
  - buscar itens no catálogo (`SurgeryCbhpmSearchView`) e adicionar ao resumo;
  - adicionar item manualmente com `Código`, `Procedimento` e `Porte`;
  - exibir um resumo com itens já adicionados e ação de remover.
- O resumo no formulário principal mostra apenas contagem (`N item(ns)`), evitando poluição visual.
- No submit (create/update), o payload envia `cbhpms` como array (ou `nil` quando vazio), com deduplicação e validação de item manual incompleto.
- Ao editar cirurgia existente, os itens são carregados de `existing.cbhpms`.

## SurgeryDetailView

- A seção `CBHPM` foi simplificada para não crescer demais quando há muitos itens.
- Agora a seção mostra:
  - total de itens (`N item(ns)`);
  - `NavigationLink` para a lista completa.
- Foi adicionada a view dedicada `SurgeryCbhpmsListView`, que lista todos os itens e detalhes:
  - `Código`
  - `Procedimento`
  - `Porte`

## Objetivo de UX

- Reduzir densidade visual no detalhe e no formulário.
- Manter acesso completo aos dados de CBHPM via navegação dedicada.
- Preparar a UI para cirurgias com muitos procedimentos CBHPM sem comprometer legibilidade.
