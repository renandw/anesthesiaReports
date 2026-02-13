# ComorbitiesReusable.md

Este documento descreve como o **modelo reutilizável de comorbidades** foi pensado para crescer sem criar novas tabelas ou telas específicas. A ideia é simples: **uma estrutura genérica no backend + enums organizadas no iOS**.

---

## 1) O modelo reutilizável (backend)

Todos os itens de preanesthesia (comorbidades, alergias, histórico etc.) vivem na mesma tabela:

```
preanesthesia_items
- domain
- category
- code
- is_custom
- custom_label
- details
```

**Para comorbidades:**
- `domain = comorbidity`
- `category = cardiovascular | endocrine | neurological | oncological | nephrological | hematological | …`
- `code = enum do tipo` (ex.: `has`, `valvopathy`, `custom`)

Isso permite **múltiplas comorbidades** por categoria sem mudar a tabela.

---

## 2) Como reutilizar no iOS (padrão genérico)

As views de **comorbidades**, **histórico cirúrgico**, **histórico anestésico**, **exames** etc. são praticamente iguais.  
O que muda é **domínio, categoria e enums**. Por isso, o ideal é ter **um núcleo reutilizável**.

Hoje, `PreanesthesiaComorbiditiesSection` usa duas camadas reutilizáveis:

1. **`ComorbidityCategorySection`** → renderiza **uma** categoria (toggle + checklist + custom + detalhes).
2. **`ComorbiditySectionConfig`** → lista de configuração que permite montar **várias** categorias sem repetição de código.

O próximo passo natural é **generalizar isso para qualquer domínio**, não só comorbidades.

### Passo a passo para adicionar nova categoria

1. **Adicionar categoria**
   - No enum `ComorbidityCategory`, inclua a nova categoria.

2. **Criar enum de códigos**
   - Exemplo: `NephroComorbidityCode`, `NeuroComorbidityCode`, etc.

3. **Adicionar bloco na UI**
   - Adicione um `ComorbiditySectionConfig` no array `sectionConfigs`.
   - Informe: `title`, `category`, `codes` e `customCodeRawValue`.
   - O toggle, lista, detalhes e custom já vêm prontos.

---

## 3) Estrutura reutilizável para outros domínios (surgery_history, anesthesia_history, etc.)

A mesma lógica pode ser aplicada a qualquer domínio do modelo genérico.  
Basta trocar:
- `domain` (ex.: `surgery_history`)
- `category` (ex.: `general`, `urology`, `orthopedic`)
- `code` (enum específico daquele domínio)

### Exemplo de configuração para Histórico Cirúrgico
```swift
struct GenericSectionConfig {
    let title: String
    let domain: PreanesthesiaItemDomain
    let category: String
    let codes: [ComorbidityCodeOption]   // pode virar SectionCodeOption
    let customCodeRawValue: String
    let footer: String
}

// Uso:
GenericSectionConfig(
    title: "Cirurgia Geral",
    domain: .surgeryHistory,
    category: "general",
    codes: GeneralSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
    customCodeRawValue: GeneralSurgeryHistoryCode.customCase.rawValue,
    footer: "Selecione cirurgias prévias e descreva detalhes."
)
```

### Por que isso ajuda
- **Mesmo componente** para múltiplas seções
- **Menos bugs** (um único fluxo de toggle + detalhes)
- **Mais rápido para expandir** (basta adicionar enums e config)

---

## 4) Plano: `DomainSection` genérico

### Objetivo
Ter **uma única view** que renderiza qualquer domínio (`comorbidity`, `surgery_history`, `anesthesia_history`, `labs_imaging`, etc.) usando apenas **config**.

### Interface sugerida
```swift
struct DomainSectionConfig {
    let title: String
    let domain: PreanesthesiaItemDomain
    let category: String
    let codes: [CodeOption]
    let customCodeRawValue: String
    let footer: String
    let customLabelPlaceholder: String
}

struct CodeOption: Hashable {
    let rawValue: String
    let displayName: String
}

struct DomainSection: View {
    let config: DomainSectionConfig
    @Binding var items: [PreanesthesiaItemInput]
}
```

### Substituição nos arquivos atuais

#### ✅ `PreanesthesiaComorbiditiesSection`
Hoje: `ComorbidityCategorySection` + `ComorbiditySectionConfig`  
Novo: `DomainSectionConfig` + `DomainSection`

Exemplo:
```swift
DomainSection(
    config: DomainSectionConfig(
        title: "Cardiovascular",
        domain: .comorbidity,
        category: "cardiovascular",
        codes: CardioComorbidityCode.allCases
            .filter { $0 != .custom }
            .map { $0.option },
        customCodeRawValue: CardioComorbidityCode.customCase.rawValue,
        footer: "Selecione comorbidades e descreva detalhes relevantes.",
        customLabelPlaceholder: "Comorbidade"
    ),
    items: $items
)
```

#### ✅ `PreanesthesiaSurgeryHistorySection`
Hoje: `SurgeryHistoryCategorySection` quase idêntica.  
Novo: usar `DomainSection` com `domain: .surgeryHistory` e enums próprios.

Exemplo:
```swift
DomainSection(
    config: DomainSectionConfig(
        title: "Cirurgia Geral",
        domain: .surgeryHistory,
        category: "general",
        codes: GeneralSurgeryHistoryCode.allCases
            .filter { $0 != .custom }
            .map { $0.option },
        customCodeRawValue: GeneralSurgeryHistoryCode.customCase.rawValue,
        footer: "Selecione cirurgias prévias e descreva detalhes.",
        customLabelPlaceholder: "Cirurgia"
    ),
    items: $items
)

---

## 7) Casos especiais com picker (sem DomainSection)

Nem tudo é checklist. Alguns domínios funcionam melhor com **seleção única**:

### Via aérea (Mallampati)
- **domain:** `airway`
- **category:** `mallampati`
- **code:** `i | ii | iii | iv`
- **is_custom:** `false`
- **details:** `nil`

Implementação recomendada:
- `Picker` com `.segmented`
- `selection` é `MallampatiCode?`
- ao escolher, remove item anterior e insere o novo.

### Hábitos e Ambiente (Capacidade Funcional)
- **domain:** `environment`
- **category:** `funcionalcapacity`
- **code:** `FunctionalCapacityCode`
- o `Picker` deve ler/gravar **somente** itens dessa categoria.

**Pitfall comum:** filtrar pela categoria errada (`environment`) faz o Picker não manter o estado.

---

## 8) Exame físico (payload por categoria)

O `PreanesthesiaPhysicalExamSection` não usa checklist.  
Cada categoria gera **um único item** no array, com `details` livre:

**Formato:**
```
{
  "domain": "physical_exam",
  "category": "<general|brain|heart|lungs|abdome|limbs>",
  "code": "<category>",
  "is_custom": false,
  "custom_label": null,
  "details": "texto livre"
}
```

**Regras do section:**
- Se o texto ficar vazio → remove o item daquela categoria.
- `code` nunca fica vazio: usa o próprio `category` como valor.
- Botão “Aplicar padrões” preenche cada categoria **somente se estiver vazia**.
```

### Ajustes necessários em `PreanesthesiaItemEnum`
Para suportar múltiplos domínios:
- Expandir `PreanesthesiaItemDomain` com casos:
  - `comorbidity`
  - `surgeryHistory`
  - `anesthesiaHistory`
  - `labsImaging`
  - `environment`
  - `nvpo`
- Criar enums de códigos por domínio (já parcialmente feitos)
- Garantir que cada enum tenha `customCase`
- Manter `CodeOption` reutilizável (pode ficar em Helper)

---

## 5) Semântica recomendada

Para consistência, use nomes em inglês (sem acento) com sufixo **-logical**:

- `cardiovascular`
- `endocrine`
- `neurological`
- `oncological`
- `nephrological`
- `hematological`

> Evite misturar (ex.: `nephro`, `nephrologic`). Escolha um padrão e mantenha.

---

## 6) Exemplo de expansão (nephrological)

### Enum de categoria
```swift
enum ComorbidityCategory: String {
    case cardiovascular
    case nephrological
}
```

### Enum de códigos
```swift
enum NephroComorbidityCode: String, CaseIterable {
    case ckd           // chronic kidney disease
    case dialysis
    case nephrectomy
    case transplant
    case custom
}
```

### Uso na UI (sem duplicar lógica)
```swift
ComorbiditySectionConfig(
    title: "Nefrológico",
    category: .nephrological,
    codes: NephroComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
    customCodeRawValue: NephroComorbidityCode.customCase.rawValue,
    footer: "Selecione comorbidades e descreva detalhes relevantes."
)
```

### Exemplo de item enviado ao backend
```json
{
  "domain": "comorbidity",
  "category": "nephrological",
  "code": "ckd",
  "is_custom": false,
  "custom_label": null,
  "details": "DRC estágio 3 desde 2021"
}
```

---

## 7) Por que isso é bom

- **Sem migrations** a cada nova comorbidade
- **UI reaproveitável** (mesma lógica para todas as categorias)
- **Payload uniforme** → mais simples de debugar
- **Facilidade de expansão** (apenas enums e bloco UI)

---

## 8) Dicas práticas

- Sempre valide `custom_label` quando `is_custom = true`
- Se o usuário desativar o toggle da categoria → remover todos os itens daquela categoria
- Para renderizar resumo na UI, derive do array (nada de `category_bool` no banco)
