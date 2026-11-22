# Infraestrutura de TI numa indústria farmacêutica: o que muda

Escrevi este guia enquanto estudava o trabalho de infraestrutura numa fábrica de medicamentos. A parte técnica é a mesma de qualquer empresa: servidores, AD, rede, backup e monitoramento. O que muda é a regra do jogo. A Anvisa fiscaliza a fábrica, e um sistema que guarda dados de produção ou de qualidade faz parte do processo de fabricação. Se um dado some, ou pode ser alterado sem deixar rastro, o problema deixa de ser só de TI: vira um problema de qualidade, que pode atingir um lote inteiro.

## As normas que se aplicam

| Norma | O que diz para a TI |
| --- | --- |
| **RDC 658/2022** (Anvisa) | Boas Práticas de Fabricação (BPF) de medicamentos. É a base de tudo |
| **IN 134/2022** (Anvisa) | Complementa a RDC 658 para **sistemas computadorizados**. Foi baseada no Anexo 11 do PIC/S. Cobre validação, segurança, trilha de auditoria, backup, gestão de mudanças, incidentes e fornecedores |
| **Guia Anvisa nº 33/2020** | Guia de validação de sistemas computadorizados. Não é obrigatório, mas mostra o que a fiscalização espera ver |
| **GAMP 5** (ISPE) | Referência de mercado para validar sistemas com abordagem baseada em risco |
| **21 CFR Part 11** (FDA) | Registros e assinaturas eletrônicas. Só se aplica se a fábrica exportar para os Estados Unidos |
| **LGPD** (Lei 13.709/2018) | Dados pessoais de colaboradores, médicos e pacientes (por exemplo, em farmacovigilância) |

Na prática, quem decide se um sistema é GxP é a Garantia da Qualidade. O papel da TI é manter esses sistemas sob controle e conseguir provar isso numa auditoria.

> **GxP** é o nome que junta as "boas práticas" (de fabricação, de laboratório, de distribuição). Um sistema GxP é qualquer sistema que guarda, processa ou controla dados usados nessas atividades.

## Onde a infraestrutura entra

No GAMP 5, o software de infraestrutura (sistema operacional, banco de dados, rede, ferramenta de backup, antivírus) fica na **categoria 1**. Ele não é validado como uma aplicação, mas precisa estar **qualificado e controlado**:

- instalado conforme uma especificação documentada (a qualificação de instalação, ou IQ);
- com a configuração registrada e sob controle de mudanças;
- monitorado, com backup testado.

As aplicações GxP rodam em cima dessa base: o LIMS do laboratório, o MES da produção, os módulos de qualidade do ERP, o software dos equipamentos de laboratório. Se alguém atualiza o servidor de um desses sistemas sem controle, a validação da aplicação fica comprometida. É por isso que, numa farmacêutica, a "simples atualização de Windows" passa pelo controle de mudanças.

## Integridade de dados (ALCOA+)

A fiscalização avalia a integridade dos dados pelo princípio ALCOA+. Cada letra tem uma tarefa clara para a infraestrutura:

| Princípio | O que significa | O que a infraestrutura faz |
| --- | --- | --- |
| **A**tribuível | Dá para saber quem fez | Contas nominais no AD, nenhuma conta compartilhada, senha e bloqueio definidos por GPO |
| **L**egível | Dá para ler durante todo o prazo de guarda | Backup em formato que continue legível; plano para quando o software antigo sair de uso |
| **C**ontemporâneo | Registrado na hora em que aconteceu | **Horário sincronizado** em todos os servidores, estações e equipamentos (NTP). Um relógio errado invalida a ordem dos registros |
| **O**riginal | O primeiro registro, ou uma cópia certificada | Permissões que impedem apagar ou sobrescrever; cópias com conferência de hash |
| **A**curado (exato) | Correto e sem alteração indevida | Controle de acesso por função; trilha de auditoria ligada e protegida contra edição |
| **+** Completo, consistente, duradouro, disponível | Nada se perde e tudo pode ser recuperado | Logs centralizados, backup testado, plano de recuperação de desastre |

## Controle de acesso

- **Perfis por função.** Cada pessoa recebe acesso pelo grupo da sua função, nunca de forma individual (o modelo AGDLP do [lab 05](../../labs/05-file-server/README.md)).
- **Segregação.** O administrador de TI não deve ser a mesma pessoa que aprova dados de qualidade no sistema, e a conta administrativa é separada da conta do dia a dia.
- **Revisão periódica de acessos, com evidência.** Exportar quem está em cada grupo, mandar para o dono do sistema aprovar e guardar o registro. O [`Export-MembrosGrupo.ps1`](../../toolkit/powershell/Export-MembrosGrupo.ps1) gera essa lista.
- **Desligamento no mesmo dia.** A conta de quem saiu é desativada imediatamente ([`Invoke-LabUserOffboarding.ps1`](../../labs/09-operations-automation/README.md)), e contas paradas são revisadas ([`Get-LabStaleAccount.ps1`](../../labs/09-operations-automation/README.md)).

## Backup e restauração

- Procedimento escrito: o que entra no backup, com que frequência, onde fica a cópia e por quanto tempo.
- **Teste de restauração periódico, com evidência guardada.** Um backup que nunca foi restaurado não conta numa auditoria. O [lab 06](../../labs/06-backup-recovery/README.md) faz isso: confere o hash SHA-256 de cada arquivo e testa a restauração.
- Prazo de guarda definido com a Garantia da Qualidade, que conhece o prazo exigido para cada tipo de registro.
- Cópia fora do prédio (regra 3-2-1: três cópias, em duas mídias, uma fora do local).

## Controle de mudanças

É o mesmo processo do checklist de [mudança planejada](../checklists/mudanca-planejada.md), com etapas a mais quando o sistema é GxP:

1. **Avaliação de impacto GxP**: a mudança afeta um sistema validado? Qual o risco para os dados?
2. **Aprovação da Garantia da Qualidade**, além da aprovação de TI.
3. Execução com **evidência anexada**: prints, saída dos comandos, horários.
4. **Requalificação**, se a mudança alterar o que estava qualificado.
5. Encerramento formal no sistema de mudanças.

Uma mudança emergencial também é registrada, só que depois de executada.

## Incidentes e desvios

Um incidente que atinge um sistema GxP (servidor fora do ar, backup que falhou, acesso indevido) é registrado, investigado até a causa raiz e pode virar um **desvio** com ação corretiva e preventiva (CAPA). Investigar a causa raiz já faz parte do meu dia a dia como N2. Aqui ela também precisa ficar documentada.

## Fornecedores e nuvem

A IN 134 pede acordos formais com quem presta serviço para sistemas GxP, nuvem incluída. Antes de colocar um sistema GxP num SaaS ou num provedor de nuvem, a empresa avalia o fornecedor e documenta as responsabilidades de cada lado: quem faz backup, quem controla o acesso e quem avisa em caso de incidente.

## Rede industrial (TI e OT)

A fábrica tem duas redes com prioridades diferentes:

- **TI** (escritório): e-mail, ERP, arquivos. A prioridade é a segurança, e o padrão é atualizar sempre.
- **OT** (produção e laboratório): máquinas de envase e embalagem, CLPs, supervisórios (SCADA), equipamentos de laboratório ligados a computadores. A prioridade é a máquina não parar, e muitos desses equipamentos rodam Windows antigo que não pode ser atualizado sem revalidar o equipamento.

O que fazer:

- **Separar as redes** em VLANs e zonas de firewall, com regras só para o que precisa passar. É o modelo Purdue, base da norma **ISA/IEC 62443**. No [lab 08](../../labs/08-fortigate-segmentation/README.md) separo servidores, estações e gerência no FortiGate. Uma fábrica acrescenta as VLANs da produção e do laboratório.
- **Isolar o equipamento que não pode ser atualizado**, em vez de atualizá-lo sem validar.
- **Acesso remoto de fornecedor controlado**: liberado só durante o atendimento, registrado e nunca com a máquina ligada direto na internet.

## Como os meus labs se encaixam

| Exigência | Onde pratico |
| --- | --- |
| Contas nominais, política de senha | [Lab 02](../../labs/02-active-directory/README.md) e [lab 04](../../labs/04-group-policy/README.md) |
| Acesso por grupo de função | [Lab 05](../../labs/05-file-server/README.md) |
| Backup com hash e teste de restauração | [Lab 06](../../labs/06-backup-recovery/README.md) |
| Monitoramento e alertas | [Lab 07](../../labs/07-monitoring-zabbix/README.md) e [lab 10](../../labs/10-grafana-dashboards/README.md) |
| Segmentação de rede | [Lab 08](../../labs/08-fortigate-segmentation/README.md) |
| Desligamento e contas paradas | [Lab 09](../../labs/09-operations-automation/README.md) |
| Mudança com plano de volta | [Checklist de mudança planejada](../checklists/mudanca-planejada.md) |
| Configuração versionada e revisada antes de aplicar | [google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio): Terraform com `plan` revisado em pull request |
| Alerta de mudança de permissão | [Lab 04 do Google Cloud](https://github.com/matheuslab-bit/google-cloud-portfolio/tree/main/projects/04-monitoring-alerts): alerta por e-mail a cada mudança de IAM, testado |

O que ainda não pratiquei e está no [ROADMAP](../../ROADMAP.md): hierarquia de NTP com alerta de relógio fora do horário, política de auditoria do Windows com eventos centralizados e um roteiro de qualificação de instalação (IQ) para um servidor novo.

## Fontes

- [IN 134/2022 - Anvisa](https://www.gov.br/anvisa/en/rules-and-regulations/arquivos/in-134_2022.pdf)
- RDC 658/2022 - Anvisa (Boas Práticas de Fabricação de Medicamentos)
- Guia Anvisa nº 33/2020 (validação de sistemas computadorizados)
- ISPE GAMP 5, 2ª edição
- ISA/IEC 62443 (segurança de automação industrial)
