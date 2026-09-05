---
name: f2e-analyzing-figma-design
description: Extract the necessary design information from Figma and Generate Analysis Document.
allowed-tools:
  - mcp_figmadevmodem_get_design_context
  - mcp_figmadevmodem_get_screenshot
  - mcp_figmadevmodem_get_variable_defs
  - mcp_figmadevmodem_get_code_connect_map
  - mcp_figmadevmodem_get_metadata
  - create_file
---

## Preconditions

- Figma MCP tools must be reachable (`mcp_figmadevmodem_*`)
- `userStoryId` must be known
- Output directory `.github/docs/{{userStoryId}}/` must be writable
- Figma design link or node ID must be provided

**Input:**
`figma_design_context`、`figma_screenshot`、`figma_variable_defs`、`figma_code_connect_map`、`figma_metadata`

## Workflow Steps

**Output:**
-   **File Path**: `{{userStoryId}}/figma-analysis-*.md` (其中 * 為數字，例如：`figma-analysis-1.md`, `figma-analysis-2.md`)
-   **Content and Format**: The generated document must include the sections `DOM Structure and UI Component Analysis`, `UI Component Usage`, `Layout & Spacing Analysis`, `Component Instance Analysis`, `Design Tokens`, `Interaction States Analysis`, `Responsive Design Analysis`, `Animation Effects Analysis`, `Accessibility Analysis`, `Layout Pattern (佈局模式)`, `HTML Structure Recommendations`, `CSS Style Specifications`, `Tailwind CSS Class Mapping`, `Visual Assets Inventory`, and `Implementation Checklist`, strictly adhering to the specified format below.

#### 1. DOM Structure Analysis
Use a tree structure to break down the visual layout of the design from top to bottom, and from outside to inside, describing the elements and their hierarchy.

**Format Example:**
See [the template](assets/dom-structure-analysis-template.md).

#### 2. UI Component Usage
List all identified UI components from the design, mapping them to existing components in the design system (`atmos-ui`, `spark-ui`, etc.) or marking them as custom-built. **This section must provide complete component library usage guidance, including import statements, props, variants, and usage examples.**

**Component Identification Method**:
1. **Check Code Connect Mapping**: Use `mcp_figma_get_code_connect_map` results to identify components that have Code Connect mappings
2. **Analyze Component Instances**: Look for `<instance>` elements in the XML structure that represent design system components
3. **Identify Custom Components**: Elements that don't match any design system component should be marked as custom-built

**Usage Strategy Decision**:
For each component, determine one of the following:
- **Direct Use**: Component can be used directly from the library without modification
- **Wrapped Component**: Component needs to be wrapped in a custom component for additional functionality or styling
- **Custom Component**: No matching library component exists, requires custom implementation

**Format Example:**
See [the template](assets/ui-component-usage-template.md).

**Required Information for Each Component**:

1. **Import Statement**: Provide the exact import statement needed (e.g., `import { Chip } from '@91app/atmos-ui'`)
2. **Props & Variants**: List all relevant props, variants, and their values as shown in the design
   - Include required props
   - Include variant names (e.g., `variant="display"`, `size="md"`)
   - Include color/theme props if applicable
   - Note any props that need to be set based on design specifications
3. **Usage Strategy**: Clearly indicate:
   - **Direct Use**: Component matches design exactly, can be imported and used directly
   - **Wrapped Component**: Component needs custom wrapper for additional features (e.g., character counter, validation, custom styling)
   - **Custom Component**: No matching library component, requires full custom implementation
4. **Usage Example**: Provide a complete code example showing how to use the component
   - For Direct Use: Show the component with all required props
   - For Wrapped Component: Show the wrapper component structure
   - For Custom Component: Show the HTML/JSX structure with Tailwind classes

**Code Connect Mapping Integration**:
- If `get_code_connect_map` returns mappings, use those as the primary source for component identification
- Document the mapping relationship: `{ nodeId: { codeConnectSrc: 'path/to/component', codeConnectName: 'ComponentName' } }`
- Extract component name and source path from Code Connect mappings
- If Code Connect mapping exists but component needs wrapping, note the reason (e.g., "Needs wrapper for character counter integration")

**Component Props Documentation**:
For each library component, document:
- **Required Props**: Props that must be provided
- **Optional Props**: Props that enhance functionality
- **Variant Values**: All variant options used in the design (e.g., `variant="display"`, `variant="outline"`)
- **State Props**: Props that control component state (e.g., `checked`, `disabled`, `loading`)
- **Event Handlers**: Props for user interactions (e.g., `onChange`, `onClick`, `onSubmit`)

**Notes**:
- Always prioritize Code Connect mappings when available
- If a component exists in the library but needs significant customization, mark it as "Wrapped Component" and explain why
- For custom components, provide complete HTML/JSX structure with Tailwind CSS classes
- Include TypeScript types if applicable (e.g., `React.ComponentProps<typeof Chip>`)

#### 3. Layout & Spacing Analysis
Extract precise layout and spacing information from the design context XML structure. Calculate margins, padding, gaps, and alignment based on element positions and dimensions. **This section is critical for static HTML/CSS implementation.**

**CRITICAL: Global Layout Strategy Identification**
Before extracting individual element spacing, you MUST first identify and document the **Global Layout Strategy** for the entire design. This is essential to ensure consistent implementation across all similar elements.

**Global Layout Strategy Requirements**:
1. **Layout System Type**: Identify whether the design uses:
   - **Flexbox System**: Horizontal or vertical flex containers
   - **Grid System**: CSS Grid with defined columns/rows
   - **Mixed System**: Combination of Flexbox and Grid
   - **Absolute Positioning**: Elements positioned absolutely (use sparingly)

2. **Repeating Patterns**: Identify patterns that repeat across the design:
   - **Form Layout Pattern**: If forms are present, identify the pattern (e.g., "Fixed-Width Horizontal Label" where labels have fixed width and inputs are flexible)
   - **Card Layout Pattern**: If cards are present, identify grid/flex structure
   - **Navigation Pattern**: If navigation exists, identify layout method
   - **Table/List Pattern**: If tables or lists exist, identify structure

3. **Fixed Dimensions**: Identify elements with fixed dimensions that must be consistent:
   - **Fixed Width Elements**: Labels, icons, buttons with specific widths
   - **Fixed Height Elements**: Input fields, buttons, avatars with specific heights
   - **Fixed Spacing**: Consistent gaps, margins, or padding values used throughout

4. **Alignment Rules**: Document alignment rules that apply globally:
   - **Vertical Alignment**: How elements align vertically (e.g., `items-start`, `items-center`, `items-end`)
   - **Horizontal Alignment**: How elements align horizontally (e.g., `justify-start`, `justify-center`, `justify-between`)
   - **Text Baseline Alignment**: How text aligns with other elements (especially important for labels and inputs)

5. **Responsive Behavior**: Document how the layout adapts:
   - **Breakpoints**: At what screen sizes does the layout change
   - **Layout Shifts**: How does the layout method change (e.g., flex-row to flex-col on mobile)

**Format for Global Layout Strategy**:
See [the template](assets/global-layout-strategy-template.md).


**Data Extraction Method**:
- Extract `x`, `y`, `width`, `height` attributes from each element in the XML structure
- Calculate spacing between sibling elements: `gap = nextElement.x - (currentElement.x + currentElement.width)`
- Calculate padding: `padding = childElement.x - parentElement.x` (for left padding), `padding = childElement.y - parentElement.y` (for top padding)
- Calculate margins: `margin = element.x - (parent.x + parent.padding)` (for left margin)
- Identify alignment patterns from coordinate relationships
- Determine layout method (Flexbox, Grid, or Absolute positioning) based on element relationships

**Format Example:**
See [the template](assets/data-extraction-method-template.md).

**CSS Property Mapping**:
- For Flexbox layouts: Provide `display`, `flex-direction`, `justify-content`, `align-items`, `gap` values
- For Grid layouts: Provide `display`, `grid-template-columns`, `grid-template-rows`, `gap` values
- For absolute positioning: Provide `position`, `top`, `left`, `right`, `bottom` values

**Layout Pattern Identification**:
After extracting spacing data, identify repeating layout patterns:
1. **Group Similar Elements**: Group elements that share the same layout pattern (e.g., all form fields)
2. **Extract Common Values**: Identify common spacing values (e.g., all labels are 176px wide)
3. **Document Pattern Rules**: Create a pattern definition that can be applied consistently
4. **Validate Consistency**: Ensure all elements following the same pattern use identical spacing values

**Notes**:
- Elements marked with `hidden="true"` should be excluded from layout calculations
- Nested elements' positions are relative to their parent container
- When calculating gaps, consider only visible sibling elements
- Always provide CSS property suggestions for each layout method identified
- **CRITICAL**: When documenting spacing, always reference the Global Layout Strategy to ensure consistency
- If you find inconsistencies in spacing values for similar elements, document them but note that they should be standardized according to the Global Layout Strategy

#### 4. Component Instance Analysis
Identify and analyze component instances (`instance` elements) in the design. These represent reusable design system components or custom component instances.

**Identification Method**:
- Look for `<instance>` elements in the XML structure
- Extract the `id` and `name` attributes
- Note the context where each instance is used
- Distinguish between design system components and custom component instances

**Format Example:**
See [the template](assets/identification-method-template.md).

**Notes**:
- Instance components typically represent reusable design system elements
- Multiple instances of the same component indicate a pattern that should be extracted
- Hidden instances (`hidden="true"`) may represent alternative states or variants

#### 5. Design Tokens
List all Design Tokens extracted from the design. Prioritize using `get_variable_defs` results. If that tool fails or hits rate limits, extract color and font information from the design context XML structure as a fallback. **Provide tokens in multiple formats for easy implementation.**

**Extraction Priority**:
1. **Primary Method**: Use `mcp_figma_get_variable_defs` to get official design variables
2. **Fallback Method**: Parse the XML structure from `get_design_context` to extract:
   - Color values from `fill` attributes or style information
   - Font information from `text` elements (size, weight, family if available)

##### Colors
**Format Example:**
See [the template](assets/design-tokens-colors-template.md).

##### Fonts
See [the template](assets/design-tokens-fonts-template.md).

##### Spacing
**Format Example:**
See [the template](assets/design-tokens-spacing-template.md).

**Note**: Spacing tokens should be derived from common gap and padding values found in the Layout & Spacing Analysis section. Always provide both CSS variables and Tailwind config formats.

#### 6. Interaction States Analysis
Analyze different states of interactive elements visible in the design. **Focus on visual style changes for CSS implementation, not business logic.**

**Format Example:**
See [the template](assets/interaction-states-analysis-template.md).

**CSS Implementation Notes**:
- Always specify exact color values, border widths, and other visual properties
- Include `transition` properties for smooth state changes (e.g., `transition: all 0.2s ease-in-out`)
- Specify `cursor` property changes (e.g., `cursor: pointer` for hover, `cursor: not-allowed` for disabled)
- Note any transform or scale changes
- Include focus-visible styles for accessibility

#### 7. Responsive Design Analysis
Document responsive behavior and breakpoint considerations based on the design.

**Format Example:**
See [the template](assets/responsive-design-analysis-template.md).

#### 9. Accessibility Analysis
Document accessibility considerations based on visual design cues.

**Format Example:**
See [the template](assets/accessibility-analysis-template.md).

#### 10. Layout Pattern (佈局模式)
Define the **Layout Patterns** identified in the design. This section provides reusable HTML/JSX structure templates that must be followed consistently throughout the implementation. **This is critical for ensuring pixel-perfect alignment and preventing layout inconsistencies.**

**Purpose**:
Layout Patterns are reusable structural templates that define:
- The exact HTML/JSX nesting structure
- CSS classes and Tailwind utilities to use
- How special elements (like character counters, helper text) are positioned
- Alignment rules that ensure visual consistency

**Pattern Identification Method**:
1. **Review Global Layout Strategy**: Use the patterns identified in section 3 (Layout & Spacing Analysis)
2. **Identify Repeating Structures**: Look for structures that appear multiple times (e.g., form fields, card layouts)
3. **Extract Common Patterns**: Group similar elements and create a unified pattern
4. **Document Special Cases**: Note any exceptions or variations to the pattern

**Format Example:**
See [the template](assets/layout-pattern-template.md).

## Pattern Application Rules

**Consistency Requirements**:
1. **ALL form fields MUST follow Pattern 1** (Fixed-Width Horizontal Label) - no exceptions
2. **ALL inputs with counters MUST follow Pattern 2** (Input with External Counter)
3. **Patterns are composable** - Pattern 1 can include Pattern 2 and Pattern 3 as needed
4. **No deviations allowed** - If a field looks different, it's likely a variation of an existing pattern, not a new pattern

**Implementation Checklist**:
- [ ] All labels have consistent width (`w-[176px]`)
- [ ] All form rows use `items-start` for vertical alignment
- [ ] All character counters are positioned externally to the right
- [ ] All helper text is positioned inside the input area container
- [ ] All form rows have consistent vertical spacing (`mb-[30px]`)
- [ ] All gaps between elements match the pattern specifications

**Notes**:
- Patterns should be implemented as reusable React components when possible
- Each pattern should have a clear name that can be referenced in code
- Patterns can be nested (e.g., Pattern 1 contains Pattern 2)
- Always validate that implementation matches the pattern structure exactly

**Pattern Documentation Requirements**:
1. **Pattern Name**: A clear, descriptive name (e.g., `FixedWidthHorizontalLabel`)
2. **Description**: What the pattern is used for and why it's important
3. **Visual Structure**: ASCII art or description showing the layout
4. **HTML/JSX Template**: Complete code template with Tailwind classes
5. **Key Rules**: Bullet points of critical rules that MUST be followed
6. **When to Use**: Clear guidance on when to apply this pattern
7. **Variations**: Document any variations or special cases
8. **Common Mistakes**: List what NOT to do

**Critical Patterns to Always Document**:
- Form field layouts (if forms are present)
- Card layouts (if cards are present)
- Navigation structures (if navigation exists)
- Input with special elements (counters, icons, helper text)
- Responsive breakpoint patterns

#### 11. HTML Structure Recommendations
Provide semantic HTML/JSX structure recommendations for each major section of the design. **This section must integrate with Layout Patterns (section 10) and Component Library Usage (section 2.2) to provide complete, implementable code examples.**

**Integration Requirements**:
1. **Reference Layout Patterns**: When providing structure examples, reference the Layout Patterns defined in section 10
2. **Include Component Library Usage**: Show how to integrate components from the design system (as documented in section 2.2)
3. **Provide Complete Examples**: Include import statements, component props, and Tailwind CSS classes
4. **Show Nesting Relationships**: Clearly demonstrate parent-child relationships and nesting structure

**Format Example:**
See [the template](assets/html-structure-recommendations-template.md).

**Semantic HTML Guidelines**:
- Use `<header>`, `<main>`, `<section>`, `<article>`, `<footer>` for page structure
- Use `<nav>` for navigation elements
- Use `<form>` for form containers
- Use proper heading hierarchy (`<h1>` through `<h6>`)
- Use `<label>` for form labels with proper `for` attributes
- Use `<button>` for interactive buttons, not `<div>` or `<span>`
- Add `aria-*` attributes for accessibility (e.g., `aria-label`, `aria-required`, `aria-describedby`)

**Component Library Integration Guidelines**:
- **Import Statements**: Always include the import statement for library components
- **Props Mapping**: Map design specifications to component props (e.g., `variant="display"`, `color="green"`)
- **Wrapper Components**: When wrapping library components, show the wrapper structure clearly
- **Custom Components**: When no library component exists, provide complete custom implementation

**Nesting Relationship Rules**:
1. **Helper Text**: MUST be nested inside the input area container (`flex-1` div), positioned above input controls
2. **Character Counter**: MUST be a sibling of the input element, in a flex container (`flex items-center gap-3`)
3. **Label**: MUST be a sibling of the input area container, with fixed width (`w-[176px] flex-shrink-0`)
4. **Form Rows**: Each form field is a separate row with consistent spacing (`mb-[30px]`)

**Critical Nesting Rules**:
- ❌ DO NOT place helper text outside the input area container
- ❌ DO NOT place character counter inside the input element
- ❌ DO NOT place character counter below the input (unless it's helper text)
- ✅ DO nest helper text inside input area container, above controls
- ✅ DO place character counter as sibling of input in flex row
- ✅ DO maintain consistent label width across all form fields

#### 12. CSS Style Specifications
Provide detailed CSS style specifications for each element, including all visual properties needed for pixel-perfect implementation.

**Format Example:**
See [the template](assets/css-style-specifications-template.md).

**Specification Requirements**:
- Include all CSS properties: layout (display, position, width, height, padding, margin), typography (font-family, font-size, font-weight, line-height, letter-spacing, color), visual (background, border, border-radius, box-shadow), and interaction (cursor, transition)
- Specify exact pixel values or relative units
- Include all state variations (default, hover, focus, active, disabled)
- Note any animations or transitions
- Include responsive variations if applicable


#### 13. Tailwind CSS Class Mapping
Map design styles to Tailwind CSS utility classes. **Mark custom styles that cannot be achieved with standard Tailwind utilities.**

**Format Example:**
```markdown
## Component Class Mappings

### Primary Button
```html
<button class="inline-flex items-center justify-center min-w-[120px] h-10 px-4 py-2 font-medium text-sm leading-[1.8] tracking-[1.2px] text-white bg-blue-500 rounded border-none shadow-sm cursor-pointer transition-all duration-200 hover:bg-blue-600 hover:shadow focus-visible:outline-2 focus-visible:outline-blue-500 focus-visible:outline-offset-2 active:bg-blue-700 active:scale-[0.98] disabled:bg-gray-400 disabled:cursor-not-allowed disabled:opacity-60">
  Button Text
</button>
```

### Custom Styles Required
Some styles cannot be achieved with standard Tailwind utilities and require custom CSS:

- **Letter Spacing**: `tracking-[1.2px]` - Custom value, not in default Tailwind scale
- **Line Height**: `leading-[1.8]` - Custom value for specific typography
- **Box Shadow**: `shadow-sm` - May need custom shadow values
- **Transform Scale**: `active:scale-[0.98]` - Custom scale value

**Tailwind Config Additions Needed**:
```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      letterSpacing: {
        'custom': '1.2px',
      },
      lineHeight: {
        'custom': '1.8',
      },
      boxShadow: {
        'custom': '0 1px 2px rgba(0, 0, 0, 0.05)',
      },
    },
  },
}
```

**Notes**:
- Use Tailwind's arbitrary values (`[value]`) for one-off custom values
- Extend Tailwind config for reusable custom values
- Always mark which styles require custom CSS or Tailwind config extensions
```

#### 14. Visual Assets Inventory
List all visual assets (images, icons, SVGs) used in the design with their specifications.

**Format Example:**
```markdown
| Asset Name | Type | Dimensions | File Format | Usage Context | Notes |
|---|---|---|---|---|---|
| Logo | Image | 120px × 40px | PNG/SVG | Header | Should be SVG for scalability |
| User Avatar | Image | 32px × 32px | PNG/JPG | User menu | Circular crop, border-radius: 50% |
| Search Icon | Icon | 16px × 16px | SVG | Search input | Use inline SVG or icon font |
| Product Image | Image | 394px × 394px | PNG/JPG | Product card | Aspect ratio: 1:1, object-fit: cover |
| Chevron Down | Icon | 24px × 24px | SVG | Dropdown | Rotate 180deg when expanded |

## Icon Specifications

### Search Icon (SVG)
```svg
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M7 12C9.76142 12 12 9.76142 12 7C12 4.23858 9.76142 2 7 2C4.23858 2 2 4.23858 2 7C2 9.76142 4.23858 12 7 12Z" stroke="currentColor" stroke-width="1.5"/>
  <path d="M10.5 10.5L14 14" stroke="currentColor" stroke-width="1.5"/>
</svg>
```

**Implementation Notes**:
- Icons should use `currentColor` for fill/stroke to allow color inheritance
- Provide SVG code or reference to icon library (e.g., Heroicons, Material Icons)
- Specify if icons should be inline SVG, icon fonts, or image sprites
- Note any animation or interaction states for icons
```

#### 15. Implementation Checklist
Provide a comprehensive checklist for verifying the implementation matches the design.

**Format Example:**
See [the template](assets/implementation-checklist-template.md).

---

## Hard Constraints

- **All 15 sections required**: The output document must not omit any of the sections listed above
- **Code Connect first**: For component identification, always check `get_code_connect_map` results first
- **Global Layout Strategy before individual spacing**: Section 3 must be completed before extracting individual spacing values
- **Quantified spacing**: All spacing, padding, and gap values must include concrete pixel numbers; vague terms like "small" or "medium" are not acceptable
- **Exclude hidden elements**: Elements with `hidden="true"` must not be included in layout calculations

## Good/Bad Examples

**✅ Good — Check Code Connect first, then identify components**
```markdown
### Button Component
- Code Connect Mapping: `{ nodeId: "123", codeConnectSrc: "@91app/atmos-ui", codeConnectName: "Button" }`
- Source: Code Connect mapping (priority)
- Usage Strategy: Direct Use
- Import: `import { Button } from '@91app/atmos-ui'`
```

**❌ Bad — Skip Code Connect and identify by visual appearance only**
```markdown
### Button Component
- Looks like a button, implement as custom
- Use `<button className="...tailwind...">` implementation
```
(Missing Code Connect Mapping check; may duplicate an existing component library implementation)

## Quality Checklist

- [ ] All 15 sections are included in the output document
- [ ] All components in Section 2 have been checked against Code Connect Mapping
- [ ] Section 3 includes Global Layout Strategy with concrete pixel definitions
- [ ] Section 5 Design Tokens provide both CSS variables and Tailwind config formats
- [ ] Section 10 defines a Pattern for every repeating layout structure
- [ ] Output file path matches the `{{userStoryId}}/figma-analysis-*.md` format
- [ ] All spacing values are derived from XML coordinate calculations, not visual estimates