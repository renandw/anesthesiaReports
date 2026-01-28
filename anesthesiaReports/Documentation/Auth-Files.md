Auth — Papéis por arquivo

Objetivo
Documentar o papel de cada arquivo da pasta Auth e como eles se relacionam.

---

Auth/AuthSession.swift
- Orquestra o estado global de sessão (loading/authenticated/unauthenticated/sessionExpired)
- Executa bootstrap (refresh) e login/logout
- Decide quando encerrar sessão em erros fatais
- Não expõe operações de usuário (isso fica no UserSession)

Auth/AuthAPI.swift
- Endpoints de autenticação (login, register)
- Usa HTTPClient centralizado

Auth/UserAPI.swift
- Endpoints de usuário (GET /users/me, PATCH /users/me, DELETE /users/me, GET /users/related)
- Usa HTTPClient centralizado

Auth/HTTPClient.swift
- Cliente único de rede do app
- Injeta Authorization automaticamente
- Faz refresh automático e repete a request uma única vez
- Converte falhas em AuthError

Auth/TokenManager.swift
- Lê/salva tokens (via AuthStorage)
- Executa refresh token
- Limpa tokens quando necessário

Auth/AuthStorage.swift
- Persistência local de tokens (Keychain)
- Exposto por métodos simples (get/save/clear)

Auth/Errors/AuthError.swift
- Enum de erros de autenticação
- Faz o mapeamento do payload do backend
- Define erros fatais e mensagens padrão

Auth/HealthAPI.swift
- Endpoint GET /health
- Indica healthy/unhealthy para Startup/Login

