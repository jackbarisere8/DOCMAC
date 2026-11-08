# Docmac password reset functions

Server-side reset with a six-digit, single-use code. The app never sees the
Firebase Admin SDK and never stores a code or token in the clear.

## Endpoints

All are `POST` with `application/json`.

| Endpoint | Body | Returns |
|---|---|---|
| `resetRequest` | `{ "email": "you@example.com" }` | `{ ok: true }` |
| `resetVerify` | `{ "email": "...", "code": "123456" }` | `{ ok: true, token, expiresInSeconds }` |
| `resetComplete` | `{ "token": "...", "password": "..." }` | `{ ok: true }` |

Errors are `{ ok: false, error: "<code>" }` where the code is one of
`invalid_email`, `invalid_code`, `code_expired`, `too_many_attempts`,
`rate_limited`, `invalid_token`, `weak_password`, `server_error`.

### Why the extra token hop

`resetVerify` returns a 32-byte token, not a password change. That keeps the
six-digit code out of the step that carries the password, and lets the app
show the strength meter before anything is written.

## Security properties

- Codes are 6 digits from `crypto.randomInt`, valid for 10 minutes, **single
  use**, and stored only as `HMAC-SHA256(pepper, emailKey:code)`.
- A code dies as soon as it verifies, so replaying it cannot mint a second token.
- Codes allow 5 attempts, then require a fresh code.
- Reset tokens are 32 random bytes, stored hashed, valid 10 minutes, single use.
- Requests are throttled to 5 per address per hour with a 60-second cooldown.
  The throttle runs for unknown addresses too, so `resetRequest` cannot be used
  to discover which emails have accounts.
- `admin.auth().updateUser()` sets the password and `revokeRefreshTokens()`
  signs out every existing session.
- Firestore rules deny all client access to `passwordResetCodes`,
  `passwordResetTokens`, and `passwordResetThrottle`.

## Setup

```powershell
cd functions
npm install

firebase functions:secrets:set RESET_OTP_PEPPER      # 32+ random characters
firebase functions:secrets:set RESEND_API_KEY         # https://resend.com/api-keys
firebase deploy --only functions,firestore:rules
```

Optional plain environment values (not secrets), set in `functions/.env`:

```dotenv
RESET_FROM_EMAIL=Docmac <no-reply@yourdomain.com>
```

Resend only delivers from a domain you have verified in their dashboard.

### Recommended Firestore TTL policies

Create TTL policies on `expiresAt` for all three collections in the Firebase
console. Expired codes are already rejected by the functions; TTL just cleans
up storage.

## Local testing

```powershell
firebase emulators:start --only functions,firestore,auth
```

Create `functions/.secret.local` (git-ignored) so the emulator can hash codes:

```dotenv
RESET_OTP_PEPPER=local-dev-pepper-at-least-16-chars
ALLOW_DEV_CODE=true
```

With `ALLOW_DEV_CODE=true` and the emulator running, `resetRequest` also
returns `devCode`. That path is gated on `FUNCTIONS_EMULATOR === 'true'` and
cannot activate in production.

Point the app at the emulator:

```powershell
flutter run --dart-define=DOCMAC_API_BASE=http://10.0.2.2:5001/docmac-88a0d/us-central1
```

`10.0.2.2` is the Android emulator's host loopback; use `127.0.0.1` for
Windows, macOS, iOS simulator and web.

The Firestore emulator needs Java 11 or newer. This machine currently reports
Java 8, so `npm test` (pure functions) is the way to verify logic here without
starting the emulator.

## Tests

```powershell
npm test
```

Covers email normalisation, key hashing, code generation, constant-time
comparison and password policy. It does not need Firebase credentials.
