# NewSRPAWizardView — Specification

## Objetivo
Criar um fluxo guiado e **obrigatoriamente linear** para registro completo:

1. **Paciente** → 2. **Cirurgia** → 3. **SRPA** → **Detalhes do SRPA**

A view final deverá encaminhar para `SRPADetailView`.

---

## Fluxo Geral (Linear e Obrigatório)

```
Step 1: PatientFormView (Mode.wizard)
  └─ cria/seleciona paciente
       ↓
Step 2: SurgeryFormView (Mode.wizard)
  └─ cria/seleciona cirurgia
       ↓
Step 3: SRPAFormView (Mode.wizard)
  └─ cria SRPA
       ↓
Navigation to SRPADetailView
```

- **Não é permitido pular etapas**.
- Cada etapa só é liberada após conclusão válida da anterior.

---

## Step 1 — PatientFormView

- Usa **exatamente o mesmo fluxo** do `PatientFormView` atual.
- Permite:
  - criação de novo paciente
  - seleção de paciente existente (dedup/claim)
- Deve ser usado com `mode = .wizard`.

### Saída do Step 1
- `selectedPatient: PatientDTO`

---

## Step 2 — SurgeryFormView

- Usa **exatamente o mesmo fluxo** do `SurgeryFormView` atual.
- Permite:
  - criação de nova cirurgia
  - seleção de cirurgia existente (precheck/claim)
- Deve ser usado com `mode = .wizard`.
- Recebe `patientId` vindo do Step 1.

### Saída do Step 2
- `selectedSurgery: SurgeryDTO`

---

## Step 3 — SRPAFormView

- Usa `SRPAFormView` com `mode = .wizard`.
- Recebe `surgeryId` vindo do Step 2.
- Ao salvar, recebe `SurgerySRPADetailsDTO`.

### Saída do Step 3
- `createdSRPA: SurgerySRPADetailsDTO`

---

## Navegação Final

Após o Step 3, navegar para:

```
SRPADetailView(
  surgeryId: selectedSurgery.id,
  initialSurgery: selectedSurgery,
  initialSRPA: createdSRPA
)
```

---

## Modos (.standalone vs .wizard)

Todos os forms já possuem:

```swift
enum Mode {
    case standalone
    case wizard
}
```

Esse wizard **deve sempre utilizar `Mode.wizard`** para:
- manter comportamento acoplado ao fluxo
- evitar ações de cancelamento fora de contexto

---

## Estados Necessários no Wizard

- `currentStep: Int` (1–3)
- `selectedPatient: PatientDTO?`
- `selectedSurgery: SurgeryDTO?`
- `createdSRPA: SurgerySRPADetailsDTO?`

---

## Regras de Transição

- **Step 1 → Step 2:** apenas se `selectedPatient != nil`.
- **Step 2 → Step 3:** apenas se `selectedSurgery != nil`.
- **Finalização:** apenas se `createdSRPA != nil`.

---

## Observações

- O wizard reaproveita todas as regras de dedup/claim já existentes nos forms.
- A experiência do usuário deve ser contínua, sem voltar etapas após concluir.

---

## Possíveis Percalços e Cuidados

1) **Assíncrono / estados parciais**
- Cada step depende do resultado do anterior. Evitar navegação para frente enquanto `create/claim` ainda está pendente.
- Sempre validar se `selectedPatient/selectedSurgery` estão preenchidos antes de renderizar o próximo step.

2) **Dedup / claim**
- Dedup pode retornar múltiplos matches; o usuário pode selecionar ou criar novo.
- O fluxo do wizard deve respeitar as mesmas regras de `PatientFormView` e `SurgeryFormView` para evitar duplicidade.

3) **Permissões**
- Ao selecionar uma cirurgia existente, garantir que a permissão permita editar (`permission != read`).
- Se a permissão for insuficiente, o wizard deve informar e bloquear o avanço.

4) **Mudança de contexto**
- Se o usuário editar o paciente no Step 1 e depois voltar/alterar a cirurgia, evitar inconsistências (ex.: cirurgia de outro paciente).
- O Step 2 deve sempre estar atrelado ao `patientId` do Step 1.

5) **Falhas de rede**
- Se falhar o request em qualquer step, manter o estado do step e permitir retry.
- Não avançar etapa em erro silencioso.

6) **SRPA já existente**
- Se já houver SRPA para a cirurgia selecionada, o Step 3 deve decidir:
  - informar ao usuário que o SRPA já existe (wizard é criação);
  - oferecer botão para navegar para `SRPADetailView`.

7) **Cancelamento**
- Como o fluxo é linear, cancelar no meio deve:
  - confirmar com o usuário;
  - evitar deixar registros “meio criados” sem contexto.

8) **Timing / dates**
- No Step 3, horários inválidos (fim antes de início) geram INVALID_PAYLOAD.
- Validar localmente antes de enviar.

9) **Atualização pós‑wizard**
- Após criar o SRPA, navegar para `SRPADetailView` com dados iniciais,
  e garantir refresh se o usuário editar depois.

10) **Reentrada no wizard**
- Se o usuário iniciar novamente o wizard, limpar estados anteriores (patient/surgery/srpa).

---

## Encaminhamento ao Detalhe (Opção A)

Para evitar o botão “voltar” retornar ao Step 3, a estratégia recomendada é:\n

1. Wizard finaliza e chama `onFinish(surgery, srpa)`.\n
2. Wizard executa `dismiss()` (fecha o sheet do wizard).\n
3. A view pai (ex.: Dashboard) abre `SRPADetailView` em um **sheet separado**.

### Implementação (detalhada)

**No `NewSRPAWizardView`:**

- Adicionar callback opcional:
  ```swift
  let onFinish: ((SurgeryDTO, SurgerySRPADetailsDTO) -> Void)?
  ```
- Criar `init` para permitir instanciar sem callback:
  ```swift
  init(onFinish: ((SurgeryDTO, SurgerySRPADetailsDTO) -> Void)? = nil) {
      self.onFinish = onFinish
  }
  ```
- No Step 3:
  - se o SRPA já existir:
    ```swift
    onFinish?(surgery, existingSRPA)
    dismiss()
    ```
  - se criar SRPA:
    ```swift
    onFinish?(surgery, createdSRPA)
    dismiss()
    ```

**No `DashboardView`:**

- Estados adicionais:
  ```swift
  @State private var showWizard = false
  @State private var showSRPADetail = false
  @State private var wizardSurgery: SurgeryDTO?
  @State private var wizardSRPA: SurgerySRPADetailsDTO?
  ```

- Ao abrir o wizard:
  ```swift
  .sheet(isPresented: $showWizard) {
      NewSRPAWizardView { surgery, srpa in
          wizardSurgery = surgery
          wizardSRPA = srpa
          showWizard = false
          showSRPADetail = true
      }
  }
  ```

- Abrir detalhe em sheet separado:
  ```swift
  .sheet(isPresented: $showSRPADetail) {
      if let surgery = wizardSurgery, let srpa = wizardSRPA {
          SRPADetailView(
              surgeryId: surgery.id,
              initialSurgery: surgery,
              initialSRPA: srpa
          )
      }
  }
  ```

