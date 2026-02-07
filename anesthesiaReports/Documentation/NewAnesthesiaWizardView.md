# NewAnesthesiaWizardView — Specification

## Objetivo
Criar um fluxo guiado e **obrigatoriamente linear** para registro completo:

1. **Paciente** → 2. **Cirurgia** → 3. **Anestesia** → **Detalhes da Anestesia**

A view final deverá encaminhar para `AnesthesiaDetailView`.

---

## Fluxo Geral (Linear e Obrigatório)

```
Step 1: PatientFormView (Mode.wizard)
  └─ cria/seleciona paciente
       ↓
Step 2: SurgeryFormView (Mode.wizard)
  └─ cria/seleciona cirurgia
       ↓
Step 3: AnesthesiaFormView (Mode.wizard)
  └─ cria anestesia
       ↓
Navigation to AnesthesiaDetailView
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

## Step 3 — AnesthesiaFormView

- Usa `AnesthesiaFormView` com `mode = .wizard`.
- Recebe `surgeryId` vindo do Step 2.
- Ao salvar, recebe `SurgeryAnesthesiaDetailsDTO`.

### Saída do Step 3
- `createdAnesthesia: SurgeryAnesthesiaDetailsDTO`

---

## Navegação Final

Após o Step 3, navegar para:

```
AnesthesiaDetailView(
  surgeryId: selectedSurgery.id,
  initialSurgery: selectedSurgery,
  initialAnesthesia: createdAnesthesia
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
- `createdAnesthesia: SurgeryAnesthesiaDetailsDTO?`

---

## Regras de Transição

- **Step 1 → Step 2:** apenas se `selectedPatient != nil`.
- **Step 2 → Step 3:** apenas se `selectedSurgery != nil`.
- **Finalização:** apenas se `createdAnesthesia != nil`.

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

6) **Anesthesia já existente**
- Se já houver anestesia para a cirurgia selecionada, o Step 3 deve decidir:
  - informar ao usuário que a anestesia já existe (wizard é criação);
  - oferecer botão para navegar para `AnesthesiaDetailView`.

7) **Cancelamento**
- Como o fluxo é linear, cancelar no meio deve:
  - confirmar com o usuário;
  - evitar deixar registros “meio criados” sem contexto.

8) **Timing / dates**
- No Step 3, horários inválidos (fim antes de início) geram INVALID_PAYLOAD.
- Validar localmente antes de enviar.

9) **Atualização pós‑wizard**
- Após criar a anestesia, navegar para `AnesthesiaDetailView` com dados iniciais,
  e garantir refresh se o usuário editar depois.

10) **Reentrada no wizard**
- Se o usuário iniciar novamente o wizard, limpar estados anteriores (patient/surgery/anesthesia).

---

## Encaminhamento ao Detalhe (Opção A)

Para evitar o botão “voltar” retornar ao Step 3, a estratégia recomendada é:\n

1. Wizard finaliza e chama `onFinish(surgery, anesthesia)`.\n
2. Wizard executa `dismiss()` (fecha o sheet do wizard).\n
3. A view pai (ex.: Dashboard) abre `AnesthesiaDetailView` em um **sheet separado**.

Isso garante que o detalhe não fique dentro do stack do wizard.

### Implementação (detalhada)

**No `NewAnesthesiaWizardView`:**

- Adicionar callback opcional:
  ```swift
  let onFinish: ((SurgeryDTO, SurgeryAnesthesiaDetailsDTO) -> Void)?
  ```
- Criar `init` para permitir instanciar sem callback:
  ```swift
  init(onFinish: ((SurgeryDTO, SurgeryAnesthesiaDetailsDTO) -> Void)? = nil) {
      self.onFinish = onFinish
  }
  ```
- No Step 3:
  - se a anestesia já existir:
    ```swift
    onFinish?(surgery, existingAnesthesia)
    dismiss()
    ```
  - se criar anestesia:
    ```swift
    onFinish?(surgery, createdAnesthesia)
    dismiss()
    ```

**No `DashboardView`:**

- Estados adicionais:
  ```swift
  @State private var showWizard = false
  @State private var showAnesthesiaDetail = false
  @State private var wizardSurgery: SurgeryDTO?
  @State private var wizardAnesthesia: SurgeryAnesthesiaDetailsDTO?
  ```

- Ao abrir o wizard:
  ```swift
  .sheet(isPresented: $showWizard) {
      NewAnesthesiaWizardView { surgery, anesthesia in
          wizardSurgery = surgery
          wizardAnesthesia = anesthesia
          showWizard = false
          showAnesthesiaDetail = true
      }
  }
  ```

- Abrir detalhe em sheet separado:
  ```swift
  .sheet(isPresented: $showAnesthesiaDetail) {
      if let surgery = wizardSurgery, let anesthesia = wizardAnesthesia {
          AnesthesiaDetailView(
              surgeryId: surgery.id,
              initialSurgery: surgery,
              initialAnesthesia: anesthesia
          )
      }
  }
  ```

Com isso, o detalhe não fica preso no stack do wizard e o botão “voltar” não retorna ao Step 3.

### Ajuste adicional (evitar sheet vazio)

Para evitar o detalhe abrir “vazio” por timing (dados ainda nil), use `sheet(item:)` com um payload único.

**No `DashboardView`:**

```swift
@State private var wizardAnesthesiaResult: WizardAnesthesiaResult?

struct WizardAnesthesiaResult: Identifiable {
    let id = UUID()
    let surgery: SurgeryDTO
    let anesthesia: SurgeryAnesthesiaDetailsDTO
}

.sheet(item: $wizardAnesthesiaResult) { result in
    AnesthesiaDetailView(
        surgeryId: result.surgery.id,
        initialSurgery: result.surgery,
        initialAnesthesia: result.anesthesia
    )
}
```

**Quando o wizard finaliza:**

```swift
NewAnesthesiaWizardView { surgery, anesthesia in
    wizardAnesthesiaResult = WizardAnesthesiaResult(surgery: surgery, anesthesia: anesthesia)
    showWizard = false
}
```

Assim, o detalhe só abre quando ambos os dados existem.

---

## Ajustes necessários nos FormViews (para Wizard)

1) **PatientFormView**
- Garantir que `Mode.wizard` não feche a tela pai automaticamente.
- Expôr callback de `onComplete` como gatilho de avanço do wizard.
- Manter dedup/claim idênticos ao modo standalone.

2) **SurgeryFormView**
- Garantir que `Mode.wizard` use o `patientId` recebido do Step 1 e não permita trocar.
- Expôr callback de `onComplete` como gatilho de avanço do wizard.
- Manter dedup/claim idênticos ao modo standalone.

3) **AnesthesiaFormView**
- Garantir que `Mode.wizard` não permita “salvar e sair” de forma isolada.
- Após criação bem‑sucedida, deve disparar `onComplete` para finalizar o wizard.
- Se já existir anestesia para a cirurgia, o wizard deve bloquear e oferecer link para `AnesthesiaDetailView`.

---

## Resumo

`NewAnesthesiaWizardView` é um **orquestrador** que reaproveita:

- `PatientFormView (Mode.wizard)`
- `SurgeryFormView (Mode.wizard)`
- `AnesthesiaFormView (Mode.wizard)`

E termina em:

- `AnesthesiaDetailView`
