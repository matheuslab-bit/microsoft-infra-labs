# Rastreabilidade: provar quem fez o quê, e quando

Em empresa que passa por auditoria (de qualidade, de cliente, de certificação ou de órgão fiscalizador), não basta o sistema funcionar. A TI precisa **provar** algumas coisas:

- quem acessou;
- o que mudou e quando;
- que o dado não foi alterado;
- que o backup volta.

Este guia junta o que a infraestrutura precisa ter para responder a essas perguntas sem correria quando o auditor chegar.

## Uma pessoa, uma conta

- Contas nominais no AD. Nada de conta compartilhada do tipo `producao` ou `laboratorio`: com ela, não dá para saber quem fez o quê.
- Política de senha e de bloqueio aplicada por GPO ([lab 04](../../labs/04-group-policy/README.md)), com regra mais rígida para as contas da TI.
- A conta administrativa fica separada da conta do dia a dia: quem administra o servidor entra com outra conta para ler e-mail.

## Todo mundo no mesmo horário

Se os relógios não batem, a ordem dos registros não se sustenta: um log diz que o arquivo foi alterado antes de ser criado, e a investigação para por aí.

- O DC com o papel de emulador de PDC sincroniza com uma fonte externa de NTP. O resto do domínio segue a hierarquia do AD.
- Equipamentos fora do domínio (switches, firewall, câmeras, relógio de ponto, máquinas com computador embarcado) apontam para o mesmo NTP interno.
- Para conferir: `w32tm /query /status` e `w32tm /monitor`.
- Um alerta no monitoramento quando um servidor passar de alguns segundos de diferença.

## Trilha de auditoria

- Política de auditoria do Windows por GPO: logon, bloqueio de conta, mudança em grupo privilegiado e acesso às pastas sensíveis.
- Eventos copiados para um servidor central, porque um log que fica só na máquina pode ser apagado por quem tem acesso a ela.
- A trilha precisa estar ligada **e** protegida: quem é auditado não pode ter permissão de editar o próprio registro.

## Quem tem acesso a quê

- Acesso sempre pelo grupo da função, nunca direto para a pessoa: o modelo AGDLP do [lab 05](../../labs/05-file-server/README.md).
- **Segregação de funções.** Quem administra o sistema não aprova os dados que passam por ele.
- **Revisão periódica com evidência.** Exportar os membros de cada grupo ([`Export-MembrosGrupo.ps1`](../../toolkit/powershell/Export-MembrosGrupo.ps1)), mandar para o dono do sistema aprovar e guardar a resposta.
- **Desligamento no mesmo dia** ([`Invoke-LabUserOffboarding.ps1`](../../labs/09-operations-automation/README.md)) e revisão das contas paradas ([`Get-LabStaleAccount.ps1`](../../labs/09-operations-automation/README.md)).

## Backup que prova integridade

- Procedimento escrito: o que entra no backup, com que frequência, onde fica a cópia e por quanto tempo.
- Hash de cada arquivo copiado, para provar que a cópia é igual ao original. O [lab 06](../../labs/06-backup-recovery/README.md) gera um manifesto com SHA-256.
- **Teste de restauração periódico, com o resultado guardado.** Um backup que nunca foi restaurado não serve como prova.
- Prazo de guarda definido pela área dona do dado, não pela TI: cada tipo de registro tem a sua exigência.
- Regra 3-2-1: três cópias, em duas mídias, uma fora do prédio.

## Mudança com evidência

É o checklist de [mudança planejada](../checklists/mudanca-planejada.md), com quatro cuidados a mais para os sistemas críticos:

1. **Avaliação de impacto** antes: a mudança afeta um sistema que guarda registros importantes? O que pode dar errado com os dados?
2. **Aprovação do dono do sistema**, não só da TI.
3. **Evidência anexada**: prints, saída dos comandos e horários.
4. **Teste depois**, para provar que o sistema continua fazendo o que fazia.

Uma mudança emergencial também é registrada, só que depois de executada.

## Servidor documentado desde a instalação

Antes de um servidor crítico entrar em uso, fica registrado:

- o que foi instalado, com versões;
- a configuração aplicada;
- a conferência contra o que foi pedido.

Daí em diante, qualquer alteração passa pela gestão de mudanças, e o registro mostra como o servidor estava em cada momento. O [checklist de servidor novo](../checklists/servidor-novo.md) é o ponto de partida.

## Incidentes

Um incidente num sistema crítico (servidor parado, backup que falhou, acesso indevido) é registrado, investigado até a causa raiz e fechado com uma ação para não acontecer de novo. Não basta resolver: a investigação precisa ficar escrita.

## Fornecedores e nuvem

Quando um sistema crítico roda num fornecedor (SaaS, nuvem ou suporte terceirizado), o contrato deixa escrito:

- quem faz o backup;
- quem controla o acesso;
- quem avisa em caso de incidente, e em quanto tempo.

O provedor é avaliado antes de receber o sistema.

## Onde pratico cada item

| Item | Onde |
| --- | --- |
| Contas nominais e política de senha | [Lab 02](../../labs/02-active-directory/README.md) e [lab 04](../../labs/04-group-policy/README.md) |
| Acesso por grupo de função | [Lab 05](../../labs/05-file-server/README.md) |
| Backup com hash e teste de restauração | [Lab 06](../../labs/06-backup-recovery/README.md) |
| Monitoramento e alertas | [Lab 07](../../labs/07-monitoring-zabbix/README.md) e [lab 10](../../labs/10-grafana-dashboards/README.md) |
| Desligamento e contas paradas | [Lab 09](../../labs/09-operations-automation/README.md) |
| Configuração versionada e revisada antes de aplicar | [google-cloud-portfolio](https://github.com/matheuslab-bit/google-cloud-portfolio): Terraform com `plan` revisado em pull request |
| Alerta de mudança de permissão | [Lab 04 do Google Cloud](https://github.com/matheuslab-bit/google-cloud-portfolio/tree/main/projects/04-monitoring-alerts): e-mail a cada mudança de IAM, testado |

O que ainda vou transformar em lab está no [ROADMAP](../../ROADMAP.md): hierarquia de NTP com alerta, política de auditoria com eventos centralizados e o registro de instalação de um servidor gerado por script.
