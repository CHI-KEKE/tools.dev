```markdown
## Layout Patterns

### Pattern 1: Fixed-Width Horizontal Label Form Field

**Pattern Name**: `FixedWidthHorizontalLabel`

**Description**: 
This pattern is used for ALL form fields in the design. It ensures consistent vertical alignment of labels across different form rows, regardless of input type (text input, textarea, date picker, etc.).

**Visual Structure**:
```
┌─────────────────────────────────────────────────────┐
│ Label (176px fixed) │ Input Area (flexible)        │
│                      │ ┌─────────────────────────┐ │
│                      │ │ Input / Textarea / etc.  │ │
│                      │ └─────────────────────────┘ │
│                      │ Helper Text (if present)    │
└─────────────────────────────────────────────────────┘
```

**HTML/JSX Structure Template**:
```tsx
<div className="flex items-start gap-1 w-full mb-[30px]">
  {/* Label - Fixed Width */}
  <label className="w-[176px] flex-shrink-0 pt-[2px] text-sm font-normal text-[#111827] tracking-[1.2px]">
    <span>欄位名稱</span>
    {required && <span className="text-[#E30200]" aria-label="required">*</span>}
  </label>

  {/* Input Area - Flexible Width */}
  <div className="flex-1 flex flex-col gap-3">
    {/* Input Row - Contains input and optional counter */}
    <div className="flex items-center gap-3">
      <input 
        className="flex-1 h-10 px-3 border border-[#A0A6B0] rounded"
        type="text"
        // ... other props
      />
      {/* Character Counter - External, Right-aligned */}
      {characterCount && (
        <span className="text-xs text-[#667079] tracking-[0.4px] whitespace-nowrap">
          ({characterCount.current}/{characterCount.max})
        </span>
      )}
    </div>

    {/* Helper Text - Below input, left-aligned */}
    {helperText && (
      <p className="text-xs text-[#667079] leading-[1.5] tracking-[0.4px] m-0">
        {helperText}
      </p>
    )}
  </div>
</div>
```

**Key Rules**:
1. **Label Width**: MUST be `w-[176px] flex-shrink-0` - this ensures all labels align vertically
2. **Vertical Alignment**: Use `items-start` (not `items-center`) to align with first line of multi-line inputs
3. **Gap Between Label and Input**: `gap-1` (4px) - consistent across all fields
4. **Input Area**: MUST use `flex-1` to take remaining space
5. **Character Counter**: MUST be positioned externally to the right of input, using `flex items-center gap-3` container
6. **Helper Text**: MUST be inside the input area container, below the input row
7. **Vertical Spacing**: Each form field row has `mb-[30px]` (30px bottom margin)

**When to Use**:
- ALL form fields with labels
- Fields with or without character counters
- Fields with or without helper text
- Single-line inputs, textareas, date pickers, etc.

**Variations**:
- **With Character Counter**: Add counter span in the input row
- **With Helper Text**: Add helper text paragraph below input row
- **With Date Range**: Replace single input with date range picker structure
- **Textarea**: Replace `<input>` with `<textarea>` but maintain same structure

---

### Pattern 2: Input with External Character Counter

**Pattern Name**: `InputWithExternalCounter`

**Description**: 
Character counters are ALWAYS positioned externally to the right of inputs, never inside the input field or below it.

**Visual Structure**:
```
┌──────────────────────────────────────────────┐
│ Input (flexible) │ Counter (fixed)           │
└──────────────────────────────────────────────┘
```

**HTML/JSX Structure Template**:
```tsx
<div className="flex items-center gap-3">
  <input 
    className="flex-1 h-10 px-3 border border-[#A0A6B0] rounded"
    type="text"
    maxLength={50}
  />
  <span className="text-xs text-[#667079] tracking-[0.4px] whitespace-nowrap">
    (8/50)
  </span>
</div>
```

**Key Rules**:
1. **Container**: Use `flex items-center gap-3` to horizontally align input and counter
2. **Input**: Use `flex-1` to take available space
3. **Counter**: Use `whitespace-nowrap` to prevent wrapping, positioned to the right
4. **Gap**: `gap-3` (12px) between input and counter
5. **Counter Style**: `text-xs text-[#667079] tracking-[0.4px]`

**When to Use**:
- Text inputs with character limits
- Textareas with character limits
- Any input that displays character count

**Common Mistakes to Avoid**:
- ❌ DO NOT place counter inside the input field (as placeholder or suffix)
- ❌ DO NOT place counter below the input (unless it's helper text)
- ❌ DO NOT use absolute positioning for counter
- ✅ DO place counter as a sibling element in a flex container

---

### Pattern 3: Form Field with Helper Text and Date Range

**Pattern Name**: `FormFieldWithHelperTextAndDateRange`

**Description**: 
Form fields that include helper text above the input controls (like date range pickers).

**Visual Structure**:
```
┌─────────────────────────────────────────────────────┐
│ Label (176px) │ Helper Text (full width)            │
│               │ Date Range Picker Row               │
│               │ ┌──────────┐ ～ ┌──────────┐       │
│               │ │ Start    │    │ End      │       │
│               │ └──────────┘    └──────────┘       │
└─────────────────────────────────────────────────────┘
```

**HTML/JSX Structure Template**:
```tsx
<div className="flex items-start gap-1 w-full mb-[30px]">
  <label className="w-[176px] flex-shrink-0 pt-[2px] text-sm font-normal text-[#111827] tracking-[1.2px]">
    活動時間
    {required && <span className="text-[#E30200]">*</span>}
  </label>

  <div className="flex-1 flex flex-col gap-3">
    {/* Helper Text - Above date picker */}
    <p className="text-xs text-[#667079] leading-[1.5] tracking-[0.4px] m-0 pl-3 relative before:content-['•'] before:absolute before:left-0">
      此時間僅供活動紀錄與成效認列之用，實際開始時間以連結 Facebook 直播的時間為準。
    </p>

    {/* Date Range Picker Row */}
    <div className="flex items-center gap-3">
      <div className="w-40 h-10 border border-[#A0A6B0] bg-[#F3F4F6] rounded px-3 flex items-center justify-between">
        <span>2025-11-08 18:00</span>
        {/* Calendar icon */}
      </div>
      <span className="text-[#A0A6B0]">～</span>
      <div className="w-40 h-10 border border-[#A0A6B0] bg-[#F3F4F6] rounded px-3 flex items-center justify-between">
        <span>2025-11-08 20:00</span>
        {/* Calendar icon */}
      </div>
    </div>
  </div>
</div>
```

**Key Rules**:
1. **Helper Text Position**: MUST be inside the input area container, ABOVE the input controls
2. **Helper Text Style**: Use bullet point (`•`) with `pl-3` and `before:` pseudo-element
3. **Vertical Spacing**: `gap-3` (12px) between helper text and date picker row
4. **Date Picker Alignment**: Use `flex items-center gap-3` for horizontal layout

**When to Use**:
- Form fields with explanatory helper text
- Date range pickers
- Any field requiring additional context above the input

---
```