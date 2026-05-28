# Setup Pipeline and ARB File Format

## Setup Pipeline

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

### 2. Configure `l10n.yaml`

Create `l10n.yaml` in the project root:

```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
preferred-supported-locales: [en]
```

Set `preferred-supported-locales` explicitly to avoid alphabetical ordering of locales.

### 3. Create ARB Files

Store translation files in `lib/l10n/arb/`:

**`app_en.arb`** (template -- this is the source of truth):

```json
{
  "@@locale": "en",
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "Greeting shown on the home page"
  },
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Label showing the number of items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "welcomeUser": "Welcome, {name}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

**`app_es.arb`**:

```json
{
  "@@locale": "es",
  "helloWorld": "!Hola Mundo!",
  "itemCount": "{count, plural, =0{Sin elementos} =1{1 elemento} other{{count} elementos}}",
  "welcomeUser": "!Bienvenido, {name}!"
}
```

### 4. Generate Localization Code

```bash
flutter gen-l10n
```

### 5. Integrate with `MaterialApp`

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

const MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
```

## ARB File Format

### Simple Strings

```json
{
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "Greeting shown on the home page"
  }
}
```

### Placeholders

```json
{
  "welcomeUser": "Welcome, {name}!",
  "@welcomeUser": {
    "description": "Welcome message with user name",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

### Plurals

```json
{
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "Label showing the number of items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```
