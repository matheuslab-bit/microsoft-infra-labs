'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { diasRestantes, classificar } = require('../src/verificar-certificados');
const { avaliar } = require('../src/monitor-servicos');

test('diasRestantes conta os dias até o vencimento', () => {
  const agora = new Date('2026-11-21T00:00:00Z');
  assert.equal(diasRestantes('2026-12-21T00:00:00Z', agora), 30);
  assert.equal(diasRestantes('2026-11-20T00:00:00Z', agora), -1);
});

test('classificar separa OK, perto de vencer e vencido', () => {
  assert.equal(classificar(90, 30), 'OK');
  assert.equal(classificar(30, 30), 'VENCE EM BREVE');
  assert.equal(classificar(-1, 30), 'VENCIDO');
});

test('avaliar marca serviço fora do ar, com erro, lento ou OK', () => {
  const s = { nome: 'Intranet', url: 'https://intranet', statusEsperado: 200, limiteMs: 1000 };
  assert.equal(avaliar(s, { erro: 'ECONNREFUSED' }).status, 'FORA DO AR');
  assert.equal(avaliar(s, { codigo: 500, tempoMs: 100 }).status, 'ERRO');
  assert.equal(avaliar(s, { codigo: 200, tempoMs: 1500 }).status, 'LENTO');
  assert.equal(avaliar(s, { codigo: 200, tempoMs: 300 }).status, 'OK');
});
