# Releasing OpenLid

OpenLid ships as a Developer ID–signed, notarized `OpenLid.app`, packaged as both a
`.zip` and a `.dmg`, attached to a GitHub Release.

## Prerequisites

- A **Developer ID Application** certificate in your login keychain.
- An Apple **app-specific password** (create at appleid.apple.com → Sign-In &
  Security → App-Specific Passwords) and your Team ID.

## Local release

1. Store notarization credentials once (keychain profile named `OpenLid-Notary`):

   ```sh
   xcrun notarytool store-credentials "OpenLid-Notary" \
     --apple-id "you@example.com" \
     --team-id "6D56G8D849" \
     --password "your-app-specific-password"
   ```

2. Bump `MARKETING_VERSION` in the Xcode project if needed.

3. Build, sign, notarize, and package:

   ```sh
   scripts/build_release.sh
   ```

   Artifacts land in `build/dist/OpenLid-<version>.zip` and `.dmg`.
   (Set `SKIP_NOTARIZE=1` to sign without notarizing for a quick local check.)

4. Tag and publish:

   ```sh
   git tag v0.1.0
   git push origin v0.1.0
   gh release create v0.1.0 build/dist/*.zip build/dist/*.dmg \
     --title "OpenLid v0.1.0" --generate-notes
   ```

## Automated release (GitHub Actions)

Pushing a tag matching `v*` runs `.github/workflows/release.yml`, which imports the
signing certificate, builds + signs + notarizes, and publishes the release.

Configure these **repository secrets** (Settings → Secrets and variables → Actions):

| Secret | What it is |
| --- | --- |
| `MACOS_CERT_P12_BASE64` | Base64 of your Developer ID Application cert + private key exported as `.p12` |
| `MACOS_CERT_PASSWORD` | Password you set when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | Any password for the temporary CI keychain |
| `NOTARY_APPLE_ID` | Apple ID email used for notarization |
| `NOTARY_PASSWORD` | App-specific password |
| `NOTARY_TEAM_ID` | Apple Developer Team ID (`6D56G8D849`) |

Export the `.p12` from **Keychain Access** (select the Developer ID Application
certificate *and* its private key → right-click → Export), then:

```sh
base64 -i Certificates.p12 | pbcopy   # paste into MACOS_CERT_P12_BASE64
```

Then just push a tag:

```sh
git tag v0.2.0 && git push origin v0.2.0
```

## Verifying a build

```sh
codesign --verify --deep --strict --verbose=2 build/dist/OpenLid.app   # (inside the dmg/zip)
spctl --assess --type execute --verbose build/dist/OpenLid.app          # should say: accepted, source=Notarized Developer ID
xcrun stapler validate build/dist/OpenLid-<version>.dmg
```
