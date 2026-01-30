# Patient Views — FSD

## Objetivo
Documentar as views principais do módulo de pacientes e a lógica de UI/estado envolvida no fluxo de criação, leitura, edição e compartilhamento.

## PatientFormView
View: `Patient/PatientFormView.swift`

### Papel
- Criar ou editar pacientes.
- Suporta dois modos: **standalone** (sheet/NavigationView) e **wizard** (futuro fluxo guiado).

### Estados relevantes
- `name`, `sex`, `dateOfBirth`, `cns` — campos do formulário.
- `isLoading` — bloqueia ações enquanto envia.
- `errorMessage` — feedback de erro de validação/rede.

### Validação
- Nome não vazio.
- Data de nascimento válida (normalizada).
- `sex` obrigatório.
- CNS com 15 dígitos.

### Comportamento
- Preenche campos quando `existing` é fornecido.
- Botões “Salvar/Criar” só habilitam quando `isValid`.
- `sex` usa enum `Sex` (rawValue `male/female`) para envio ao servidor.

---

## PatientDetailView
View: `Patient/PatientDetailView.swift`

### Papel
- Mostrar detalhes do paciente.
- Permitir editar, compartilhar e excluir quando `my_permission == "write"`.

### Comportamento
- Exibe seções: **Dados**, **Metadados** e **Compartilhado com**.
- Carrega shares e exibe permissões.
- Abre `PatientFormView` para edição.
- Abre `CanShareWithView` para compartilhar.

### Permissões
- Usa `my_permission` do payload.
- Bloqueia ações quando o usuário não é writer.

---

## CanShareWithView
View: `Patient/CanShareWithView.swift`

### Papel
- Compartilhar pacientes com usuários relacionados.
- Permitir atualizar permissão ou revogar.

### Conceitos aplicados
- **Shimmer loading** no primeiro carregamento.
- **Feedback visual por ícones/cores** (sem mensagens temporárias).
- **Operações por linha** com estados isolados.
- **Confirmação destrutiva** para revogação.
- **Debounce de busca** e **refreshable**.

### Helpers
- `PermissionBadgeView` — ícone + cor da permissão com overlay de loading.
- `Shimmer` — efeito de carregamento esqueleto.
- `ShakeEffect` — feedback visual em erro por linha.
