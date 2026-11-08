'use strict';

const crypto = require('node:crypto');

const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/** Lower-cases and validates an address. Returns null when unusable. */
function normalizeEmail(value) {
  if (typeof value !== 'string') return null;
  const email = value.trim().toLowerCase();
  if (email.length < 5 || email.length > 254) return null;
  return EMAIL_PATTERN.test(email) ? email : null;
}

function sha256Hex(value) {
  return crypto.createHash('sha256').update(String(value), 'utf8').digest('hex');
}

/**
 * Document id for an address. Raw emails never become Firestore keys: that
 * would leak addresses to anyone who can read the collection later and would
 * break on addresses containing characters Firestore rejects.
 */
function emailKey(email) {
  return sha256Hex(`docmac-reset:${normalizeEmail(email) ?? ''}`);
}

/** Codes are never stored in the clear, only as a peppered HMAC. */
function hashCode(email, code, pepper) {
  return crypto
    .createHmac('sha256', pepper)
    .update(`${emailKey(email)}:${code}`, 'utf8')
    .digest('hex');
}

function generateCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');
}

function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

/** Length-safe comparison so a wrong code cannot be guessed byte by byte. */
function constantTimeEqual(left, right) {
  const a = Buffer.from(String(left));
  const b = Buffer.from(String(right));
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

function isAcceptablePassword(value) {
  return typeof value === 'string' && value.length >= 8 && value.length <= 4096;
}

module.exports = {
  normalizeEmail,
  sha256Hex,
  emailKey,
  hashCode,
  generateCode,
  generateToken,
  constantTimeEqual,
  isAcceptablePassword,
};
