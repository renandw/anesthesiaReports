Startup Views — Functional Specification Document (FSD)

1. Objetivo

Este documento define o comportamento e as responsabilidades das Startup Views do app iOS, responsáveis pelo fluxo inicial de autenticação e navegação básica do usuário.

As Startup Views cobrem:
• inicialização do app
• autenticação explícita
• criação de conta
• exibição do estado autenticado
• logout

Nenhuma view de domínio (negócio) participa deste fluxo.

⸻

2. Princípios Gerais

• O estado global de autenticação é controlado exclusivamente pelo AuthSession
• UserSession é a fonte de dados do usuário autenticado
• Views não tomam decisões de navegação baseadas em tokens ou respostas de API
• Navegação é sempre derivada do estado (state-driven UI)
• Nenhuma view acessa TokenManager, AuthAPI ou UserAPI diretamente
• Startup Views são simples, previsíveis e descartáveis

⸻

3. Arquitetura de Estado

Todas as Startup Views observam o seguinte estado global:

AuthSession.state:
• loading
• unauthenticated
• authenticated
• sessionExpired

A mudança desse estado é a única forma válida de transição entre telas principais.

⸻

4. StartupView

4.1 Responsabilidade

A StartupView é a view raiz do app e o ponto inicial de execução.

Ela é responsável por:
• disparar o bootstrap da sessão
• exibir um estado de carregamento transitório
• delegar a navegação com base no AuthSession.state

4.2 Comportamento

Ao ser exibida:
• chama AuthSession.bootstrap()
• aguarda a resolução do estado

Estados possíveis:
• loading → exibe indicador de carregamento
• unauthenticated → exibe LoginView (se health ok) ou SystemUnavailableView
• authenticated → exibe DashboardView
• sessionExpired → exibe SessionExpiredView

4.4 Health Check

• StartupView consulta HealthAPI
• Se unhealthy: exibe SystemUnavailableView e faz polling
• Quando healthy: segue com bootstrap

4.3 Restrições

A StartupView NÃO:
• exibe dados de usuário
• executa login ou logout
• acessa tokens
• executa chamadas diretas ao backend

⸻

5. LoginView

5.1 Responsabilidade

A LoginView é responsável pela autenticação explícita do usuário.

5.2 Funcionalidades

• coleta email e senha
• dispara AuthSession.login(email, password)
• exibe mensagens de erro de autenticação
• permite navegação para RegisterView

5.3 Comportamento

• Em sucesso: não navega manualmente
• Aguarda AuthSession.state mudar para authenticated
• Em erro: exibe feedback local sem alterar estado global

5.4 Restrições

A LoginView NÃO:
• salva tokens
• navega para DashboardView
• decide sucesso de login
• chama serviços de backend diretamente

⸻

6. RegisterView

6.1 Responsabilidade

A RegisterView é responsável pela criação de uma nova conta de usuário.

6.2 Funcionalidades

• coleta dados de cadastro
• dispara AuthSession.register(...)
• exibe sucesso ou erro
• retorna manualmente para LoginView após sucesso

6.3 Comportamento

• O registro NÃO cria sessão
• AuthSession.state permanece inalterado
• A navegação após sucesso é explícita (dismiss)

6.4 Restrições

A RegisterView NÃO:
• cria login automático
• salva tokens
• navega por estado
• acessa dados locais persistidos

⸻

7. SessionExpiredView

7.1 Responsabilidade

A SessionExpiredView representa o estado de sessão expirada sem encerramento definitivo.

Ela é responsável por:
• informar claramente que a sessão expirou
• preservar dados locais
• conduzir o usuário à reautenticação ou ao logout explícito

7.2 Funcionalidades

• exibe mensagem de sessão expirada
• permite navegação para LoginView (reatenticação)
• oferece ação explícita de logout definitivo

7.3 Comportamento

• A reautenticação ocorre pelo fluxo normal de LoginView
• Em sucesso, AuthSession.state muda para authenticated
• Logout explícito chama AuthSession.logout()

7.4 Restrições

A SessionExpiredView NÃO:
• altera AuthSession.state diretamente
• acessa tokens ou serviços
• executa sync
• apaga dados automaticamente

⸻

8. DashboardView

8.1 Responsabilidade

A DashboardView representa o estado autenticado do app.

8.2 Funcionalidades

• exibe mensagem de boas-vindas
• exibe dados básicos do usuário (UserSession)
• oferece ação explícita de logout

8.3 Comportamento

• Dados são lidos do UserSession (estado já carregado no bootstrap)
• Logout dispara AuthSession.logout()
• Navegação ocorre apenas pela mudança de AuthSession.state

8.4 Restrições

A DashboardView NÃO:
• chama APIs diretamente
• acessa tokens
• controla navegação manualmente
• executa lógica de autenticação

⸻

9. Fluxo de Navegação

O fluxo de navegação é inteiramente dirigido por estado:

AuthSession.state = loading
→ StartupView (loading)

AuthSession.state = unauthenticated
→ LoginView
→ RegisterView (opcional, via navegação explícita)

AuthSession.state = authenticated
→ DashboardView

AuthSession.state = sessionExpired
→ SessionExpiredView

⸻

10. Views fora do Startup Flow (referência)

As views abaixo são acessíveis a partir do estado authenticated, mas não
fazem parte do Startup Flow:

• UserDetailsView — detalhes e edição do usuário
• EditUserView — edição simples de perfil
• CanShareWithView — seleção de usuários relacionados (temporária)

⸻

11. Regra de Ouro

Nenhuma Startup View decide o fluxo do app.
Apenas o AuthSession altera o estado global.

⸻

12. Conclusão

As Startup Views formam um fluxo previsível, desacoplado e orientado a estado.

Essa arquitetura garante:
• simplicidade de UI
• segurança de sessão
• consistência de navegação
• facilidade de manutenção e testes
