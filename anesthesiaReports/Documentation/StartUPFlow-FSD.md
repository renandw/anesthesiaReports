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

3.1 AuthSession

Responsável por:
• orquestrar o fluxo de autenticação
• manter o estado global (loading, authenticated, unauthenticated)
• traduzir erros técnicos em decisões de navegação
• forçar logout automático quando necessário

AuthSession é a única fonte de verdade para o estado de login do app.

⸻

3.2 AuthService

Responsável por:
• executar ações explícitas (login, logout, register)
• carregar o estado do usuário via GET /users/me
• persistir e limpar dados locais (SwiftData)

⸻

3.3 HTTPClient + TokenManager

Responsabilidades internas de infraestrutura:
• adicionar Authorization automaticamente
• realizar refresh de token quando necessário
• repetir a request original uma única vez
• sinalizar erro fatal quando a sessão é inválida

Nenhuma View ou Service acessa tokens diretamente.

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

Passo 2 — Verificar sessão e estado do usuário

AuthSession executa:
authService.loadUserState()

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

Ações:
• limpar tokens
• apagar dados locais
• atualizar AuthSession.state = unauthenticated
• navegar para LoginView

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

RegisterView é acessível apenas a partir da LoginView.

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
• redirecionamento para LoginView

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

10. Conclusão

Com AuthSession, HTTPClient e refresh automático:
• o app sempre inicia em estado consistente
• decisões de autenticação são centralizadas
• não há duplicação de lógica
• mudanças de estado do usuário são respeitadas imediatamente
• o modelo offline-first é preservado com segurança
