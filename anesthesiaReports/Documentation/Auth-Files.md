Auth — Papéis por arquivo

Objetivo
Documentar o papel de cada arquivo da pasta Auth e como eles se relacionam.

---

Auth/AuthSession.swift
- Responsabilidade
  - Orquestrar estado global de sessão (loading/authenticated/unauthenticated/sessionExpired)
  - Executar bootstrap (refresh) e login/logout
  - Decidir quando encerrar sessão em erros fatais
- Entradas
  - Credenciais de login (email/senha)
  - Tokens do TokenManager
- Saídas
  - Alteração de AuthSession.state
  - Limpeza de tokens e user quando necessário
- Dependências
  - TokenManager (tokens e refresh)
  - AuthAPI (login/register)
  - UserSession (carregar/limpar usuário)
- Observações
  - Não expõe operações de usuário

Auth/AuthAPI.swift
- Responsabilidade
  - Endpoints de autenticação (login, register)
- Entradas
  - Login: email/senha
  - Register: RegisterInput
- Saídas
  - AuthResponse (tokens) no login
  - EmptyResponse no register
- Dependências
  - HTTPClient
- Observações
  - Não faz refresh diretamente (TokenManager assume)

Auth/UserAPI.swift
- Responsabilidade
  - Endpoints de usuário (GET /users/me, PATCH /users/me, DELETE /users/me, GET /users/related)
- Entradas
  - UpdateUserInput, filtros de related (company/search)
- Saídas
  - UserDTO, RelatedUserDTO
- Dependências
  - HTTPClient
- Observações
  - Não recebe tokens explicitamente (HTTPClient injeta)

Auth/HTTPClient.swift
- Responsabilidade
  - Cliente único de rede
  - Injeta Authorization automaticamente
  - Faz refresh automático e repete a request uma única vez
  - Converte falhas em AuthError
- Fluxo
  - Request → 401/token inválido → refresh → retry 1x → erro fatal se falhar
- Observações
  - É o ponto único para tratamento de erros de rede

Auth/TokenManager.swift
- Responsabilidade
  - Lê/salva tokens (via AuthStorage)
  - Executa refresh token
  - Limpa tokens quando necessário
- Observações
  - É usado por AuthSession e HTTPClient

Auth/AuthStorage.swift
- Responsabilidade
  - Persistência local de tokens (Keychain)
  - get/save/clear

Auth/Errors/AuthError.swift
- Responsabilidade
  - Enum de erros de autenticação
  - Mapeamento de payload do backend
  - Define erros fatais e mensagens padrão

Auth/HealthAPI.swift
- Responsabilidade
  - Endpoint GET /health
  - Indica healthy/unhealthy para Startup/Login

---

Relacionamentos (resumo)
AuthSession → TokenManager → AuthStorage
AuthSession → AuthAPI
AuthSession ↔ UserSession → UserAPI
UserAPI/AuthAPI → HTTPClient → TokenManager
