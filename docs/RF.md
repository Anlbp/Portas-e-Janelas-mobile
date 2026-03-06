# Requisitos Funcionais (RF)
## Sistema de Gestão - Casa de Portas e Janelas



## RF01 - Autenticação de Usuário

**Descrição:**  
O sistema deve permitir que usuários autenticados (Operário, Gerente e Admin) realizem login utilizando e-mail e senha.

**Atores:**  
Usuário (Operário, Gerente, Admin)

**Regras associadas:**  
- O sistema deve validar as credenciais informadas.
- O sistema deve solicitar autenticação em dois fatores (2FA).
- O sistema deve bloquear o acesso após 5 tentativas inválidas.



## RF02 – Gerenciamento de Produtos

**Descrição:**  
O sistema deve permitir o gerenciamento de produtos (portas e janelas), incluindo cadastro, edição, remoção e busca.

**Atores:**  
Operário, Gerente, Admin

**Regras associadas:**  
- Operários podem apenas **adicionar** novos produtos.
- Gerentes e Administradores podem **editar, remover e visualizar** produtos.
- O sistema deve permitir busca de produtos por nome ou categoria.



## RF03 – Recomendações com Inteligência Artificial

**Descrição:**  
O sistema deve permitir que usuários utilizem uma ferramenta de inteligência artificial para obter recomendações de portas e janelas de acordo com as necessidades do cliente.

**Atores:**  
Operário, Gerente, Admin

**Regras associadas:**  
- O usuário deve informar características da necessidade do cliente (ex: ambiente, medidas, estilo, orçamento).
- O sistema deve processar essas informações utilizando um módulo de inteligência artificial.
- O sistema deve apresentar sugestões de produtos adequados às necessidades informadas.
