# Requisitos Não Funcionais (RNF)
## Sistema de Gestão - Casa de Portas e Janelas


## RNF01 - Desempenho

**Descrição:**  
O sistema deve responder às principais ações do usuário de forma rápida para garantir uma boa experiência de uso.

**Critérios:**
- O tempo de resposta para operações comuns (login, busca de produtos e clientes) deve ser de no máximo **2 segundos**.
- Consultas de dados e geração de analíticas devem ocorrer em até **5 segundos**.


## RNF02 - Segurança

**Descrição:**  
O sistema deve garantir a segurança dos dados e o acesso restrito às funcionalidades de acordo com o nível de usuário.

**Critérios:**
- O sistema deve utilizar **autenticação com e-mail e senha**.
- Deve ser implementado **2FA (autenticação em dois fatores)** para login.
- O sistema deve bloquear temporariamente a conta após **5 tentativas de login inválidas**.


## RNF03 - Disponibilidade

**Descrição:**  
O sistema deve estar disponível para os usuários durante o horário de operação da empresa.

**Critérios:**
- O sistema deve possuir disponibilidade mínima de **99% do tempo de funcionamento**.
- Manutenções devem ser realizadas preferencialmente **fora do horário de expediente**.
- O sistema deve possuir mecanismo de recuperação em caso de falha.
