# Releasing mdview

Public releases must be signed with a Developer ID Application certificate and notarized by Apple. The release workflow deliberately fails if its signing or notarization credentials are absent.

Configure these repository Actions secrets before pushing a `vX.Y.Z` tag:

| Secret | Value |
| --- | --- |
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded Developer ID Application `.p12` certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password used to export that `.p12` file |
| `KEYCHAIN_PASSWORD` | A new random password used for the temporary CI keychain |
| `DEVELOPER_ID_APPLICATION` | Full certificate identity, for example `Developer ID Application: Example, Inc. (TEAMID)` |
| `APPLE_API_KEY_BASE64` | Base64-encoded App Store Connect API-key `.p8` file with notary access |
| `APPLE_API_KEY_ID` | App Store Connect API key ID |
| `APPLE_API_ISSUER_ID` | App Store Connect issuer ID |

The normal CI workflow intentionally uses an explicit ad-hoc signature only to validate archive structure. It never publishes artifacts.

## Release

1. Update `CLI.version` and the README package command.
2. Run `swift test` locally.
3. Commit and push the release commit.
4. Create and push an annotated `vX.Y.Z` tag.
5. Confirm that the Release workflow signs, notarizes, verifies, and publishes all four release assets.
6. Download the published archive on a clean macOS account and verify that Gatekeeper accepts the installed binary.
