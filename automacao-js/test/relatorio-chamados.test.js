'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { parseCsv } = require('../src/csv');
const { resumir, gerarMarkdown, horasEntre } = require('../src/relatorio-chamados');

test('parseCsv lê cabeçalho, aspas com vírgula e ignora linhas vazias', () => {
  const linhas = parseCsv('a,b,c\n1,"x, y",3\n\n4,5,6\n');
  assert.equal(linhas.length, 2);
  assert.equal(linhas[0].b, 'x, y');
  assert.equal(linhas[1].c, '6');
});

test('horasEntre calcula a duração em horas', () => {
  assert.equal(horasEntre('2026-11-02T08:00', '2026-11-02T10:30'), 2.5);
});

test('resumir calcula volume, SLA e tempo médio', () => {
  const chamados = [
    { aberto_em: '2026-11-02T08:00', fechado_em: '2026-11-02T09:00', categoria: 'Rede', prioridade: 'Alta', sla_horas: '4' },
    { aberto_em: '2026-11-02T08:00', fechado_em: '2026-11-02T14:00', categoria: 'Rede', prioridade: 'Alta', sla_horas: '4' },
    { aberto_em: '2026-11-02T08:00', fechado_em: '', categoria: 'Telefonia', prioridade: 'Media', sla_horas: '8' },
  ];
  const r = resumir(chamados);
  assert.equal(r.total, 3);
  assert.equal(r.fechados, 2);
  assert.equal(r.abertos, 1);
  assert.equal(r.slaPct, 50);
  assert.equal(r.tempoMedioHoras, 3.5);
  assert.equal(r.porCategoria[0].nome, 'Rede');
  assert.equal(r.porCategoria[0].slaPct, 50);
  assert.equal(r.porCategoria[1].slaPct, null);
});

test('o arquivo de exemplo gera um relatório em Markdown', () => {
  const csv = fs.readFileSync(path.join(__dirname, '..', 'dados', 'chamados-exemplo.csv'), 'utf8');
  const md = gerarMarkdown(resumir(parseCsv(csv)));
  assert.match(md, /^# Relatório de chamados/);
  assert.match(md, /Chamados no período: \*\*16\*\*/);
  assert.match(md, /\| Telefonia \|/);
});
