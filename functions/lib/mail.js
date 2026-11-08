'use strict';

const { logger } = require('firebase-functions/logger');

const RESEND_ENDPOINT = 'https://api.resend.com/emails';

/** Logs must never contain a full address or the code itself. */
function maskEmail(email) {
  const [name, domain] = String(email).split('@');
  if (!domain) return 'unknown';
  const visible = name.slice(0, 2);
  return `${visible}${'*'.repeat(Math.max(1, name.length - 2))}@${domain}`;
}

function resetCodeHtml(code, minutes) {
  const digits = code.split('').join('</td><td>');
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Your Docmac reset code</title>
  </head>
  <body style="margin:0;padding:0;background:#eef3fa;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#eef3fa;padding:32px 16px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:440px;background:#0b1220;border-radius:24px;overflow:hidden;">
            <tr>
              <td style="padding:32px 32px 8px 32px;">
                <table role="presentation" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="width:36px;height:36px;background:#2f6bff;border-radius:10px;text-align:center;vertical-align:middle;color:#ffffff;font-size:20px;font-weight:700;">D</td>
                    <td style="padding-left:12px;color:#f4f7fb;font-size:20px;font-weight:700;letter-spacing:-0.3px;">Docmac</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:16px 32px 0 32px;color:#f4f7fb;font-size:24px;font-weight:700;letter-spacing:-0.5px;">
                Reset your password
              </td>
            </tr>
            <tr>
              <td style="padding:10px 32px 0 32px;color:#9aa6b8;font-size:14px;line-height:1.55;">
                Enter this code in the app to choose a new password. It expires in ${minutes} minutes and can be used once.
              </td>
            </tr>
            <tr>
              <td style="padding:26px 32px 0 32px;">
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#151f2e;border:1px solid #26354a;border-radius:16px;">
                  <tr>
                    <td style="padding:20px 8px;text-align:center;color:#f4f7fb;font-size:34px;font-weight:700;letter-spacing:10px;">${digits}</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:22px 32px 32px 32px;color:#7e8ba0;font-size:12.5px;line-height:1.6;">
                If you did not ask to reset your password, you can ignore this email. Your password will not change until the code is used in the app.
              </td>
            </tr>
          </table>
          <div style="max-width:440px;padding:18px 8px 0 8px;color:#8290a6;font-size:11.5px;line-height:1.5;text-align:center;">
            Docmac never asks for this code by phone, chat, or email.
          </div>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

/**
 * Sends the reset code through Resend's HTTP API. Returns false instead of
 * throwing so a mail outage cannot be used to probe which addresses exist.
 */
async function sendResetCode({ to, code, minutes, apiKey, from }) {
  if (!apiKey) {
    logger.warn('RESEND_API_KEY is not configured; reset code was not emailed.', {
      to: maskEmail(to),
    });
    return false;
  }

  try {
    const response = await fetch(RESEND_ENDPOINT, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from,
        to: [to],
        subject: `${code} is your Docmac reset code`,
        html: resetCodeHtml(code, minutes),
        text:
          `Your Docmac password reset code is ${code}. ` +
          `It expires in ${minutes} minutes and can be used once. ` +
          'If you did not request this, ignore this email.',
      }),
    });

    if (!response.ok) {
      logger.error('Resend rejected the reset email.', {
        status: response.status,
        to: maskEmail(to),
      });
      return false;
    }
    return true;
  } catch (error) {
    logger.error('Resend request failed.', {
      message: error?.message,
      to: maskEmail(to),
    });
    return false;
  }
}

module.exports = { sendResetCode, resetCodeHtml, maskEmail };
