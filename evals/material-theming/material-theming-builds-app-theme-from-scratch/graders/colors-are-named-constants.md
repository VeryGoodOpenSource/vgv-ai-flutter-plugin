---
type: llm
---

PASS if every brand color hex literal is declared once as a static constant in a dedicated colors class, and the ColorScheme entries reference those constants by name. Colors.white or Colors.black used for an on-color role is acceptable.

FAIL if a ColorScheme passes a Color(0x...) literal directly to a color role, or if the brand hex literals are not declared as static constants in a dedicated colors class, for example bare top-level constants or the same hex repeated in more than one place.
