# Regras de Negócio (RN)
## Sistema de Gestão - Casa de Portas e Janelas


## RN01 - Controle de Permissões de Usuário

**Descrição:**  
O sistema deve aplicar diferentes níveis de permissão para cada tipo de usuário.

**Regras:**
- Operários podem apenas **adicionar** novos produtos e clientes.
- Gerentes podem **visualizar, editar e remover** produtos e clientes.
- Administradores possuem **acesso total ao sistema**, incluindo configurações.


## RN02 - Registro de Auditoria

**Descrição:**  
O sistema deve registrar automaticamente todas as ações importantes realizadas pelos usuários.

**Regras:**
- Alterações em produtos e clientes devem ser registradas.
- O registro deve armazenar **usuário, data, hora e ação realizada**.
- Apenas **Gerentes e Administradores** podem visualizar os registros de auditoria.


## RN03 - Recomendações com Inteligência Artificial

**Descrição:**  
O sistema deve gerar recomendações de portas e janelas com base nas informações fornecidas pelo usuário.

**Regras:**
- O usuário deve informar características do projeto ou necessidade do cliente (ex: ambiente, tamanho, estilo ou orçamento).
- O sistema deve analisar essas informações utilizando o módulo de inteligência artificial.
- As recomendações devem sugerir **produtos compatíveis disponíveis no catálogo do sistema**.
