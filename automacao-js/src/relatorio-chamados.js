#!/usr/bin/env node
'use strict';

// Lê a exportação de chamados (CSV) e monta um relatório em Markdown com volume, SLA e tempo médio
// de resolução, por categoria e por prioridade. Serve para a reunião semanal sem montar planilha à mão.
//
// Uso: node src/relatorio-chamados.js chamados.csv [--saida relatorio.md]
// Colunas esperadas: id, aberto_em, fechado_em, categoria, prioridade, sla_horas, status

const fs = require('node:fs');
const { parseCsv } = require('./csv');

const HORA = 60 * 60 * 1000;

function horasEntre(inicio, fim) {
  return (new Date(fim) - new Date(inicio)) / HORA;
}

function resumir(chamados) {
  const fechados = chamados.filter((c) => c.fechado_em);
  const dentroSla = fechados.filter((c) => horasEntre(c.aberto_em, c.fechado_em) <= Number(c.sla_horas));
  const tempos = fechados.map((c) => horasEntre(c.aberto_em, c.fechado_em));

  const agrupar = (campo) => {
    const grupos = {};
    for (const c of chamados) {
      const chave = c[campo] || '(sem valor)';
      grupos[chave] ??= { total: 0, fechados: 0, dentroSla: 0 };
      grupos[chave].total++;
      if (c.fechado_em) {
        grupos[chave].fechados++;
        if (horasEntre(c.aberto_em, c.fechado_em) <= Number(c.sla_horas)) grupos[chave].dentroSla++;
      }
    }
    return Object.entries(grupos)
      .map(([nome, g]) => ({ nome, ...g, slaPct: g.fechados ? (g.dentroSla / g.fechados) * 100 : null }))
      .sort((a, b) => b.total - a.total);
  };

  return {
    total: chamados.length,
    abertos: chamados.length - fechados.length,
    fechados: fechados.length,
    slaPct: fechados.length ? (dentroSla.length / fechados.length) * 100 : null,
    tempoMedioHoras: tempos.length ? tempos.reduce((a, b) => a + b, 0) / tempos.length : null,
    porCategoria: agrupar('categoria'),
    porPrioridade: agrupar('prioridade'),
  };
}

const pct = (v) => (v === null ? '-' : `${v.toFixed(1)}%`);
const horas = (v) => (v === null ? '-' : `${v.toFixed(1)} h`);

function gerarMarkdown(r, titulo = 'Relatório de chamados') {
  const tabela = (linhas) => [
    '| Nome | Total | Fechados | Dentro do SLA |',
    '| --- | ---: | ---: | ---: |',
    ...linhas.map((g) => `| ${g.nome} | ${g.total} | ${g.fechados} | ${pct(g.slaPct)} |`),
  ];
  return [
    `# ${titulo}`,
    '',
    `- Chamados no período: **${r.total}** (${r.fechados} fechados, ${r.abertos} em aberto)`,
    `- Fechados dentro do SLA: **${pct(r.slaPct)}**`,
    `- Tempo médio de resolução: **${horas(r.tempoMedioHoras)}**`,
    '',
    '## Por categoria',
    '',
    ...tabela(r.porCategoria),
    '',
    '## Por prioridade',
    '',
    ...tabela(r.porPrioridade),
    '',
  ].join('\n');
}

if (require.main === module) {
  const [arquivo, ...resto] = process.argv.slice(2);
  if (!arquivo) {
    console.error('Uso: node src/relatorio-chamados.js chamados.csv [--saida relatorio.md]');
    process.exit(2);
  }
  const relatorio = gerarMarkdown(resumir(parseCsv(fs.readFileSync(arquivo, 'utf8'))));
  const i = resto.indexOf('--saida');
  if (i >= 0 && resto[i + 1]) {
    fs.writeFileSync(resto[i + 1], relatorio, 'utf8');
    console.log(`Relatório salvo em ${resto[i + 1]}`);
  } else {
    console.log(relatorio);
  }
}

module.exports = { resumir, gerarMarkdown, horasEntre };
