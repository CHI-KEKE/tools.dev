**Format Example:**
```markdown
| Visual Element | Component Library | Import Statement | Props & Variants | Usage Strategy | Usage Example |
|---|---|---|---|---|---|
| Status Chip | `@91app/atmos-ui` | `import { Chip } from '@91app/atmos-ui'` | `variant="display"`, `color="green"`, `isShowStartIcon={true}` | Direct Use | `<Chip variant="display" color="green" isShowStartIcon>進行中</Chip>` |
| Text Input | `@91app/atmos-ui` | `import { Input } from '@91app/atmos-ui'` | `type="text"`, `value`, `onChange`, `placeholder` | Wrapped Component | Wrap in custom component for character counter integration |
| Character Counter | None | N/A | N/A | Custom Component | `<span className="text-xs text-[#667079]">(8/50)</span>` |
| Page Title | None | N/A | N/A | Custom Component | Requires custom styling: `<h1 className="text-2xl font-medium">Page Title</h1>` |
```

**Example with Complete Details**:
```markdown
| Visual Element | Component Library | Import Statement | Props & Variants | Usage Strategy | Usage Example |
|---|---|---|---|---|---|
| Status Chip | `@91app/atmos-ui` | `import { Chip } from '@91app/atmos-ui'` | **Required**: `variant="display"`, `color="green"`<br>**Optional**: `isShowStartIcon={true}` | Direct Use | ```tsx\n<Chip variant="display" color="green" isShowStartIcon>\n  進行中\n</Chip>\n``` |
| Text Input with Counter | `@91app/atmos-ui` | `import { Input } from '@91app/atmos-ui'` | **Required**: `type="text"`, `value`, `onChange`<br>**Optional**: `placeholder`, `maxLength` | Wrapped Component | Wrap in custom `FormField` component that adds character counter: ```tsx\n<FormField\n  label="直播名稱"\n  required\n  characterCount={{ current: 8, max: 50 }}\n>\n  <Input\n    type="text"\n    value={value}\n    onChange={onChange}\n    maxLength={50}\n  />\n</FormField>\n``` |
```