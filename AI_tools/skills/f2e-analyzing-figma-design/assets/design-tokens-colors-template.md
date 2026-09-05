**Format Example (from Variables):**
```markdown
-   `Light/Background`: `#F8F9FC`
-   `Light/800 (text - Primary)`: `#111827`
-   `Light/blue (text-system)`: `#3B82F6`
-   ...
```

**Format Example (Fallback from XML):**
```markdown
-   Primary Background: `#FFFFFF` (extracted from main container)
-   Text Primary: `#111827` (extracted from text elements)
-   Accent Blue: `#3B82F6` (extracted from button elements)
-   ...
```

**CSS Variables Format:**
```css
:root {
  --color-background: #F8F9FC;
  --color-text-primary: #111827;
  --color-blue-system: #3B82F6;
  /* ... */
}
```

**Tailwind Config Format:**
```javascript
colors: {
  background: '#F8F9FC',
  'text-primary': '#111827',
  'blue-system': '#3B82F6',
  // ...
}
```