Patient API — FSD

Objetivo
Documentar o uso da API de pacientes pelo app iOS (contrato esperado).

---

Base URL
```txt
http://localhost:7362
```

Autenticação
Todas as rotas requerem `Authorization: Bearer <access_token>`.

---

Endpoints usados pelo app

1) Listar pacientes (meus + compartilhados)
GET `/patients`

Query params:
```
search=<nome_parcial>
```

Uso no app:
- Carrega a lista principal
- Retorna `my_permission` para controle de UI

2) Listar pacientes compartilhados comigo
GET `/patients/shared-with-me`

Query params:
```
search=<nome_parcial>
```

Uso no app:
- Aba/lista "Compartilhados comigo"

3) Listar pacientes compartilhados por mim
GET `/patients/shared-by-me`

Query params:
```
search=<nome_parcial>
```

Uso no app:
- Aba/lista "Compartilhados por mim"

4) Detalhar paciente
GET `/patients/:patientId`

Uso no app:
- Abre detalhes do paciente
- Retorna `my_permission` para habilitar/ocultar ações

5) Criar paciente
POST `/patients`

Body:
```json
{
  "patient_name": "Nome",
  "sex": "male",
  "date_of_birth": "1991-02-14",
  "cns": "000000000000000"
}
```

Uso no app:
- Formulário de criação
- Resposta inclui `my_permission = write`

6) Atualizar paciente
PATCH `/patients/:patientId`

Body parcial:
```json
{
  "patient_name": "Novo nome",
  "sex": "female",
  "date_of_birth": "1991-02-14",
  "cns": "000000000000000"
}
```

Uso no app:
- Formulário de edição
- Só permitido se `my_permission = write`

7) Deletar paciente (soft delete)
DELETE `/patients/:patientId`

Uso no app:
- Ação "Excluir"
- Só permitido se `my_permission = write`

8) Listar compartilhamentos do paciente
GET `/patients/:patientId/share`

Uso no app:
- Exibir lista "Compartilhado com"
- Só permitido se `my_permission = write`

9) Conceder/atualizar compartilhamento
POST `/patients/:patientId/share`

Body:
```json
{
  "user_id": "uuid",
  "permission": "read"
}
```

Uso no app:
- Ação de compartilhar com usuário
- `permission`: read | write

10) Atualizar permissão
PATCH `/patients/:patientId/share/:userId`

Body:
```json
{
  "user_id": "uuid",
  "permission": "write"
}
```

11) Revogar acesso
DELETE `/patients/:patientId/share/:userId`

Uso no app:
- Ação "Revogar acesso" no compartilhamento

---

Campo `my_permission`

- `write`: usuário pode editar, excluir e compartilhar
- `read`: usuário apenas visualiza

O app deve esconder ações de escrita quando `my_permission == read`.

