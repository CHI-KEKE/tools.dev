```markdown
## Global Layout Strategy

### Primary Layout System
- **System Type**: Flexbox (column-based)
- **Container Structure**: Main container uses `display: flex; flex-direction: column; gap: 30px;`

### Repeating Patterns Identified

#### Pattern 1: Fixed-Width Horizontal Label Form Layout
- **Pattern Name**: "Fixed-Width Horizontal Label"
- **Description**: All form fields follow a consistent pattern where labels have a fixed width (176px) on the left, and input areas are flexible on the right
- **Structure**: 
  - Container: `display: flex; flex-direction: row; align-items: flex-start; gap: 4px;`
  - Label: `width: 176px; flex-shrink: 0;` (fixed width, prevents shrinking)
  - Input Area: `flex: 1;` (takes remaining space)
- **Vertical Alignment**: Labels use `align-items: flex-start` (not `center`) to align with first line of multi-line inputs
- **Consistency Rule**: **ALL form fields MUST follow this exact pattern** to ensure vertical alignment of labels across different rows

#### Pattern 2: Input with Character Counter
- **Pattern Name**: "Input with External Counter"
- **Description**: Character counters are positioned externally to the right of inputs, not inside the input field
- **Structure**:
  - Container: `display: flex; flex-direction: row; align-items: center; gap: 12px;`
  - Input: `flex: 1;` (takes available space)
  - Counter: `flex-shrink: 0; white-space: nowrap;` (fixed width, no wrapping)
- **Consistency Rule**: **ALL inputs with counters MUST place the counter outside and to the right**, never inside the input or below it

### Fixed Dimensions
- **Label Width**: `176px` (applies to ALL form labels)
- **Input Height**: `40px` (applies to ALL text inputs)
- **Gap Between Label and Input**: `4px` (consistent across ALL form fields)
- **Gap Between Form Rows**: `30px` (consistent vertical spacing)

### Alignment Rules
- **Form Row Alignment**: `align-items: flex-start` (ensures labels align with first line of multi-line inputs)
- **Label Text Alignment**: Left-aligned (`text-align: left`)
- **Input Text Alignment**: Left-aligned (`text-align: left`)
```