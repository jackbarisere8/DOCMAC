const test = require('node:test');
const assert = require('node:assert/strict');

const { normalizeHandle, directChatId } = require('../lib/chat');

test('normalizeHandle lower-cases, strips @ and validates length', () => {
  assert.equal(normalizeHandle('  @Jack_Wilson '), 'jack_wilson');
  assert.equal(normalizeHandle('jack'), 'jack');
  assert.equal(normalizeHandle('ab'), null);
  assert.equal(normalizeHandle('bad handle'), null);
  assert.equal(normalizeHandle('a'.repeat(21)), null);
  assert.equal(normalizeHandle(null), null);
});

test('directChatId is stable for both participants', () => {
  assert.equal(directChatId('uidB', 'uidA'), directChatId('uidA', 'uidB'));
  assert.match(directChatId('uidA', 'uidB'), /^direct_uidA__uidB$/);
  assert.notEqual(directChatId('uidA', 'uidB'), directChatId('uidA', 'uidC'));
});

