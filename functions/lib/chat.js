'use strict';

/**
 * Normalises a Docmac handle. Handles are the public, human-readable part of
 * an identity; they are always lower-case and may be written with a leading
 * `@` by people sharing their profile.
 */
function normalizeHandle(value) {
  if (typeof value !== 'string') return null;
  const handle = value.trim().toLowerCase().replace(/^@/, '');
  return /^[a-z0-9_]{3,20}$/.test(handle) ? handle : null;
}

/**
 * Deterministic 1:1 chat id. Sorting the two UIDs means both participants
 * compute the same document id, so opening the conversation from either side
 * can never create a second copy.
 */
function directChatId(uidA, uidB) {
  const ids = [String(uidA), String(uidB)].sort();
  return `direct_${ids[0]}__${ids[1]}`;
}

module.exports = { normalizeHandle, directChatId };
