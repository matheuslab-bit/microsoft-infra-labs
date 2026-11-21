#!/usr/bin/env node
'use strict';

// Conecta em cada site/servidor, lê o certificado TLS e avisa quantos dias faltam para vencer.
// Certificado vencido derruba sistema e costuma ser descoberto pelo usuário. Este script avisa antes.
//
// Uso: node src/verificar-certificados.js site1.com site2.com:8443 [--limite 30]
// Sai com código 1 se algum certificado estiver dentro do limite, vencido ou inacessível.

const tls = require('node:tls');

const DIA = 24 * 60 * 60 * 1000;

function diasRestantes(validoAte, agora = new Date()) {
  return Math.floor((new Date(validoAte) - agora) / DIA);
}

function classificar(dias, limite) {
  if (dias < 0) return 'VENCIDO';
  if (dias <= limite) return 'VENCE EM BREVE';
  return 'OK';
}

function lerCertificado(alvo, timeoutMs = 8000) {
  const [host, porta = '443'] = alvo.split(':');
  return new Promise((resolve) => {
    const socket = tls.connect({ host, port: Number(porta), servername: host, timeout: timeoutMs }, () => {
      const cert = socket.getPeerCertificate();
      socket.end();
      resolve({ alvo, validoAte: cert.valid_to, emissor: cert.issuer && cert.issuer.O });
    });
    socket.on('timeout', () => {
      socket.destroy();
      resolve({ alvo, erro: 'tempo esgotado' });
    });
    socket.on('error', (e) => resolve({ alvo, erro: e.code || e.message }));
  });
}

async function main() {
  const args = process.argv.slice(2);
  let limite = 30;
  const alvos = [];
  for (let j = 0; j < args.length; j++) {
    if (args[j] === '--limite') {
      limite = Number(args[++j]);
    } else {
      alvos.push(args[j]);
    }
  }
  if (alvos.length === 0) {
    console.error('Uso: node src/verificar-certificados.js site1.com [site2.com:8443] [--limite 30]');
    process.exit(2);
  }
  let problema = false;
  const linhas = [];
  for (const r of await Promise.all(alvos.map((a) => lerCertificado(a)))) {
    if (r.erro) {
      problema = true;
      linhas.push({ Alvo: r.alvo, Status: 'ERRO', Dias: '-', 'Vence em': '-', Detalhe: r.erro });
      continue;
    }
    const dias = diasRestantes(r.validoAte);
    const status = classificar(dias, limite);
    if (status !== 'OK') problema = true;
    linhas.push({ Alvo: r.alvo, Status: status, Dias: dias, 'Vence em': new Date(r.validoAte).toLocaleDateString('pt-BR'), Detalhe: r.emissor || '' });
  }
  console.table(linhas);
  process.exit(problema ? 1 : 0);
}

if (require.main === module) main();

module.exports = { diasRestantes, classificar };
