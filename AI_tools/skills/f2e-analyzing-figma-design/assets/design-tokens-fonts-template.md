**Format Example (from Variables):**
```markdown
-   `20-M = xl`: Font(family: "Noto Sans TC", style: Medium, size: 20, weight: 500, line-height: 1.8, letter-spacing: 0.6px)
-   `14-R = sm`: Font(family: "Noto Sans TC", style: Regular, size: 14, weight: 400, line-height: 1.8, letter-spacing: 1.2px)
-   ...
```

**Format Example (Fallback from XML):**
```markdown
-   Heading Large: Font(family: "Noto Sans TC", size: 26px, weight: 500, line-height: 1.8) - Used in section titles
-   Body Regular: Font(family: "Noto Sans TC", size: 14px, weight: 400, line-height: 1.8) - Used in product descriptions
-   Label Small: Font(family: "Noto Sans TC", size: 12px, weight: 400, line-height: 1.5) - Used in tags and labels
-   ...
```

**CSS Variables Format:**
```css
:root {
  --font-family-base: 'Noto Sans TC', sans-serif;
  --font-size-xl: 20px;
  --font-size-sm: 14px;
  --font-size-xs: 12px;
  --font-weight-medium: 500;
  --font-weight-regular: 400;
  --line-height-base: 1.8;
  --letter-spacing-base: 1.2px;
}
```

**Tailwind Config Format:**
```javascript
fontFamily: {
  sans: ['Noto Sans TC', 'sans-serif'],
},
fontSize: {
  xl: ['20px', { lineHeight: '1.8', letterSpacing: '0.6px' }],
  sm: ['14px', { lineHeight: '1.8', letterSpacing: '1.2px' }],
  xs: ['12px', { lineHeight: '1.5' }],
},
fontWeight: {
  regular: 400,
  medium: 500,
},
```