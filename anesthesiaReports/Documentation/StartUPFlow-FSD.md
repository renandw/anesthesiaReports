Startup Flow — Functional Specification Document (FSD)

1. Objetivo

Definir o fluxo de inicialização do app iOS considerando o domínio user, após a introdução de uma camada de sessão centralizada (AuthSession) e refresh automático de tokens.

O Startup Flow é responsável por:
• decidir se existe sessão válida
• restaurar o estado do usuário a partir do backend
• redirecionar para a tela correta
• invalidar o app imediatamente quando a sessão não é válida

Nenhuma tela de negócio é exibida antes da decisão do startup.

⸻

2. Princípios

• O backend é a única fonte da verdade  
• O app nunca assume que existe sessão válida  
• Refresh de token é automático, transparente e centralizado  
• Mudanças de estado do usuário invalidam o app imediatamente  
• O Startup Flow é centralizado no AuthSession  
• Views não contêm lógica de autenticação  

⸻

3. Componentes Envolvidos
Ver também: Documentação detalhada dos arquivos em `Documentation/Auth-Files.md`.

3.1 AuthSession

Responsável por:
• orquestrar o fluxo de autenticação
• manter o estado global (loading, authenticated, unauthenticated)
• traduzir erros técnicos em decisões de navegação
• forçar logout automático quando necessário

AuthSession é a única fonte de verdade para o estado de login do app.

⸻

3.2 AuthSession (ações explícitas)

Responsável por:
• executar ações explícitas (login, logout, register)
• orquestrar bootstrap com refresh
• manter o estado global (loading, authenticated, unauthenticated)

Obs: o AuthSession não expõe mais métodos de usuário.

⸻

3.3 UserSession

Responsável por:
• carregar e manter o usuário atual
• atualizar perfil (PATCH /users/me)
• deletar conta (DELETE /users/me)
• listar usuários relacionados (GET /users/related)

UserSession depende de AuthStorage e UserAPI para usar o access token.

⸻

3.4 UserAPI

Responsável por:
• chamadas de usuário (GET /users/me, PATCH /users/me, DELETE /users/me, GET /users/related)
• traduzir respostas para DTOs

⸻

3.5 HTTPClient + TokenManager

Responsabilidades internas de infraestrutura:
• adicionar Authorization automaticamente
• realizar refresh de token quando necessário
• repetir a request original uma única vez
• sinalizar erro fatal quando a sessão é inválida

Nenhuma View ou Service acessa tokens diretamente.

⸻

3.6 HealthAPI (atual)

Responsável por:
• consultar GET /health
• sinalizar healthy/unhealthy no app

Obs: hoje o HealthAPI é usado diretamente pela StartupView e LoginView.
Há um plano para evoluir isso para um HealthMonitor global (seção 10).

⸻

4. StartupView (ou AppBootstrapView)

Responsabilidade

A StartupView é a primeira tela do app.

Ela:
• não exibe dados de domínio
• não permite interação
• apenas dispara o fluxo de inicialização

Visualmente pode ser:
• splash
• loading
• tela em branco com spinner

⸻

5. Fluxo de Inicialização (passo a passo)

Passo 1 — App inicia
• @main App cria uma instância de AuthSession
• StartupView é exibida
• AuthSession.bootstrap() é chamado

⸻

Passo 1.1 — Health check (novo)
• StartupView chama HealthAPI.check()
• Se healthy, segue para bootstrap
• Se unhealthy, mostra “Sistema indisponível” e inicia polling automático

⸻

Passo 2 — Verificar sessão e estado do usuário

AuthSession executa:
userSession.loadUser()

Esse método:
• chama GET /users/me
• utiliza HTTPClient
• HTTPClient adiciona Authorization automaticamente
• refresh de token ocorre de forma transparente, se necessário

Resultados possíveis:
• usuário carregado com sucesso
• erro fatal de autenticação
• usuário inativo ou deletado

⸻

Passo 3 — Sessão inválida

Erros considerados fatais:
• TOKEN_INVALID
• TOKEN_EXPIRED (após tentativa de refresh)
• USER_INACTIVE
• USER_DELETED
• erros de rede ou infraestrutura
• sistema indisponível (health = unhealthy)

Ações:
• limpar tokens
• apagar dados locais
• atualizar AuthSession.state = sessionExpired
• navegar para SessionExpiredView

Nenhuma tentativa adicional é feita.

⸻

Passo 4 — Sessão válida

Condições:
• active = true
• is_deleted = false

Ações:
• criar ou atualizar User (SwiftData)
• criar ou atualizar SyncState(scope: user)
• atualizar AuthSession.state = authenticated
• navegar para DashboardView

⸻

6. Navegação Resultante

Estado do AuthSession | View exibida
loading               | StartupView
unauthenticated       | LoginView
authenticated         | DashboardView
sessionExpired        | SessionExpiredView

RegisterView é acessível apenas a partir da LoginView.

Quando o sistema está indisponível (health = unhealthy),
StartupView mostra a tela de indisponibilidade e tenta novamente em background.

⸻

7. Erros e Comportamentos

Erros de sessão (fatais):
• TOKEN_INVALID
• TOKEN_EXPIRED
• USER_DELETED

Ações:
• logout automático
• limpeza completa do estado local
• redirecionamento para LoginView

⸻

Erros de conta:
• USER_INACTIVE

Ações:
• sessão invalidada
• uso offline bloqueado
• redirecionamento para LoginView

⸻

Erros técnicos (rede, timeout, backend):
• tratados como sessão inválida no startup
• redirecionamento para SessionExpiredView

⸻

8. O que o Startup Flow NÃO faz

• não acessa tokens diretamente  
• não faz refresh manual  
• não decide UI de negócio  
• não sincroniza outros domínios  
• não assume estado de login  

⸻

9. Regra de Ouro

Nenhuma View assume estado de autenticação.  
Apenas o AuthSession decide.

⸻

10. Plano para HealthMonitor Global (robusto)

Objetivo
• centralizar o estado de saúde do backend
• diferenciar “sem internet” vs “servidor indisponível”
• evitar lógica de rede nas Views

Proposta
• Criar HealthMonitor (ObservableObject) com:
  - @Published status: .unknown | .healthy | .serverDown | .offline
  - polling configurável (ex: 15s ou 30s)
  - cancelamento quando app vai background
  - modo “burst” ao retornar para foreground
• Usar NWPathMonitor para detectar conectividade local
• Se offline: status = .offline (não chama /health)
• Se online: chama /health e define .healthy ou .serverDown

Integração
• Injetar HealthMonitor no ambiente no @main
• StartupView, LoginView e DashboardView consomem o mesmo estado
• AuthSession usa HealthMonitor para decidir se tenta bootstrap

Política de UI
• Startup: bloqueia login enquanto .offline/.serverDown
• Login: mostra badge de status (online/offline)
• Dashboard: opcional mostrar banner discreto

⸻

10. Conclusão

Com AuthSession, HTTPClient e refresh automático:
• o app sempre inicia em estado consistente
• decisões de autenticação são centralizadas
• não há duplicação de lógica
• mudanças de estado do usuário são respeitadas imediatamente
• o modelo offline-first é preservado com segurança
