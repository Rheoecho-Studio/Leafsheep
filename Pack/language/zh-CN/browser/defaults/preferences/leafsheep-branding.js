/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

//@line 7 "/home/xxbj/Project/Leafsheep/Rolling/build/leafsheep/branding/unofficial/pref/leafsheep-branding.js"
// Set defines to construct URLs
//@line 15 "/home/xxbj/Project/Leafsheep/Rolling/build/leafsheep/branding/unofficial/pref/leafsheep-branding.js"
// Shared Branding Preferences
// XXX: These should REALLY go back to application preferences
// Interval: Time between checks for a new version (in seconds)
pref("app.update.interval", 86400); // 1 day
// The time interval between the downloading of mar file chunks in the
// background (in seconds)
// 0 means "download everything at once"
pref("app.update.download.backgroundInterval", 0);
// Give the user x seconds to react before showing the big UI. default=192 hours
pref("app.update.promptWaitTime", 691200);
// The number of days a binary is permitted to be old
// without checking for an update.  This assumes that
// app.update.checkInstallTime is true.
pref("app.update.checkInstallTime.days", 14);
// Give the user x seconds to reboot before showing a badge on the hamburger
// button. default=immediately
pref("app.update.badgeWaitTime", 0);
// Number of usages of the web console or scratchpad.
// If this is less than 5, then pasting code into the web console or scratchpad is disabled
pref("devtools.selfxss.count", 100);
// 
pref("general.useragent.appVersionIsBuildID", true);
//@line 19 "/home/xxbj/Project/Leafsheep/Rolling/build/leafsheep/branding/unofficial/pref/leafsheep-branding.js"
// Branding Specific Preferences
pref("startup.homepage_override_url", "https://www.rheoecho.fyi/bl_w//releasenotes.html");
pref("startup.homepage_welcome_url", "http://www.rheoecho.fyi/bl_w//lsfirstrun.html");
pref("startup.homepage_welcome_url.additional", "");
// Version release notes
pref("app.releaseNotesURL", "http://www.rheoecho.fyi/bl_w//releasenotes.html");
// Vendor home page
pref("app.vendorURL", "http://www.rheoecho.fyi/bl_w//");
pref("app.update.url", "https://aus.rheoecho.fyi/bl_w//?application=%PRODUCT%&version=%VERSION%&arch=%BUILD_TARGET%&flavor=%BUILD_SPECIAL%&toolkit=%WIDGET_TOOLKIT%&buildid=%BUILD_ID%&channel=%CHANNEL%");
// URL user can browse to manually if for some reason all update installation
// attempts fail.
pref("app.update.url.manual", "https://www.rheoecho.fyi/bl_w//");
// A default value for the "More information about this update" link
// supplied in the "An update is available" page of the update wizard.
pref("app.update.url.details", "https://www.rheoecho.fyi/bl_w//releasenotes.html");
// Provide UA Gecko and Firefox slices for web compatibility
pref("general.useragent.compatMode.firefox",true);
pref("general.useragent.compatMode.gecko",true);
pref("general.useragent.compatMode.version", "147.0.4");
// Shared User Agent Overrides
// Pale Moon Version needed for challenges.cloudflare.com user agent override
//LSVAPI
// %OS_SLICE% macro is resolved at runtime, see MoonchildProductions/UXP/issues/1473
// Special-case AMO
// We send the native UA slice now, since they no longer offer any compatible extensions for us.
// This will result in an "only with Firefox" message which suits us fine, because it's the truth.
pref("general.useragent.override.addons.mozilla.org","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
// Required for domains that are unresponsive to requests from users (or likely to be)
pref("general.useragent.override.aol.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep)");
pref("general.useragent.override.bing.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep)");
pref("general.useragent.override.canva.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Pale Moon)");
pref("general.useragent.override.chase.com","Mozilla/5.0 (%OS_SLICE% rv:140.0) Gecko/20100101 Firefox/140.0");
pref("general.useragent.override.dropbox.com","Mozilla/5.0 (%OS_SLICE% rv:68.9) Gecko/20100101 Firefox/68.9 (Leafsheep)");
pref("general.useragent.override.bilibili.com","Mozilla/5.0 (%OS_SLICE% rv:140.0) Gecko/20100101 Firefox/140.0 (Leafsheep)");
pref("general.useragent.override.youtube.com","Mozilla/5.0 (%OS_SLICE%) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 (Leafsheep)");
pref("general.useragent.override.kroger.com","Mozilla/5.0 (%OS_SLICE% rv:86.0) Gecko/20100101 Firefox/86.0 (Leafsheep)");
pref("general.useragent.override.netteller.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4");
pref("general.useragent.override.patientaccess.com","Mozilla/5.0 (%OS_SLICE% rv:60.0) Gecko/20100101 Firefox/60.0 Leafsheep/1.1.0");
pref("general.useragent.override.outlook.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep)");
pref("general.useragent.override.web.de","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep)");
pref("general.useragent.override.yahoo.com","Mozilla/5.0 (%OS_SLICE% rv:99.9) Gecko/20100101 Firefox/99.9");
pref("general.useragent.override.calendar.yahoo.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep)");
// Soundcloud uses Firefox-exclusive combinations of code. Never pass Firefox slice.
pref("general.useragent.override.soundcloud.com","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.players.brightcove.net","Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko");
// Google fonts serves physically different fonts to later Firefox versions that render incorrectly unless on Gecko
pref("general.useragent.override.fonts.googleapis.com", "Mozilla/5.0 (%OS_SLICE% rv:140.0) Gecko/20100101 Firefox/140.0");
pref("general.useragent.override.fonts-api.wp.com", "Mozilla/5.0 (%OS_SLICE% rv:61.9) Gecko/20100101 Firefox/61.9");
// The following requires native mode. Or it blocks.. "too old firefox", breakage, etc.
pref("general.useragent.override.deviantart.com","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.deviantart.net","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.altibox.dk","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.altibox.no","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.mozilla.org","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.mozilla.com","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.github.com","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
pref("general.useragent.override.zoho.com","Mozilla/5.0 (%OS_SLICE% rv:6.8) Goanna/20170101 Leafsheep/1.1.0");
// UA-Sniffing domains below have indicated no interest in supporting Leafsheep (BOO!)
pref("general.useragent.override.humblebundle.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep)");
pref("general.useragent.override.privat24.ua","Mozilla/5.0 (%OS_SLICE% rv:38.0) Gecko/20100101 Firefox/38.0");
pref("general.useragent.override.citi.com","Mozilla/5.0 (%OS_SLICE% rv:68.0) Gecko/20100101 Firefox/68.0 SeaMonkey/2.53.12");
pref("general.useragent.override.facebook.com","Mozilla/5.0 (%OS_SLICE% rv:68.0) Gecko/20100101 Firefox/68.0 Leafsheep/1.1.0");
pref("general.useragent.override.mewe.com", "Mozilla/5.0 (%OS_SLICE% rv:102.0) Gecko/20100101 Firefox/102.0");
// UA-sniffing domains that are "app/vendor-specific" and do not like Leafsheep
pref("general.useragent.override.web.whatsapp.com","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36");
pref("general.useragent.override.youtube.com","Mozilla/5.0 (%OS_SLICE% rv:102.0) Gecko/20100101 Firefox/102.0");
pref("general.useragent.override.studio.youtube.com","Mozilla/5.0 (%OS_SLICE% rv:102.0) Gecko/20100101 Goanna/6.8 Firefox/102.0 Leafsheep/1.1.0");
// The following domains do not like the Goanna slice
pref("general.useragent.override.bab.la","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4");
pref("general.useragent.override.babla.gr","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4");
pref("general.useragent.override.collinsdictionary.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4");
pref("general.useragent.override.dictionary.cambridge.org","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4");
pref("general.useragent.override.hitbox.tv","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4");
pref("general.useragent.override.ldoceonline.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4");
pref("general.useragent.override.yuku.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 Leafsheep/1.1.0");
// Domains Leafsheep overrides that are not in the Pale Moon overrides
pref("general.useragent.override.slack.com","Mozilla/5.0 (%OS_SLICE% rv:120.0) Gecko/20100101 Firefox/128.0 Leafsheep/1.1.0");
// Domains that require a Pale Moon user agent override
//pref("general.useragent.override.challenges.cloudflare.com","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Goanna/6.8 Firefox/147.0.4 PaleMoon/33.6.1");
// ============================================================================
//Leafsheep Rolling Update (LSVAPI)
pref("general.useragent.override.rheoecho.fyi","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep) 6.8 Goanna/6.8 Leafsheep/1.1.0 (LSVAPI: 1.1 , SP0 , 7fca2b8de3 )");
pref("general.useragent.override.ie.icoa.cn","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep) 6.8 Goanna/6.8 Leafsheep/1.1.0 (LSVAPI: 1.1 , SP0 , 7fca2b8de3 )");
pref("general.useragent.override.codeberg.org","Mozilla/5.0 (%OS_SLICE% rv:147.0.4) Gecko/20100101 Firefox/147.0.4 (Leafsheep) 6.8 Goanna/6.8 Leafsheep/1.1.0 (LSVAPI: 1.1 , SP0 , 7fca2b8de3 )");//@line 47 "/home/xxbj/Project/Leafsheep/Rolling/build/leafsheep/branding/unofficial/pref/leafsheep-branding.js"
// Geolocation
pref("geo.wifi.uri", "https://pro.ip-api.com/json/?fields=lat,lon,status,message&key=jyVzd1rYPdkQCPC");
