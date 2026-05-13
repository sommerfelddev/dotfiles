/*
 * Thunderbird user.js — non-private configuration tracked in dotfiles.
 *
 * Tight, curated set. Each pref changes a behaviour I actually want;
 * defaults already-shipped by Mozilla/Arch are NOT restated.
 *
 * Inspired by (not copied from) HorlogeSkynet/thunderbird-user.js.
 * Deployed by run_onchange_after_deploy-thunderbird.sh.tmpl.
 * Accounts, passwords, mailboxes, calendar/contact data stay local.
 */

/** Startup — no start.thunderbird.net page **/
user_pref("mailnews.start_page.enabled", false);

/** Reading — no remote content, no read receipts **/
user_pref("mailnews.message_display.disable_remote_image", true);
user_pref("mail.inline_attachments", false);
user_pref("mail.mdn.report.enabled", false);
user_pref("mail.incorporate.return_receipt", 0);

/** Compose — plain text, format=flowed wrap at 72 **/
user_pref("mail.identity.default.compose_html", false);
user_pref("mail.default_html_action", 2);
user_pref("mailnews.send_plaintext_flowed", true);
user_pref("mail.compose.default_to_paragraph", false);
user_pref("mailnews.wraplength", 72);

/** Outgoing headers — don't leak TB version **/
user_pref("mailnews.headers.showUserAgent", false);
user_pref("general.useragent.override", "");

/** Network — no Referer, no prefetch **/
user_pref("network.http.sendRefererHeader", 0);
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.captive-portal-service.enabled", false);

/** Safe-browsing — off. TB rarely opens arbitrary URLs; avoids Google contact. **/
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);

/** Privacy signal + local history off **/
user_pref("privacy.donottrackheader.enabled", true);
user_pref("places.history.enabled", false);
user_pref("browser.formfill.enable", false);

/** OpenPGP — use system gpg-agent/keys instead of TB's internal store **/
user_pref("mail.openpgp.allow_external_gnupg", true);

/** UI / notifications — mako handles the rest **/
user_pref("mail.shell.checkDefaultClient", false);
user_pref("mail.biff.play_sound", false);
user_pref("mail.biff.show_alert", false);
user_pref("mail.pane_config.dynamic", 2);

/** Calendar **/
user_pref("calendar.week.start", 1);
user_pref("calendar.timezone.useSystemTimezone", true);
