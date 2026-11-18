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
