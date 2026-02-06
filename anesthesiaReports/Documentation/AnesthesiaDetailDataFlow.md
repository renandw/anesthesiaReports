# AnesthesiaDetailView — Data Flow (Patient, Surgery, Anesthesia)

Este documento descreve **como os dados de Patient, Surgery e Anesthesia são carregados, exibidos e editados** dentro de `AnesthesiaDetailView` e suas views filhas.

## 1) Visão Geral da Arquitetura

A tela é composta por:

- **AnesthesiaDetailView** (pai)
  - controla o estado global (`patient`, `surgery`, `anesthesia`)
  - resolve carregamento inicial (quando dados não foram fornecidos)
  - fornece dados para as seções
- **ContentSectionView** (switch de seção)
  - decide qual seção mostrar
- **IdentificationView** (filha da seção Identificação)
  - exibe dados básicos
  - aciona edições via sheets (PatientForm, SurgeryForm, AnesthesiaForm)
  - atualiza o estado do pai via `@Binding`

## 2) Fonte de Dados (Entrada)

`AnesthesiaDetailView` aceita:

- `surgeryId: String` (sempre obrigatório)
- `initialSurgery: SurgeryDTO?` (opcional)
- `initialAnesthesia: SurgeryAnesthesiaDetailsDTO?` (opcional)

**Uso recomendado:**
- Quando navegar a partir de `SurgeryDetailView`, passe `initialSurgery` e `initialAnesthesia` já carregados.
- Quando navegar de outros lugares, passe apenas `surgeryId` e deixe a tela buscar os dados.

## 3) Carregamento Inicial

Dentro de `AnesthesiaDetailView`:

1. Se `initialSurgery` existe → `surgery = initialSurgery`.
2. Se `initialAnesthesia` existe → `anesthesia = initialAnesthesia`.
3. Se `surgery` ainda for `nil` → busca com `surgerySession.getById(surgeryId)`.
4. Se `anesthesia` ainda for `nil` → busca com `anesthesiaSession.getBySurgery(surgeryId)`.
5. Se `patient` ainda for `nil` → busca com `patientSession.getById(surgery.patientId)`.

Isso evita chamadas duplicadas quando a tela já recebeu os dados.

## 4) Exibição em IdentificationView

`IdentificationView` recebe bindings (`@Binding`) para:

- `patient: PatientDTO?`
- `surgery: SurgeryDTO?`
- `anesthesia: SurgeryAnesthesiaDetailsDTO?`

E renderiza:

- **Paciente:** `patient.name`
- **Cirurgia:** `surgery.proposedProcedure`
- **Início da anestesia:** `anesthesia.startAt`

## 5) Edição (Forms via Sheets)

`IdentificationView` mostra três botões (title bar buttons):

- Editar Paciente → `PatientFormView`
- Editar Cirurgia → `SurgeryFormView`
- Editar Anestesia → `AnesthesiaFormView`

Cada form é aberto com dados existentes:

- `PatientFormView(existing: patient)`
- `SurgeryFormView(existing: surgery)`
- `AnesthesiaFormView(initialAnesthesia: anesthesia)`

## 6) Atualização Após Salvar

Quando o usuário salva em qualquer form:

1. O `onComplete` atualiza o **binding local** (ex.: `self.patient = updated`).
2. Em seguida, `reloadIfPossible()` executa refresh para:
   - `surgerySession.getById`
   - `patientSession.getById`
   - `anesthesiaSession.getBySurgery`

Isso garante que os dados exibidos na tela sejam consistentes com o backend.

## 7) Fluxo de Dependência

- `patient` depende de `surgery.patientId`
- `anesthesia` depende de `surgeryId`

Se `surgery` for nil, não é possível buscar `patient`.

## 8) Comportamento em Caso de Erro

- Erros no carregamento inicial exibem `errorMessage` simples na tela.
- Erros durante `reloadIfPossible()` são ignorados para não interromper o fluxo do usuário.

## 9) Pontos de Extensão

Você pode acrescentar novos dados em `IdentificationView` sem alterar o fluxo:

Exemplos:
- Sexo / idade do paciente
- Convênio da cirurgia
- Status da anestesia

## 10) Resumo do Fluxo

```
SurgeryDetailView → AnesthesiaDetailView
    ↓
(carrega surgery + anesthesia se não fornecido)
    ↓
busca patient
    ↓
IdentificationView mostra dados
    ↓
forms abrem via sheets
    ↓
onComplete atualiza bindings
    ↓
reloadIfPossible refaz fetch
```

---

Este fluxo garante:
- reutilização da tela em múltiplos pontos de navegação
- dados sempre sincronizados
- baixo acoplamento entre view pai e filhos
