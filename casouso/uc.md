# Exercício: Casos de Uso  
## Sistema de Gestão — Casa de Portas e Janelas

---

# Caso de Uso 1: Realizar Login

**Caso de Uso:** Realizar Login  
**Ator:** Usuário (Operário, Gerente, Admin)  
**Objetivo:** Permitir que o usuário acesse o sistema

## Pré-condições
- Usuário deve possuir conta cadastrada no sistema

## Pós-condições
- Usuário autenticado e redirecionado para a página inicial

## Fluxo Principal
1. Usuário acessa a tela de login  
2. Usuário informa e-mail e senha  
3. Sistema valida as credenciais  
4. Sistema solicita autenticação em dois fatores (2FA)  
5. Usuário informa o código de verificação  
6. Sistema concede acesso ao sistema  

## Fluxos Alternativos

### A1 – Credenciais inválidas
1. Sistema detecta erro nas credenciais  
2. Sistema exibe mensagem de erro  
3. Usuário retorna à tela de login  

### A2 – Código 2FA inválido
1. Sistema detecta código incorreto  
2. Sistema exibe mensagem de erro  
3. Usuário tenta novamente  

## Regras de Negócio
- **RN01** Bloqueio após 5 tentativas inválidas  
- **RN02** Autenticação em dois fatores obrigatória  

## Requisitos Relacionados
- **RF01** Autenticação de usuário  
- **RNF01** Tempo de resposta máximo de 2 segundos  

---

# Caso de Uso 2: Recuperar Senha

**Caso de Uso:** Recuperar Senha  
**Ator:** Usuário  
**Objetivo:** Permitir que o usuário recupere o acesso à conta

## Pré-condições
- Usuário deve possuir e-mail cadastrado no sistema

## Pós-condições
- Usuário redefine a senha e consegue acessar o sistema

## Fluxo Principal
1. Usuário acessa a opção **"Esqueci minha senha"**  
2. Usuário informa o e-mail cadastrado  
3. Sistema envia link de recuperação  
4. Usuário acessa o link enviado  
5. Usuário define nova senha  
6. Sistema salva a nova senha  

## Fluxos Alternativos

### A1 – E-mail não encontrado
1. Sistema detecta e-mail inexistente  
2. Sistema exibe mensagem de erro  

## Regras de Negócio
- **RN03** Link de recuperação válido por 15 minutos  

## Requisitos Relacionados
- **RF02** Recuperação de senha  
- **RNF02** Envio de e-mail em até 5 segundos  

---

# Caso de Uso 3: Gerenciar Produtos

**Caso de Uso:** Gerenciar Produtos  
**Ator:** Operário, Gerente, Admin  
**Objetivo:** Permitir o cadastro e gerenciamento de produtos (portas e janelas)

## Pré-condições
- Usuário deve estar autenticado no sistema

## Pós-condições
- Produtos cadastrados ou atualizados no sistema

## Fluxo Principal
1. Usuário acessa a tela de produtos  
2. Sistema exibe lista de produtos  
3. Usuário utiliza a barra de busca para localizar produtos  
4. Usuário seleciona a ação desejada (adicionar, editar ou remover)  
5. Sistema salva as alterações realizadas  

## Fluxos Alternativos

### A1 – Produto não encontrado
1. Sistema informa que nenhum produto corresponde à busca  

### A2 – Dados inválidos
1. Sistema detecta erro nos dados informados  
2. Sistema exibe mensagem de erro  
3. Usuário corrige as informações  

## Regras de Negócio
- **RN04** Operários podem apenas adicionar produtos  
- **RN05** Apenas gerente e administrador podem editar ou remover produtos  

## Requisitos Relacionados
- **RF03** Cadastro de produtos  
- **RF04** Edição de produtos  
- **RF05** Remoção de produtos  
- **RNF03** Atualização de dados em até 3 segundos  

---

# Caso de Uso 4: Gerenciar Clientes

**Caso de Uso:** Gerenciar Clientes  
**Ator:** Operário, Gerente, Admin  
**Objetivo:** Permitir o cadastro e gerenciamento de clientes

## Pré-condições
- Usuário deve estar autenticado no sistema

## Pós-condições
- Cliente cadastrado ou atualizado no sistema

## Fluxo Principal
1. Usuário acessa a tela de clientes  
2. Sistema exibe lista de clientes cadastrados  
3. Usuário utiliza a barra de busca  
4. Usuário seleciona a ação desejada (adicionar, editar ou remover)  
5. Sistema salva as alterações  

## Fluxos Alternativos

### A1 – Cliente não encontrado
1. Sistema informa que não existem clientes correspondentes à busca  

### A2 – Dados inválidos
1. Sistema detecta erro nos dados informados  
2. Sistema solicita correção  

## Regras de Negócio
- **RN06** Operários podem apenas adicionar clientes  
- **RN07** Apenas gerente e administrador podem editar ou remover clientes  

## Requisitos Relacionados
- **RF06** Cadastro de clientes  
- **RF07** Edição de clientes  
- **RF08** Remoção de clientes  

---

# Caso de Uso 5: Visualizar Registro de Auditoria

**Caso de Uso:** Visualizar Registro de Auditoria  
**Ator:** Gerente, Admin  
**Objetivo:** Permitir consulta das atividades realizadas no sistema

## Pré-condições
- Usuário deve estar autenticado

## Pós-condições
- Registros exibidos na tela

## Fluxo Principal
1. Usuário acessa a tela de auditoria  
2. Sistema exibe histórico de ações realizadas  
3. Usuário utiliza filtros para refinar a busca  
4. Sistema apresenta os resultados  

## Fluxos Alternativos

### A1 – Nenhum registro encontrado
1. Sistema informa que não há registros para os filtros selecionados  

## Regras de Negócio
- **RN08** Apenas gerente e administrador podem visualizar auditoria  

## Requisitos Relacionados
- **RF09** Registro de atividades do sistema  

---

# Caso de Uso 6: Visualizar Analíticas

**Caso de Uso:** Visualizar Analíticas  
**Ator:** Gerente, Admin  
**Objetivo:** Permitir análise de dados do sistema

## Pré-condições
- Usuário autenticado

## Pós-condições
- Relatórios exibidos com dados atualizados

## Fluxo Principal
1. Usuário acessa a tela de analíticas  
2. Sistema apresenta gráficos e indicadores  
3. Usuário seleciona filtros de período  
4. Sistema atualiza os dados exibidos  

## Fluxos Alternativos

### A1 – Falha ao carregar dados
1. Sistema informa erro na geração das analíticas  

## Regras de Negócio
- **RN09** Apenas gerente e administrador possuem acesso às analíticas  

## Requisitos Relacionados
- **RF10** Visualização de relatórios e gráficos  

---

# Caso de Uso 7: Acessar Configurações

**Caso de Uso:** Acessar Configurações  
**Ator:** Admin  
**Objetivo:** Permitir administração das configurações do sistema

## Pré-condições
- Administrador autenticado

## Pós-condições
- Configurações atualizadas no sistema

## Fluxo Principal
1. Administrador acessa a tela de configurações  
2. Sistema apresenta opções de configuração  
3. Administrador altera os parâmetros desejados  
4. Sistema salva as alterações  

## Fluxos Alternativos

### A1 – Configuração inválida
1. Sistema detecta erro  
2. Sistema solicita correção  

## Regras de Negócio
- **RN10** Apenas administradores podem alterar configurações  

## Requisitos Relacionados
- **RF11** Gerenciamento de configurações  
