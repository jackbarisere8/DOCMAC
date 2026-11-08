const test = require('node:test');
const assert = require('node:assert/strict');

const {
  normalizeEmail,
  emailKey,
  hashCode,
  generateCode,
  generateToken,
  constantTimeEqual,
  isAcceptablePassword,
} = require('../lib/security');

test('normalizeEmail trims, lower-cases, and rejects junk', () => {
  assert.equal(normalizeEmail('  Jack@Example.COM '), 'jack@example.com');
  assert.equal(normalizeEmail('not-an-email'), null);
  assert.equal(normalizeEmail('a@b'), null);
  assert.equal(normalizeEmail(null), null);
  assert.equal(normalizeEmail(42), null);
  assert.equal(normalizeEmail('x'.repeat(250) + '@example.com'), null);
});

test('emailKey never contains the raw address', () => {
  const key = emailKey('jack@example.com');
  assert.match(key, /^[a-f0-9]{64}$/);
  assert.ok(!key.includes('jack'));
  assert.notEqual(key, emailKey('jill@example.com'));
  assert.equal(key, emailKey('JACK@example.com'));
});

test('hashCode is deterministic per address and pepper', () => {
  const pepper = 'a'.repeat(32);
  assert.equal(
    hashCode('jack@example.com', '123456', pepper),
    hashCode('jack@example.com', '123456', pepper),
  );
  assert.notEqual(
    hashCode('jack@example.com', '123456', pepper),
    hashCode('jack@example.com', '123457', pepper),
  );
  assert.notEqual(
    hashCode('jack@example.com', '123456', pepper),
    hashCode('jill@example.com', '123456', pepper),
  );
  assert.notEqual(
    hashCode('jack@example.com', '123456', pepper),
    hashCode('jack@example.com', '123456', 'b'.repeat(32)),
  );
});

test('generateCode always yields six digits', () => {
  for (let i = 0; i < 250; i += 1) {
    assert.match(generateCode(), /^\d{6}$/);
  }
});

test('generateToken is 32 random bytes of hex', () => {
  const first = generateToken();
  assert.match(first, /^[a-f0-9]{64}$/);
  assert.notEqual(first, generateToken());
});

test('constantTimeEqual compares without throwing on length mismatch', () => {
  assert.equal(constantTimeEqual('abc', 'abc'), true);
  assert.equal(constantTimeEqual('abc', 'abd'), false);
  assert.equal(constantTimeEqual('abc', 'abcd'), false);
});

test('isAcceptablePassword enforces the minimum length', () => {
  assert.equal(isAcceptablePassword('1234567'), false);
  assert.equal(isAcceptablePassword('12345678'), true);
  assert.equal(isAcceptablePassword(null), false);
  assert.equal(isAcceptablePassword('x'.repeat(4097)), false);
});
