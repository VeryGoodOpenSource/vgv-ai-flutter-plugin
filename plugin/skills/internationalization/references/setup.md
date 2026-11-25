# ARB File Format

## Simple Strings

```json
{
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "Greeting shown on the home page"
  }
}
```

## Placeholders

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

Since Flutter 3.50, `flutter gen-l10n` rejects a placeholder `type` that is not a valid Dart
type name. Use Dart types such as `String`, `int`, `num`, `double`, or `DateTime`.

## Plurals

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
