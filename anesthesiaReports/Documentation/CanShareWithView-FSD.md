# CanShareWithView — Compartilhamento de Pacientes

## Objetivo da View
Tela responsável por compartilhar um paciente com outros anestesistas relacionados (mesma empresa), definindo a permissão de acesso (`read` ou `write`). Também permite revogar acesso.

Essa view é o ponto de controle visual para o fluxo de compartilhamento no app.

## Papel no Fluxo
1. Carrega lista de usuários relacionados (filtrados por empresa e busca).
2. Carrega shares existentes do paciente.
3. Exibe o estado atual de permissão por usuário.
4. Permite atualizar permissão ou revogar.

## Conceitos Aplicados
- **Feedback visual por ícones e cores**  
  Sem mensagens temporárias. O status é percebido pela cor e ícone.

- **Operações por linha (isoladas)**  
  Cada usuário pode estar em atualização sem bloquear o resto da lista.

- **Shimmer (skeleton loading)**  
  Evita telas vazias durante o carregamento inicial.

- **Confirmação destrutiva**  
  Revogação exige confirmação explícita.

- **Debounce de busca**  
  Evita múltiplas chamadas enquanto o usuário digita.

- **Refreshable**  
  Permite sincronizar manualmente com o servidor.

## Estados Visuais de Permissão
| Permission | Ícone | Cor | Observação |
|---|---|---|---|
| `read` | `eye` | Azul | Acesso de leitura |
| `write` | `pencil` | Verde | Acesso total |
| `none` | `nosign` | Cinza | Sem acesso |

## Fluxo de Atualização
1. Usuário escolhe permissão no menu.
2. Request é enviado.
3. Enquanto aguarda, o ícone mostra `ProgressView` sobreposto.
4. Se sucesso, ícone muda para o novo estado.
5. Se falha, a linha recebe efeito de **shake**.

## Helpers Utilizados
### `PermissionBadgeView`
Arquivo: `Helper/PermissionBadgeView.swift`  
Mostra o ícone + cor de permissão e overlay de loading.

### `Shimmer`
Arquivo: `Helper/Shimmer.swift`  
Aplica shimmer em listas de placeholder durante carregamento inicial.

### `ShakeEffect`
Local: `Patient/CanShareWithView.swift`  
Efeito de shake para feedback de erro em uma linha específica.
