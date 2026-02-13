# PreanesthesiaFormView.md

## 1) Payload (o que vai para o backend)

O formulário envia um payload **único** para `/preanesthesia` (create/patch), com foco em **itens clínicos genéricos** (`items`) e alguns campos estruturados (ASA, técnicas, clearance etc.).

### Campos principais
- **ASA**: usa `asa_raw` (string), vindo do `AsaPickerView`.
- **Técnicas anestésicas**: enviados como `anesthesia_techniques` (via `AnesthesiaTechniquePickerView`).
- **Clearance**: enviado como `clearance` com `status` e `items`.
- **Itens genéricos (`items`)**: comorbidades, cirurgia prévia, airway, ambiente, exames, exame físico, medicações etc.

### Formato de cada item genérico
```
{
  "domain": "<domain>",
  "category": "<category>",
  "code": "<code>",
  "is_custom": false,
  "custom_label": null,
  "details": "texto livre"
}
```

Regras importantes:
- `domain`, `category`, `code` são **obrigatórios**.
- `is_custom = true` exige `custom_label`.
- `details` é opcional.
- O backend **substitui todos os itens** a cada PATCH (delete + insert).

---

## 2) Estrutura das seções do formulário

Cada `NavigationLink` abre uma seção em tela própria com `Form`:

1. **Comorbidades** (`PreanesthesiaComorbiditiesSection`)
   - Domain: `comorbidity`
   - Categorias: cardiovascular, respiratory, neuro, endocrine, etc.
   - UI: toggle por categoria + checklist + custom

2. **Histórico Cirúrgico** (`PreanesthesiaSurgeryHistorySection`)
   - Domain: `surgery_history`
   - Categorias: general (e futuras)
   - UI: igual à comorbidades (DomainSection)

3. **Histórico Anestésico** (`PreanesthesiaAnesthesiaHistorySection`)
   - Domain: `anesthesia_history`
   - UI: checklist com detalhes

4. **Avaliação Via Aérea** (`PreanesthesiaAirwaySection`)
   - Domain: `airway`
   - Mallampati: **picker segmentado** (1 opção)
   - Preditores: DomainSection

5. **Hábitos e Ambiente** (`PreanesthesiaSocialAndEnvironmentSection`)
   - Domain: `social_environment`
   - Capacidade funcional: **picker segmentado**
   - Tabaco/álcool/drogas/exposição: DomainSection

6. **Exame Físico** (`PreanesthesiaPhysicalExamSection`)
   - Domain: `physical_exam`
   - Cada categoria = 1 item com `details`
   - `code = category` (nunca vazio)
   - Botão na toolbar: **Aplicar padrões**

7. **Exames e Imagens** (`PreanesthesiaLabsAndImageSection`)
   - Domain: `labs_and_image`
   - Laboratório: lista fixa de `LabsCode` com campo de valor
   - ECG/RX/ECO: DomainSection
   - Outro exame: input livre (custom)

8. **Medicações** (`PreanesthesiaMedicationsSection`)
   - Domain: `medications`
   - Categorias: `allergy` e `dailymeds`
   - UI: lista + input + botão adicionar

---

## 3) Estados e fluxo de dados

### Estados principais
- `@State private var preanesthesiaItems: [PreanesthesiaItemInput]`
- `@State private var clearanceStatus: ClearanceStatus?`
- `@State private var clearanceItems: [String]`
- `@State private var asaSelection: ASAClassification?`

### Fontes iniciais
Ao abrir o form:
- Se existir `initialPreanesthesia`, carrega **ASA, técnicas, clearance e items**.
- Alguns dados são exibidos com base em `patient` e `surgery` (nomes, datas).

### Limitação importante
As mudanças feitas nas subviews **só têm efeito após salvar** o formulário principal.

---

## 4) Limitações atuais

- O form **não sincroniza em tempo real** com a view de detalhes.
- Algumas seções assumem que **ausência de itens** significa ausência clínica.
- Não há validações clínicas profundas no iOS (apenas formais).

---

## 5) Interpretação na View de Detalhes

A interpretação padrão deve seguir a lógica:

| Seção | Sem itens | Interpretação sugerida |
|------|-----------|------------------------|
| Comorbidades | nenhum item | “Sem comorbidades relatadas” |
| Alergias | nenhum item | “Sem alergias conhecidas” |
| Medicações diárias | nenhum item | “Sem uso contínuo” |
| Exame físico | sem item na categoria | “Sem achados descritos” |
| Exames | sem item | “Sem exames informados” |

**Atenção:** ausência de itens não significa normalidade clínica absoluta — é apenas “não informado”.

---

## 6) Quando recarregar dados

Sempre que o formulário for fechado após salvar, a tela de detalhes deve:
- Recarregar o `preanesthesia` completo
- Atualizar ASA, técnicas, clearance e items

Sugestão:
- Ao fechar o form, chamar `reload` no session do detalhe
- Evitar cache antigo na view de detalhes

---

## 7) Recomendações de UX

- Indicar visualmente o número de itens por seção (ex.: “3 comorbidades”)
- Em itens custom, mostrar `custom_label` + `details`
- Em detalhes vazios, mostrar “não informado”

---

## 8) Checklist de evolução futura

- Airway: preditores com detalhes individuais
- Exames: permitir valores numéricos + unidade
- Medicações: permitir dose e frequência
- Exame físico: presets mais refinados

---

## 9) Itens inteligentes (derivados) e sincronização UI

Alguns itens podem ser **derivados automaticamente** a partir de dados do paciente/surgery
ou de outros itens já selecionados.

### Exemplos de derivação
- `patient.sex == female` → `ApfelScoreCode.femaleSex`
- `SmokingCode.current` → `ApfelScoreCode.tobaccoUse`
 - `AnesthesiaComplicationsHistoryCode.nausea` → `ApfelScoreCode.historyPONV`

### Regra de UX (visível + reversível)
- Itens derivados **aparecem visíveis** na UI (como se tivessem sido selecionados).
- Se o usuário **desmarcar** um item derivado, o item correspondente também deve
  ser desmarcado (e vice‑versa).

### Comportamento recomendado
1. **Na entrada do form**: calcular e inserir os derivados, se faltando.
2. **Durante edição**: manter sincronização bidirecional
   (ex.: remover `tobaccoUse` remove `SmokingCode.current`).
3. **Na saída/salvar**: garantir consistência final entre itens relacionados.

### Observações
- Derivados devem ser **determinísticos** e **explicáveis** ao usuário.
- Evitar “forçar” seleção: se o usuário remove, respeitar.

---

## 10) Pendências críticas (validações e contexto clínico)

### 10.1 Validações clínicas e mudança de status
Falta definir o conjunto de **validações obrigatórias** que determinam quando\n+`preanesthesia.status` pode passar de `in_progress_pre` para `completed_pre`.

Exemplos de gatilhos possíveis (a discutir):
- ASA preenchido
- Técnicas anestésicas selecionadas
- Clearance definido
- Itens mínimos em comorbidades/medicações

Isso vai exigir regras explícitas (backend + iOS) para evitar inconsistência.

### 10.2 Ajustes por idade (patient.dateOfBirth + surgery.date)
Ainda não implementado:
- Calcular idade com base em `patient.dateOfBirth` e `surgery.date`.
- Usar idade para **mostrar/ocultar** seções (ex.: pediatria, infant).

### 10.3 Ajustes por sexo (patient.sex)
Ainda não implementado:
- Ocultar seções **gestacionais** para sexo masculino.
- Ocultar seções **andrológicas** para sexo feminino.

Esses filtros melhoram UX, mas exigem cuidado para não esconder dados já existentes.

---

## 11) Outros pontos a considerar

1) **Unidades e referência em exames**  
   - Labs sem unidade viram ambíguos (Hb 12 = g/dL?).  
   - Ideal: incluir unidade e/ou faixa de referência.

2) **Ausência ≠ normal**  
   - Sem item não significa normalidade clínica.  
   - As views de detalhe devem exibir “não informado” em vez de “normal”.

3) **Status e regressão**  
   - Ao definir `completed_pre`, pequenas edições não deveriam\n+     rebaixar automaticamente sem confirmação.

4) **Contexto cirúrgico**  
   - Algumas seções podem ser irrelevantes dependendo do tipo de cirurgia.  
   - Possível filtragem adicional usando `surgery.type`.

5) **Auditoria**  
   - Mostrar “última atualização” e autor aumenta confiança clínica.

6) **Duplicidade**  
   - Evitar itens duplicados com mesmo `domain + category + code`.

7) **Performance**  
   - O array de `items` cresce rápido; vale considerar\n+     cache de summaries por domínio ou diffs na UI.

### Implementação atual (sync bidirecional)

O formulário já sincroniza automaticamente:
- **Náusea anestésica** ↔ **Apfel `historyPONV`**
- **Tabagismo atual** ↔ **Apfel `tobaccoUse`**

Snippet (resumo):
```swift
.onChange(of: preanesthesiaItems) { oldValue, newValue in
    let synced = syncNvpoWithAnesthesiaHistory(old: oldValue, new: newValue)
    if synced != newValue {
        preanesthesiaItems = synced
    }
}
```

E dentro do helper:
```swift
if hasSmokingCurrent && !hasApfelTobacco {
    addApfelTobaccoUse()
}
if hasApfelTobacco && !hasSmokingCurrent {
    addSmokingCurrent()
}
```
