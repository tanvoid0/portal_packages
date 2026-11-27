# portal_packages

Shared Flutter packages behind the Portal apps. Each directory is one pub.dev
package, published independently.

| package | what |
|---|---|
| [portal_ai](portal_ai) ([pub.dev](https://pub.dev/packages/portal_ai)) | AI backend discovery (on-device, Ollama, cloud, server) and a shared chat runtime |
| [portal_platform](portal_platform) ([pub.dev](https://pub.dev/packages/portal_platform)) | auth, session, API client, deep links, in-app updates, offline-first sync |
| [portal_ui_core](portal_ui_core) ([pub.dev](https://pub.dev/packages/portal_ui_core)) | design tokens, `PortalUiTheme`, themed components |
| [portal_crypto](portal_crypto) ([pub.dev](https://pub.dev/packages/portal_crypto)) | AES-GCM, key wrapping, vault blob format |
| [portal_notifications](portal_notifications) ([pub.dev](https://pub.dev/packages/portal_notifications)) | local + scheduled notifications with actions |
| [portal_scanner](portal_scanner) ([pub.dev](https://pub.dev/packages/portal_scanner)) | native document scanner → PDF / JPEG |
| [portal_core](portal_core) ([pub.dev](https://pub.dev/packages/portal_core)) | annotation-driven model codegen, local cache |

`portal_ui_kit` is a Mason brick, not a pub package.

`portal_platform` depends on `portal_crypto` and `portal_ui_core` from pub.dev;
`pubspec_overrides.yaml` resolves them from the sibling directories when
working here. Publish order when they change together: crypto → ui_core →
platform.

MIT.
