```markdown
## Visual Fidelity Checklist

### Dimensions & Spacing
- [ ] All element widths match design (±1px tolerance acceptable)
- [ ] All element heights match design (±1px tolerance acceptable)
- [ ] All padding values match design
- [ ] All margin values match design
- [ ] All gaps between elements match design
- [ ] All border-radius values match design

### Colors
- [ ] All background colors match design (verify hex values)
- [ ] All text colors match design
- [ ] All border colors match design
- [ ] All hover state colors match design
- [ ] All focus state colors match design
- [ ] All disabled state colors match design
- [ ] Color contrast meets WCAG AA standards (4.5:1 for text)

### Typography
- [ ] All font families match design
- [ ] All font sizes match design (±1px tolerance acceptable)
- [ ] All font weights match design
- [ ] All line heights match design
- [ ] All letter spacing values match design
- [ ] Text alignment matches design

### Visual Effects
- [ ] All box-shadow values match design
- [ ] All border styles match design (width, style, color)
- [ ] All background images/gradients match design
- [ ] All icons/images display correctly
- [ ] All icons/images have correct dimensions

### Interaction States
- [ ] Hover states match design
- [ ] Focus states match design (including focus-visible)
- [ ] Active states match design
- [ ] Disabled states match design
- [ ] Transitions are smooth and match design timing

## HTML Structure Checklist

- [ ] Semantic HTML tags used correctly (`<header>`, `<main>`, `<section>`, etc.)
- [ ] Heading hierarchy is correct (`<h1>` through `<h6>`)
- [ ] Form elements have proper `<label>` associations
- [ ] All interactive elements are keyboard accessible
- [ ] All images have descriptive `alt` attributes
- [ ] All icons have `aria-label` or `aria-labelledby` attributes
- [ ] ARIA attributes are used where appropriate
- [ ] HTML structure matches the design hierarchy

## Layout Pattern Compliance Checklist

### Global Layout Strategy
- [ ] Primary layout system identified and documented (Flexbox/Grid/Mixed)
- [ ] Repeating patterns identified and documented
- [ ] Fixed dimensions documented and applied consistently
- [ ] Alignment rules documented and followed

### Form Field Layout (Pattern 1: Fixed-Width Horizontal Label)
- [ ] ALL form labels have consistent fixed width (`w-[176px]` or specified width)
- [ ] ALL form rows use `items-start` for vertical alignment (not `items-center`)
- [ ] ALL labels use `flex-shrink-0` to prevent shrinking
- [ ] ALL input areas use `flex-1` to take remaining space
- [ ] Gap between label and input is consistent (`gap-1` or specified gap)
- [ ] Vertical spacing between form rows is consistent (`mb-[30px]` or specified spacing)
- [ ] Labels align vertically across all form rows (visual check)

### Character Counter Layout (Pattern 2: Input with External Counter)
- [ ] Character counters are positioned externally to the right of inputs
- [ ] Counters are NOT placed inside input fields
- [ ] Counters are NOT placed below inputs (unless as helper text)
- [ ] Counter container uses `flex items-center gap-3` for horizontal alignment
- [ ] Counter uses `whitespace-nowrap` to prevent wrapping
- [ ] Gap between input and counter is consistent (`gap-3` or specified gap)

### Helper Text Layout
- [ ] Helper text is nested INSIDE the input area container
- [ ] Helper text is positioned ABOVE input controls (not below)
- [ ] Helper text uses correct styling (`text-xs text-[#667079]`)
- [ ] Helper text has proper spacing from input controls (`gap-3` or specified gap)

### Nesting Structure Validation
- [ ] Helper text is correctly nested: `Input Area Container > Helper Text > Input Controls`
- [ ] Character counter is correctly nested: `Input Row Container > Input + Counter`
- [ ] Form field structure matches Layout Pattern templates exactly
- [ ] No deviations from documented patterns without justification

## Component Library Usage Checklist

### Import Statements
- [ ] All component library imports are correct (e.g., `import { Chip } from '@91app/atmos-ui'`)
- [ ] Import paths match the component library documentation
- [ ] No incorrect or missing imports
- [ ] TypeScript types are imported if needed (e.g., `React.ComponentProps<typeof Chip>`)

### Component Props and Variants
- [ ] All required props are provided for each component
- [ ] Variant props match design specifications (e.g., `variant="display"`)
- [ ] Color props match design specifications (e.g., `color="green"`)
- [ ] Size props match design specifications (e.g., `size="md"`)
- [ ] State props are correctly set (e.g., `checked`, `disabled`, `loading`)
- [ ] Event handlers are properly connected (e.g., `onChange`, `onClick`)

### Component Usage Strategy
- [ ] Direct Use components are used without unnecessary wrappers
- [ ] Wrapped components have clear justification for wrapping
- [ ] Custom components are only used when no library component exists
- [ ] Component usage matches the strategy documented in section 2.2

### Code Connect Mapping Compliance
- [ ] Components with Code Connect mappings are used as specified
- [ ] Component names match Code Connect mapping names
- [ ] Source paths match Code Connect mapping paths
- [ ] Any deviations from Code Connect mappings are documented and justified

### Component Integration
- [ ] Library components are correctly integrated into HTML/JSX structure
- [ ] Component props are correctly mapped from design specifications
- [ ] Custom styling is applied correctly when needed
- [ ] Components maintain accessibility attributes (ARIA labels, etc.)

## Responsive Design Checklist

- [ ] Layout adapts correctly at all breakpoints
- [ ] Text remains readable at all breakpoints
- [ ] Images scale appropriately at all breakpoints
- [ ] Navigation adapts correctly (e.g., hamburger menu on mobile)
- [ ] Form elements are usable on mobile devices
- [ ] Touch targets are at least 44px × 44px on mobile
- [ ] No horizontal scrolling on any breakpoint
- [ ] Content doesn't overflow containers at any breakpoint
```