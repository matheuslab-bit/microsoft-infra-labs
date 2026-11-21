#!/usr/bin/env node
'use strict';

// Verifica uma lista de serviços web (status HTTP e tempo de resposta) a partir de um arquivo JSON.
// A saída pode ser em tabela, para olhar na hora, ou em JSON, para alimentar Zabbix ou Grafana.
//
// Uso: node src/monitor-servicos.js servicos.json [--json]
// Formato do arquivo: [{ "nome": "Intranet", "url": "https://intranet", "statusEsperado": 200, "limiteMs": 1500 }]

const fs = require('node:fs');

function avaliar(servico, resultado) {
  if (resultado.erro) return { ...servico, status: 'FORA DO AR', detalhe: resultado.erro, tempoMs: null };
  const esperado = servico.statusEsperado ?? 200;
  const limite = servico.limiteMs ?? 2000;
  let status = 'OK';
  if (resultado.codigo !== esperado) status = 'ERRO';
  else if (resultado.tempoMs > limite) status = 'LENTO';
  return { ...servico, status, codigo: resultado.codigo, tempoMs: resultado.tempoMs };
}

async function checar(url, timeoutMs = 10000) {
  const inicio = Date.now();
  try {
    const resposta = await fetch(url, { method: 'GET', redirect: 'manual', signal: AbortSignal.timeout(timeoutMs) });
    return { codigo: resposta.status, tempoMs: Date.now() - inicio };
  } catch (e) {
    return { erro: e.name === 'TimeoutError' ? 'tempo esgotado' : (e.cause && e.cause.code) || e.message };
  }
}

async function main() {
  const [arquivo, ...resto] = process.argv.slice(2);
  if (!arquivo) {
    console.error('Uso: node src/monitor-servicos.js servicos.json [--json]');
    process.exit(2);
  }
  const servicos = JSON.parse(fs.readFileSync(arquivo, 'utf8'));
  const resultados = await Promise.all(servicos.map(async (s) => avaliar(s, await checar(s.url))));
  if (resto.includes('--json')) {
    console.log(JSON.stringify({ verificadoEm: new Date().toISOString(), resultados }, null, 2));
  } else {
    console.table(resultados.map((r) => ({ Serviço: r.nome, Status: r.status, HTTP: r.codigo ?? '-', 'Tempo (ms)': r.tempoMs ?? '-' })));
  }
  process.exit(resultados.some((r) => r.status !== 'OK') ? 1 : 0);
}

if (require.main === module) main();

module.exports = { avaliar };
