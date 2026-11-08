# YAKA release readiness — 2026-11-08

This is a source review record, not a claim that the current branch is ready for a store rollout.

The review branch also removes raw FCM-token logging and API response-body logging from debug output. It still needs the account, payment, privacy, signing, and device checks below.

## Before merging the review branch

1. Review the complete public-repository PR: it replaces the older 1.2.1 source snapshot with the newer 4.0.4 app and removes tracked generated Android build files. The two repositories have unrelated Git histories, so this is a full source migration, including payment, download, and native code. Uncommitted work in the original private `refactor` worktree is not included; decide and test its integration separately.
2. Require green format, analysis, tests, Android debug build, and iOS no-codesign build checks. Run app flows on real devices before a release tag.

## Before publishing a new binary or direct-download APK

1. **Account deletion:** `UserProfilePage` labels an action “Delete account”, but its confirmed path clears local authentication and logs out; it does not call a server deletion endpoint. The backend owner must define the deletion contract and data/entitlement effects, then the app must implement and test it. The Play listing says users can request deletion; confirm that the actual process fulfills that statement.
2. **Privacy:** The public Play listing says no data is collected, while source initializes Firebase Analytics, receives FCM tokens, and uses phone authentication, account, and payment APIs. A privacy owner must reconcile actual collection, consent, disclosures, and the privacy policy. Notification permission is requested by the optional service during startup; confirm the prompt timing and user explanation on devices.
3. **Payment initiation:** The online-payment request includes an embedded static token in mobile source. The backend owner must determine whether it is a credential, move sensitive authorization server-side if so, rotate it, and verify that old app versions remain supported. Do not copy its value into documentation or CI.
4. **Signing:** The source tree has no `android/key.properties`; the project has local keystore files outside Git. Verify the correct alias, passwords, package ID, and certificate against Play's **app signing certificate**. Keep all values outside Git. A release-signed APK using only the Play upload key may not update a Play-installed app.
5. **Upgrade and device checks:** Test login, offline startup and logout, cart/order creation, wallet top-up, collar purchase/download, Android USB storage picker/copy, push/deep links, and the one-time legacy download-cache cleanup on current and upgraded installations. Use the approved payment test environment; do not spend production money for smoke tests.
6. **Store versions:** Source is `4.0.4+61`. The iOS App Store currently reports 4.0.4; confirm the active Play version and increase build numbers for new uploads. Tag the exact validated commit only after review and device checks. Keep GitHub Releases honest about source snapshots versus installable binaries.

## CI scope

CI checks formatting, application analysis, Flutter tests, an Android debug build, and an iOS build without signing. It does not prove production signing, backend payment settlement, account deletion, store privacy disclosures, or direct-download APK upgrades.
