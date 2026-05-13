/** Session restore **/
user_pref("browser.startup.page", 3); // 0102: resume previous session
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false); // FF128+

/** Search & URL bar **/
user_pref("keyword.enabled", true); // allow search from URL bar
user_pref("network.http.referer.XOriginPolicy", 0); // always send cross-origin referer

/** Passwords & autofill **/
user_pref("signon.rememberSignons", false);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.creditCards.enabled", false);
user_pref("extensions.formautofill.heuristics.enabled", false);

/** DRM **/
user_pref("browser.eme.ui.enabled", false); // hide DRM UI toggle

/** Network **/
user_pref("network.dns.disableIPv6", false); // keep IPv6 enabled

/** Loopback callbacks (VPN/SSO clients like snx-rs, Forticlient) **/
// snx-rs and similar VPN clients land SAML callbacks on http://127.0.0.1:<port>/<token>.
// LibreWolf hardens beyond arkenfox by force-upgrading loopback to HTTPS and enabling
// LNA blocking; both break the plain-HTTP loopback handoff. Restoring stock Firefox /
// arkenfox behaviour for loopback only. arkenfox 1245 deliberately leaves upgrade_local
// commented out and does not touch network.lna.*. See LibreWolf issues #2954, #2962.
user_pref("dom.security.https_only_mode.upgrade_local", false);
user_pref("network.lna.local-network-to-localhost.skip-checks", true);

/** Resist Fingerprinting **/
user_pref("privacy.resistFingerprinting.testGranularityMask", 4);
user_pref("privacy.resistFingerprinting.exemptedDomains", "meet.google.com,teams.microsoft.com");
user_pref("privacy.resistFingerprinting.letterboxing", true);
user_pref("privacy.spoof_english", 2); // force English headers
