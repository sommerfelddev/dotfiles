/*
 * Thunderbird user.js — non-private configuration tracked in dotfiles.
 * Accounts, passwords, mailboxes, calendar/contact data, and per-machine
 * state stay local (prefs.js, logins.json, key4.db, ImapMail/, etc.).
 * Deployed by run_onchange_after_deploy-thunderbird.sh.tmpl.
 */

/** Startup & updates **/
user_pref("app.update.auto", false);                              // Arch handles updates
user_pref("app.update.enabled", false);
user_pref("mail.shell.checkDefaultClient", false);
user_pref("mailnews.start_page.enabled", false);                  // no "what's new" tab
user_pref("browser.rights.3.shown", true);
user_pref("mail.spotlight.firstRunDone", true);
user_pref("mail.winsearch.firstRunDone", true);

/** Telemetry & data reporting — off **/
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");

/** Safe browsing & connectivity probes — off (we trust our mail sources) **/
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);

/** Reading — no remote content, no read receipts **/
user_pref("mailnews.message_display.disable_remote_image", true); // block tracking pixels
user_pref("mail.phishing.detection.enabled", true);
user_pref("mail.mdn.report.enabled", false);                      // never send read receipts
user_pref("mail.incorporate.return_receipt", 0);                  // never request
user_pref("mail.server.default.mark_old_as_read", false);
user_pref("mailnews.mark_message_read.auto", true);
user_pref("mailnews.mark_message_read.delay", true);
user_pref("mailnews.mark_message_read.delay.interval", 2);

/** Compose — plain text first, flowed wrap at 72 **/
user_pref("mail.identity.default.compose_html", false);
user_pref("mailnews.send_plaintext_flowed", true);
user_pref("mailnews.wraplength", 72);
user_pref("mail.strictly_mime", false);
user_pref("mail.SpellCheckBeforeSend", true);
user_pref("mail.spellcheck.inline", true);

/** UI **/
user_pref("mail.pane_config.dynamic", 2);                          // vertical: message pane on the right
user_pref("mail.threadpane.table.horizontal_scroll", true);
user_pref("mailnews.default_sort_order", 2);                       // descending
user_pref("mailnews.default_sort_type", 18);                       // by date
user_pref("mail.folder_widget.view_flags", 1);                     // unified folders mode
user_pref("mail.biff.play_sound", false);                          // use mako notifications only
user_pref("mail.biff.show_alert", true);
user_pref("mail.biff.alert.show_preview", false);                  // don't leak body to notification
user_pref("mail.biff.alert.show_sender", true);
user_pref("mail.biff.alert.show_subject", true);

/** Calendar **/
user_pref("calendar.week.start", 1);                               // Monday
user_pref("calendar.view.timeIndicator.interval", 1);
user_pref("calendar.alarms.playsound", false);
user_pref("calendar.alarms.show", true);
user_pref("calendar.timezone.useSystemTimezone", true);

/** Privacy **/
user_pref("privacy.donottrackheader.enabled", true);
user_pref("places.history.enabled", false);
user_pref("browser.formfill.enable", false);
