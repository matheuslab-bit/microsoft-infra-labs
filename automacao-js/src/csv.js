'use strict';

// Lê CSV simples com cabeçalho. Aceita campos entre aspas (com vírgula dentro) e linhas em branco.
function parseCsv(texto) {
  const linhas = texto.replace(/^﻿/, '').split(/\r?\n/).filter((l) => l.trim() !== '');
  if (linhas.length === 0) return [];
  const cabecalho = dividirLinha(linhas[0]);
  return linhas.slice(1).map((linha) => {
    const valores = dividirLinha(linha);
    return Object.fromEntries(cabecalho.map((campo, i) => [campo, (valores[i] ?? '').trim()]));
  });
}

function dividirLinha(linha) {
  const campos = [];
  let atual = '';
  let entreAspas = false;
  for (let i = 0; i < linha.length; i++) {
    const c = linha[i];
    if (c === '"' && linha[i + 1] === '"' && entreAspas) {
      atual += '"';
      i++;
    } else if (c === '"') {
      entreAspas = !entreAspas;
    } else if (c === ',' && !entreAspas) {
      campos.push(atual);
      atual = '';
    } else {
      atual += c;
    }
  }
  campos.push(atual);
  return campos;
}

module.exports = { parseCsv };
