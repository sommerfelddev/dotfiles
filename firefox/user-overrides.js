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

/** OpenH264 for WebRTC (MS Teams, any H.264-only conferencing) **/
// LibreWolf disables the GMP provider and the OpenH264 plugin, and pretends
// media.webrtc.hw.h264.enabled=true covers it. On Linux Mozilla's FFmpeg
// doesn't ship H.264 encode (patent policy), so Teams gets no usable encoder
// and remote participants see no video while local preview works.
// arkenfox 2020 deliberately leaves GMP alone; this aligns with arkenfox.
user_pref("media.gmp-provider.enabled", true);
user_pref("media.gmp-gmpopenh264.enabled", true);
user_pref("media.gmp-manager.url", "https://aus5.mozilla.org/update/3/GMP/%VERSION%/%BUILD_ID%/%BUILD_TARGET%/%LOCALE%/%CHANNEL%/%OS_VERSION%/%DISTRIBUTION%/%DISTRIBUTION_VERSION%/update.xml");

/** Network **/
user_pref("network.dns.disableIPv6", false); // keep IPv6 enabled

// NOTE on snx-rs SAML loopback callbacks (Check Point VPN):
// LibreWolf force-upgrades http://127.0.0.1:<port>/<token> to HTTPS and
// enables LNA blocking, which both break the snx-rs SAML handoff.
// `dom.security.https_only_mode.upgrade_local = false` and
// `network.lna.local-network-to-localhost.skip-checks = true` were tried
// here and did NOT actually fix the SAML flow — left disabled. The
// working fix is the wrapper script ~/.local/bin/snxctl-chromium, which
// routes snx-rs's xdg-open through flatpak ungoogled-chromium via a
// systemd --user drop-in. See dot_local/share/snx-rs/bin/xdg-open and
// dot_config/systemd/user/snx-rs.service.d/10-chromium-saml.conf.

/** Resist Fingerprinting **/
user_pref("privacy.resistFingerprinting.testGranularityMask", 4);
user_pref("privacy.resistFingerprinting.exemptedDomains", "meet.google.com,teams.microsoft.com");
user_pref("privacy.resistFingerprinting.letterboxing", true);
user_pref("privacy.spoof_english", 2); // force English headers
