# Backend Considerations

## Multi-Language Content Storage

When the backend serves user-facing content:

1. Store database entries with translations for each supported language
2. Require clients to transmit the user's locale with each request or during session initialization
3. Return content in the requested locale

## Error Message Localization

Two approaches for localizing error messages from the backend:

**HTTP Status Code Mapping**: The frontend maps standard HTTP status codes to l10n keys.

**Custom Error Constants**: The backend returns error constants that the app maps to localized strings:

```dart
// Backend returns: { "error": "expired_code" }
// Frontend maps to l10n key:
final message = switch (error) {
  'invalid_code' => context.l10n.errorInvalidCode,
  'expired_code' => context.l10n.errorExpiredCode,
  'limit_reached' => context.l10n.errorLimitReached,
  _ => context.l10n.errorGeneric,
};
```
