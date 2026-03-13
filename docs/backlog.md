# 📋 Backlog do Projeto: Casa de Portas e Janelas

## 🎯 Visão do Produto
Aplicativo mobile-first para operários da construção civil que atua como um **assistente inteligente de vendas**, permitindo consulta de produtos, recomendações baseadas em IA, gestão de relacionamento com clientes e auditoria para gestores.

---

## 🏗️ Épico 1: Catálogo de Produtos e Visão Técnica
**Objetivo:** Permitir que operários consultem o portfólio completo de portas e janelas com detalhes técnicos e visuais.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | PROD-01 | Operário | Visualizar lista completa de portas e janelas | Conhecer os produtos disponíveis em estoque | [ ] Scroll infinito ou paginação<br>[ ] Filtro por categoria (porta/janela)<br>[ ] Thumbnail da imagem |
| 🟥 Alta | PROD-02 | Operário | Ver detalhes técnicos de um produto (dimensões, material, cor) | Verificar se atende às necessidades da obra | [ ] Exibir ficha técnica<br>[ ] Informar disponibilidade em estoque<br>[ ] Botão "Compartilhar" |
| 🟨 Média | PROD-03 | Operário | Buscar produtos por nome ou código | Agilizar a consulta no dia a dia | [ ] Busca por texto com autocomplete<br>[ ] Busca por código de barras (câmera) |
| 🟩 Baixa | PROD-04 | Admin | Importar novo catálogo via planilha | Atualizar produtos em massa | [ ] Validação de formato .csv/.xlsx<br>[ ] Log de erros de importação |

---

## 📊 Épico 2: Analytics e Métricas de Vendas
**Objetivo:** Fornecer dashboards e insights sobre o desempenho de produtos e vendas.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | ANAL-01 | Operário | Visualizar produtos mais consultados no dia | Saber o que está em alta | [ ] Ranking top 5/10<br>[ ] Atualização em tempo real |
| 🟨 Média | ANAL-02 | Gerente | Acompanhar métricas de conversão (consulta x venda) | Avaliar desempenho da equipe | [ ] Gráficos comparativos por período<br>[ ] Exportar relatório PDF |
| 🟨 Média | ANAL-03 | Admin | Ver histórico de preços por produto | Auditar reajustes | [ ] Linha do tempo com data/alteração |

---

## 👥 Épico 3: CRM e Gestão de Clientes
**Objetivo:** Centralizar informações de clientes e histórico de atendimento.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | CRM-01 | Operário | Cadastrar novo cliente com dados básicos (nome, CPF/CNPJ, telefone) | Iniciar um atendimento formal | [ ] Validação de CPF/CNPJ<br>[ ] Evitar duplicidade |
| 🟥 Alta | CRM-02 | Operário | Consultar cliente por telefone ou nome | Acessar rapidamente o histórico | [ ] Busca full-text<br>[ ] Exibir últimos contatos |
| 🟨 Média | CRM-03 | Operário | Registrar interação com cliente (ex: "orçamento enviado") | Manter histórico atualizado | [ ] Timestamp automático<br>[ ] Campo de observações livres |
| 🟩 Baixa | CRM-04 | Gerente | Visualizar mapa de clientes por região | Planejar ações de marketing local | [ ] Integração com Google Maps |

---

## 🤖 Épico 4: Assistente IA de Recomendações
**Objetivo:** Usar inteligência artificial para sugerir produtos com base nas necessidades do cliente.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | IA-01 | Operário | Responder perguntas sobre a obra (ex: "porta para área externa") | Receber sugestões personalizadas de produtos | [ ] IA considera: local, clima, tamanho<br>[ ] Exibir até 5 sugestões ranqueadas |
| 🟥 Alta | IA-02 | Operário | Informar medidas do vão | Obter lista de produtos compatíveis | [ ] Calcular folgas recomendadas<br>[ ] Alertar se medida for atípica |
| 🟨 Média | IA-03 | Operário | Enviar foto do local | IA identificar tipo de abertura necessária | [ ] Upload de imagem<br>[ ] Análise básica de imagem (ML Kit) |
| 🟩 Baixa | IA-04 | Admin | Treinar modelo com novos produtos | Manter recomendações atualizadas | [ ] Dashboard de "aprendizado" |

---

## 🔒 Épico 5: Registro de Auditoria (Logs)
**Objetivo:** Garantir rastreabilidade total das ações no sistema para gerentes e administradores.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | AUD-01 | Gerente | Visualizar log detalhado de ações por operário | Auditar possíveis erros ou fraudes | [ ] Filtro por data, operário, ação<br>[ ] Exportar CSV |
| 🟥 Alta | AUD-02 | Admin | Receber alertas automáticos de ações suspeitas | Agir rapidamente | [ ] Regras configuráveis (ex: consultas em massa)<br>[ ] Notificação push/email |
| 🟨 Média | AUD-03 | Gerente | Ver quem visualizou dados sensíveis de clientes | Garantir conformidade com LGPD | [ ] Logs imutáveis<br>[ ] Indicação de "visualização indevida" |
| 🟨 Média | AUD-04 | Admin | Reverter ações indevidas (ex: deleção acidental) | Corrigir erros rapidamente | [ ] Botão de "restaurar" com justificativa |

---

## 🔐 Épico 6: Autenticação e Segurança de Acesso
**Objetivo:** Garantir que apenas usuários autorizados acessem o sistema, com diferentes níveis de segurança baseados no perfil (operário, gerente, admin).

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | AUTH-01 | Usuário (todos) | Fazer login com e-mail e senha | Acessar o aplicativo de forma segura | [ ] Validação de e-mail válido<br>[ ] Senha com mínimo 8 caracteres<br>[ ] Botão "Mostrar/Esconder" senha<br>[ ] Mensagem de erro clara para credenciais inválidas<br>[ ] "Lembrar-me" por 7 dias |
| 🟥 Alta | AUTH-02 | Usuário (todos) | Visualizar tela de boas-vindas com campo de login | Iniciar o processo de autenticação | [ ] Logo da empresa<br>[ ] Campo e-mail<br>[ ] Campo senha<br>[ ] Botão "Entrar"<br>[ ] Link "Esqueci minha senha"<br>[ ] Link "Solicitar acesso" (para novos usuários) |
| 🟥 Alta | AUTH-03 | Admin | Gerenciar usuários (criar, editar, desativar) | Controlar quem tem acesso ao sistema | [ ] Lista de usuários com status (ativo/inativo)<br>[ ] Botão "Novo usuário"<br>[ ] Atribuição de perfil (operário/gerente/admin)<br>[ ] Reset de senha forçado no primeiro acesso |

---

## 📱 Épico 7: Autenticação Biométrica
**Objetivo:** Permitir acesso rápido e seguro via biometria do dispositivo (impressão digital ou reconhecimento facial).

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | BIO-01 | Usuário (todos) | Ativar login por biometria após primeiro acesso | Acessar o app rapidamente sem digitar senha | [ ] Tela de "Configurar biometria" no primeiro login<br>[ ] Verificar se dispositivo suporta biometria<br>[ ] Opção "Pular por enquanto"<br>[ ] Feedback de sucesso/erro na configuração |
| 🟥 Alta | BIO-02 | Usuário (todos) | Fazer login usando impressão digital | Entrar no app de forma rápida e segura | [ ] Tela inicial com opção "Login com biometria"<br>[ ] Fallback para senha se biometria falhar 3x<br>[ ] Animação de reconhecimento |
| 🟥 Alta | BIO-03 | Usuário (todos) | Fazer login usando reconhecimento facial (Face ID / Android Face) | Alternativa à digital em dispositivos compatíveis | [ ] Detecção automática do método disponível<br>[ ] Priorizar biometria mais segura do dispositivo<br>[ ] Funcionar em diferentes condições de luz |
| 🟨 Média | BIO-04 | Usuário (todos) | Gerenciar preferências biométricas nas configurações | Ativar/desativar biometria quando desejar | [ ] Toggle "Login biométrico"<br>[ ] Opção "Reconfigurar biometria"<br>[ ] Mensagem de confirmação |
| 🟨 Média | BIO-05 | Gerente/Admin | Exigir biometria para ações sensíveis | Aumentar segurança em operações críticas | [ ] Configuração por perfil<br>[ ] Solicitar biometria antes de ações como: excluir cliente, alterar preços, ver logs de auditoria |

---

## 🔑 Épico 8: Autenticação de Dois Fatores (2FA)
**Objetivo:** Adicionar camada extra de segurança, especialmente para gerentes e administradores.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | 2FA-01 | Gerente/Admin | Ativar autenticação de dois fatores | Proteger minha conta contra acessos não autorizados | [ ] Opção "Ativar 2FA" nas configurações<br>[ ] Escolher método (SMS ou Google Authenticator)<br>[ ] Código de verificação para ativar |
| 🟥 Alta | 2FA-02 | Gerente/Admin | Fazer login com 2FA via SMS | Garantir que só eu acesse mesmo com senha vazada | [ ] Enviar código de 6 dígitos por SMS<br>[ ] Código válido por 5 minutos<br>[ ] Reenviar código (com limite de 3x) |
| 🟥 Alta | 2FA-03 | Gerente/Admin | Fazer login com 2FA via aplicativo autenticador (Google/Microsoft) | Usar método mais seguro que SMS | [ ] QR Code para escanear<br>[ ] Código de backup para recuperação<br>[ ] Sincronização com horário do servidor |
| 🟥 Alta | 2FA-04 | Admin | Exigir 2FA obrigatório para todos os gerentes | Garantir política de segurança da empresa | [ ] Configuração "2FA obrigatório" no painel admin<br>[ ] Bloquear login de gerentes sem 2FA ativo<br>[ ] Notificação por e-mail para gerentes sem 2FA |
| 🟨 Média | 2FA-05 | Gerente/Admin | Visualizar códigos de backup | Recuperar acesso se perder o celular | [ ] Gerar 10 códigos de uso único<br>[ ] Opção de baixar/imprimir<br>[ ] Regenerar códigos (invalidando anteriores) |
| 🟨 Média | 2FA-06 | Gerente/Admin | Desativar 2FA (com confirmação) | Caso necessário, com segurança | [ ] Confirmar senha atual<br>[ ] Enviar e-mail de notificação<br>[ ] Período de carência de 24h (opcional) |
| 🟩 Baixa | 2FA-07 | Operário | Ativar 2FA opcionalmente | Ter segurança extra mesmo sendo operário | [ ] Mesmas funcionalidades do 2FA para gerente<br>[ ] Não obrigatório, apenas opt-in |

---

## 🔄 Épico 9: Recuperação de Senha
**Objetivo:** Permitir que usuários recuperem acesso à conta de forma segura quando esquecem a senha.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | REC-01 | Usuário (todos) | Solicitar recuperação de senha pela tela de login | Reaver acesso à minha conta | [ ] Link "Esqueci minha senha" na tela de login<br>[ ] Campo para informar e-mail cadastrado<br>[ ] Mensagem de confirmação (mesmo para e-mails não cadastrados - segurança) |
| 🟥 Alta | REC-02 | Usuário (todos) | Receber e-mail com link de recuperação | Criar uma nova senha | [ ] E-mail enviado em até 30 segundos<br>[ ] Link válido por 1 hora<br>[ ] Link de uso único |
| 🟥 Alta | REC-03 | Usuário (todos) | Criar nova senha através do link recebido | Recuperar o acesso ao app | [ ] Página segura (https)<br>[ ] Validação de senha forte<br>[ ] Confirmar nova senha<br>[ ] Feedback de sucesso/erro |
| 🟨 Média | REC-04 | Usuário (todos) | Receber confirmação de alteração de senha por e-mail | Saber que a alteração foi realizada com sucesso | [ ] E-mail automático após mudança<br>[ ] Aviso sobre troca de senha (segurança) |
| 🟨 Média | REC-05 | Admin | Visualizar relatório de solicitações de recuperação | Monitorar tentativas de acesso | [ ] Log com data/hora, usuário, IP<br>[ ] Alertar sobre múltiplas tentativas falhas |
| 🟨 Média | REC-06 | Usuário (todos) | Responder perguntas de segurança (opcional) | Camada extra na recuperação | [ ] Configurar 3 perguntas no primeiro acesso<br>[ ] Responder para receber link de recuperação |
| 🟩 Baixa | REC-07 | Gerente/Admin | Recuperar senha via SMS (fallback) | Alternativa se não acessar e-mail | [ ] Vincular celular no cadastro<br>[ ] Código enviado por SMS válido por 10 minutos |

---

## 📋 Épico 10: Sessão e Segurança Contínua
**Objetivo:** Gerenciar sessões ativas e garantir segurança durante o uso do aplicativo.

### User Stories

| Prioridade | Story ID | Como... | Quero... | Para que... | Critérios de Aceitação |
|------------|----------|---------|----------|-------------|------------------------|
| 🟥 Alta | SESS-01 | Usuário (todos) | Permanecer logado após fechar o app | Não precisar digitar senha toda vez | [ ] Token de refresh válido por 30 dias<br>[ ] Logout automático após inatividade (configurável) |
| 🟥 Alta | SESS-02 | Usuário (todos) | Fazer logout manualmente | Sair da conta em dispositivos compartilhados | [ ] Botão "Sair" no menu<br>[ ] Confirmar ação<br>[ ] Redirecionar para tela de login |
| 🟥 Alta | SESS-03 | Usuário (todos) | Visualizar meu perfil com dados do usuário | Confirmar minha identidade | [ ] Foto/avatar<br>[ ] Nome completo<br>[ ] E-mail<br>[ ] Perfil (operário/gerente/admin)<br>[ ] Botão "Editar perfil" |
| 🟨 Média | SESS-04 | Usuário (todos) | Editar meus dados de perfil (nome, telefone) | Manter informações atualizadas | [ ] Validar campos obrigatórios<br>[ ] Confirmar alterações por e-mail |
| 🟨 Média | SESS-05 | Usuário (todos) | Visualizar dispositivos onde estou logado | Monitorar acessos à minha conta | [ ] Lista com: dispositivo, localização aproximada, último acesso<br>[ ] Botão "Desconectar dispositivo" |
| 🟨 Média | SESS-06 | Admin | Forçar logout de usuários específicos | Bloquear acesso em caso de suspeita | [ ] Painel admin com lista de sessões ativas<br>[ ] Botão "Revogar acesso" |
| 🟩 Baixa | SESS-07 | Admin | Configurar políticas de senha | Garantir conformidade com segurança | [ ] Tamanho mínimo<br>[ ] Exigir caracteres especiais<br>[ ] Expiração de senha a cada X dias |

---

## 🔒 Backlog Consolidado - Épicos de Autenticação

### 📊 Visão Geral dos Novos Épicos

| Épico | Foco Principal | Stories | Prioridade |
|-------|----------------|---------|------------|
| **06 - Autenticação** | Login básico e gestão de usuários | 3 | 🟥 Crítica |
| **07 - Biometria** | Impressão digital e facial | 5 | 🟥 Crítica |
| **08 - 2FA** | Dois fatores para gerentes/admins | 7 | 🟥 Crítica |
| **09 - Recuperação** | Esqueci minha senha | 7 | 🟥 Crítica |
| **10 - Sessão** | Perfil e dispositivos | 7 | 🟨 Alta |

### 🚀 Prioridade para Implementação (Sprints Iniciais)

1. **Sprint 1 - Base de Autenticação**
   - `AUTH-02` - Tela de login
   - `AUTH-01` - Login com e-mail/senha
   - `REC-01` a `REC-03` - Fluxo completo de recuperação de senha

2. **Sprint 2 - Biometria e Perfil**
   - `BIO-01` a `BIO-03` - Configuração e uso de biometria
   - `SESS-01` a `SESS-03` - Sessão persistente e perfil

3. **Sprint 3 - Administração e 2FA**
   - `AUTH-03` - Gestão de usuários (admin)
   - `2FA-01` a `2FA-03` - 2FA básico para gerentes/admins

4. **Sprints Futuras**
   - `2FA-04` a `2FA-07` - Políticas avançadas de 2FA
   - `BIO-04` a `BIO-05` - Configurações avançadas de biometria
   - `SESS-04` a `SESS-07` - Sessões e políticas

### 📝 Notas Técnicas Específicas para Autenticação

- **Tokens:** JWT com refresh token armazenado em HTTP-only cookie ou Secure Storage (mobile)
- **Biometria:** React Native Biometrics / LocalAuthentication (expo)
- **2FA:** Implementar TOTP (RFC 6238) compatível com Google Authenticator
- **E-mails:** Serviço transacional (SendGrid, AWS SES) com templates personalizados
- **Rate limiting:** Prevenir brute force em login e recuperação de senha
- **LGPD/GDPR:** Consentimento explícito para coleta de dados biométricos
- **Offline:** Permitir login biométrico offline (último token válido)

## 🧩 Backlog Consolidado (Visão Geral)

### 🔝 Topo da Fila (Próxima Sprint)
1. `PROD-01` - Lista de produtos com filtros
2. `CRM-01` - Cadastro de clientes
3. `IA-01` - Recomendações baseadas em perguntas
4. `AUD-01` - Log de ações do operário

### 📌 Prioridade Alta (Próximas Sprints)
- `PROD-02` - Detalhes técnicos do produto
- `CRM-02` - Consulta de cliente por telefone
- `ANAL-01` - Dashboard de consultas
- `IA-02` - Recomendações por medidas
- `AUD-02` - Alertas automáticos

### ⏳ Futuro (Refinamento Pendente)
- `PROD-04` - Importação em massa
- `CRM-04` - Mapa de clientes
- `IA-04` - Treinamento do modelo
- `AUD-04` - Reverter ações indevidas

---

## 📝 Notas Técnicas para o Time de Dev

- **Stack sugerida:** React Native (mobile), Node.js (API), PostgreSQL, Redis (cache), TensorFlow Lite (IA on-device)
- **Autenticação:** Firebase Auth com perfis (operário, gerente, admin)
- **Offline-first:** Operários podem estar em áreas sem internet; sincronizar quando online
- **LGPD:** Campo de observações em CRM deve ter aviso de consentimento
