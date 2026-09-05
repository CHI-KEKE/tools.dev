**Format Example:**

## Main Container Structure

```tsx
import React from 'react';

export const MainContainer = () => {
  return (
    <main className="main-container bg-white p-5 rounded-[10px] border border-gray-200">
      <header className="page-header mb-6">
        <h1 className="page-title text-2xl font-medium text-[#111827]">Page Title</h1>
      </header>
      
      <section className="content-section">
        <h2 className="section-title text-xl font-medium text-[#111827] mb-4">Section Title</h2>
        <div className="section-content">
          {/* Content here */}
        </div>
      </section>
    </main>
  );
};
```

## Form Structure with Component Library Integration

**Pattern Used**: `FixedWidthHorizontalLabel` (from Layout Patterns section 10)

```tsx
import React from 'react';
import { Input, Chip } from '@91app/atmos-ui';

export const FormField = ({ 
  label, 
  required, 
  helperText, 
  characterCount,
  value,
  onChange 
}) => {
  return (
    <div className="flex items-start gap-1 w-full mb-[30px]">
      {/* Label - Following Pattern 1: Fixed-Width Horizontal Label */}
      <label className="w-[176px] flex-shrink-0 pt-[2px] text-sm font-normal text-[#111827] tracking-[1.2px]">
        <span>{label}</span>
        {required && (
          <span className="text-[#E30200]" aria-label="required">*</span>
        )}
      </label>

      {/* Input Area - Flexible Width */}
      <div className="flex-1 flex flex-col gap-3">
        {/* Input Row - Following Pattern 2: Input with External Counter */}
        <div className="flex items-center gap-3">
          <Input
            type="text"
            value={value}
            onChange={onChange}
            className="flex-1 h-10 px-3 border border-[#A0A6B0] rounded"
            maxLength={characterCount?.max}
            aria-required={required}
            aria-describedby={helperText ? `${label}-help` : undefined}
          />
          {/* Character Counter - External, Right-aligned */}
          {characterCount && (
            <span 
              className="text-xs text-[#667079] tracking-[0.4px] whitespace-nowrap"
              aria-live="polite"
              aria-atomic="true"
            >
              ({characterCount.current}/{characterCount.max})
            </span>
          )}
        </div>

        {/* Helper Text - Below input, left-aligned */}
        {helperText && (
          <p 
            id={`${label}-help`}
            className="text-xs text-[#667079] leading-[1.5] tracking-[0.4px] m-0"
          >
            {helperText}
          </p>
        )}
      </div>
    </div>
  );
};

// Usage Example
export const FormExample = () => {
  const [name, setName] = React.useState('雙十一王小明直播');
  
  return (
    <form className="form-container" aria-label="基本設定表單">
      {/* Status Field */}
      <div className="flex items-center gap-1 w-full mb-[30px]">
        <label className="w-[176px] flex-shrink-0 text-sm font-normal text-[#111827] tracking-[1.2px]">
          狀態
        </label>
        <div className="flex-1">
          <Chip variant="display" color="green" isShowStartIcon>
            進行中
          </Chip>
        </div>
      </div>

      {/* Name Field with Counter */}
      <FormField
        label="直播名稱"
        required
        value={name}
        onChange={(e) => setName(e.target.value)}
        characterCount={{ current: name.length, max: 50 }}
      />

      {/* Activity Time Field with Helper Text */}
      <div className="flex items-start gap-1 w-full mb-[30px]">
        <label className="w-[176px] flex-shrink-0 pt-[2px] text-sm font-normal text-[#111827] tracking-[1.2px]">
          活動時間
          <span className="text-[#E30200]">*</span>
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
    </form>
  );
};
```

## Complex Nesting Structure Example

**Pattern Used**: `FormFieldWithHelperTextAndDateRange` (from Layout Patterns section 10)

```tsx
// This example shows how helper text is nested INSIDE the input area container,
// positioned ABOVE the date picker controls
<div className="flex items-start gap-1 w-full mb-[30px]">
  {/* Label - Fixed width */}
  <label className="w-[176px] flex-shrink-0 pt-[2px]">
    活動時間 <span className="text-[#E30200]">*</span>
  </label>

  {/* Input Area Container - Flexible width */}
  <div className="flex-1 flex flex-col gap-3">
    {/* Helper Text - Nested INSIDE input area, ABOVE controls */}
    <p className="text-xs text-[#667079] m-0">
      Helper text goes here, above the input controls
    </p>

    {/* Input Controls - Below helper text */}
    <div className="flex items-center gap-3">
      {/* Date picker inputs */}
    </div>
  </div>
</div>
```