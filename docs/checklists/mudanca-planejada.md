# Checklist: mudança planejada (janela de manutenção)

Baseado na gestão de mudanças do ITIL, no tamanho certo para uma equipe pequena. Serve para atualização de servidor, troca de firewall, migração e qualquer coisa que possa parar um serviço.

## Planejamento

- [ ] O que vai mudar, por quê e qual o benefício, em duas ou três frases
- [ ] Sistemas e usuários afetados, e por quanto tempo
- [ ] Janela escolhida fora do horário de pico, combinada com os donos dos sistemas
- [ ] Passo a passo da execução escrito, com os comandos
- [ ] **Plano de volta** (rollback) escrito e com um tempo limite para decidir voltar
- [ ] Backup ou checkpoint feito antes, e conferido
- [ ] Aprovação registrada (gestor ou comitê de mudanças)
- [ ] Usuários avisados com antecedência

## Execução

- [ ] Aviso de início da janela
- [ ] Monitoramento acompanhado durante a mudança (Zabbix e Grafana abertos)
- [ ] Cada passo marcado com o horário
- [ ] Se algo sair do plano e passar do tempo limite: executar o rollback, sem improviso

## Validação e encerramento

- [ ] Testes combinados executados (o serviço sobe, usuários conseguem acessar)
- [ ] Dono do sistema confirmou que está tudo funcionando
- [ ] Aviso de fim da janela
- [ ] Documentação atualizada (diagramas, IPs, versões)
- [ ] Mudança encerrada com o resultado: concluída, concluída com ressalvas ou revertida
