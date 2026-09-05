---
name: f2e-designing-core-architecture
description: Generate core architectural design focusing on concrete frontend implementation artifacts.
allowed-tools:
  - read_file
  - file_search
  - create_file
---

## Preconditions

- Work Item Description must be provided
- Output directory `.github/docs/{{userStoryId}}/` must be accessible
- F2E Clarifications complete (optional)
- Figma analysis documents (`.github/docs/{{userStoryId}}/figma-analysis-*.md`) complete (optional)

**Input:**
- Work Item Description (requirement description)
- Custom.FrontendImplementPlan (existing implementation plan, may be empty)
- Tags (relevant tags)
- Clarifications (clarification content extracted from Comments)
- Figma Analysis Documents (design analysis documents read from `.github/docs/{{userStoryId}}/figma-analysis-*.md`, may not exist)

## Workflow Steps

**Output:**
-   **File Path**: `.github/docs/{{userStoryId}}/implement-plan.md`
-   **Content and Format**: The generated document must include the sections `New Files`, `Modified Files`, `File Tree`, `API Contract Changes`, `Key Code Responsibilities`, and `Design Summary`, strictly adhering to the specified format below.

Generate core architectural design focusing on **concrete frontend implementation artifacts**:

---

#### 3.1 📁 New Files
List all new React components, hooks, stores, types, or services to be created:
```markdown
| File Path | Purpose | Key Responsibilities |
|-----------|---------|----------------------|
| `src/components/feature/PromotionCard.tsx` | Display promotion information | Render promotion UI, handle user interactions |
| `src/hooks/usePromotion.ts` | Promotion data fetching logic | Fetch promotion data via SWR, manage loading/error states |
| `src/stores/promotionStore.ts` | Promotion state management | Manage promotion selection state using Zustand |
| `src/types/promotion.ts` | TypeScript type definitions | Define Promotion, PromotionProduct interfaces |
| `src/services/promotionApi.ts` | API service layer | Encapsulate API calls, handle request/response transformation |
```

---

#### 3.2 ✏️ Modified Files
List existing files that need to be updated:
```markdown
| File Path | Changes Required | Reason |
|-----------|------------------|--------|
| `src/pages/ProductDetailPage.tsx` | Add promotion display section | Show active promotions for product |
| `src/components/common/ProductCard.tsx` | Add promotion badge prop | Display promotion indicator on product cards |
| `src/hooks/useProduct.ts` | Extend return type with promotion data | Include promotion information in product queries |
```

---

#### 3.3 🗂️ File Tree
Complete directory structure showing all affected files:
```
ProjectRoot/
├── src/
│   ├── components/
│   │   ├── feature/
│   │   │   └── PromotionCard.tsx [NEW]
│   │   └── common/
│   │       └── ProductCard.tsx [MODIFIED]
│   ├── hooks/
│   │   ├── usePromotion.ts [NEW]
│   │   └── useProduct.ts [MODIFIED]
│   ├── stores/
│   │   └── promotionStore.ts [NEW]
│   ├── types/
│   │   └── promotion.ts [NEW]
│   ├── services/
│   │   └── promotionApi.ts [NEW]
│   └── pages/
│       └── ProductDetailPage.tsx [MODIFIED]
└── tests/
    └── components/
        └── PromotionCard.test.tsx [NEW]

📊 Summary:
- Total files affected: 8
- New files: 6
- Modified files: 2
- Directories affected: 6
```

---

#### 3.4 📞 API Contract Changes
Define required changes to API request/response structures from a frontend perspective:
```markdown
**New API Endpoints:**
- `GET /api/promotions/active` - Get active promotions
  - Response: `{ promotions: Promotion[] }`
  - Query params: `?productId={id}` (optional filter)

**Modified API Endpoints:**
- `GET /api/products/{id}` - Extend response to include promotion data
  - Added field: `currentPromotion: Promotion | null`
  - Added field: `promotionDiscount: number | null`

**Request/Response Types:**
```typescript
interface Promotion {
  id: string;
  name: string;
  discountRate: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
}

interface ProductResponse {
  id: string;
  name: string;
  price: number;
  currentPromotion: Promotion | null;  // NEW
  promotionDiscount: number | null;    // NEW
}
```

**Error Handling:**
- 404: Promotion not found
- 400: Invalid promotion parameters
- 429: Rate limit exceeded (promotion queries)
```

---

#### 3.5 🔑 Key Code Responsibilities

**Component Architecture:**
- `PromotionCard`: Presentational component for promotion display (follows SRP)
- `ProductDetailPage`: Container component orchestrating product + promotion data
- Component composition: Reuse existing `Card`, `Badge`, `Button` from design system

**State Management Strategy:**
- **Local State**: Use `useState` for UI-only state (e.g., modal open/close)
- **Server State**: Use SWR hooks (`usePromotion`, `useProduct`) for data fetching and caching
- **Global State**: Use Zustand store (`promotionStore`) for cross-component promotion selection state
- **URL State**: Use query parameters for promotion filtering (shareable URLs)

**Hook Utilization:**
- `usePromotion(productId)`: Fetch and cache promotion data with automatic revalidation
- `useProduct(id)`: Extended to include promotion data in response
- Custom hook composition: `usePromotionWithProduct()` combines both hooks for convenience

**Reuse Existing Components:**
- ✅ Leverage `useProductQuery()` hook instead of creating new `useProductDetailService`
- ✅ Reuse `Card`, `Badge`, `Button` components from `atmos-ui` or `spark-ui` library
- ✅ Extend existing `ProductCard` component with promotion prop rather than creating new component
- ❌ Do NOT create new `PromotionTagService` - use existing tag utilities

**Figma-driven UI Components:**
- If Figma analysis provided:
  - List UI components needed based on Figma DOM structure
  - Specify whether to use existing library components or create new ones
  - Note styling requirements based on Design Tokens (colors, spacing, typography)

**Critical Implementation Points:**
1. **Component Separation**: Keep `PromotionCard` as pure presentational component (no business logic)
2. **Data Fetching**: Use SWR for automatic caching and revalidation of promotion data
3. **Type Safety**: Define strict TypeScript interfaces for all API contracts
4. **Error Boundaries**: Wrap promotion components in error boundaries for graceful failure handling
5. **Accessibility**: Ensure promotion cards meet WCAG 2.1 AA standards (keyboard navigation, screen reader support)

---

### Design Summary
```markdown
## 📋 Core Design Summary

### System Design Overview
- **Files Affected**: 8 total (6 new, 2 modified)
- **API Contract Changes**: 1 new endpoint, 1 modified endpoint
- **Key Components**: PromotionCard component, usePromotion hook, promotionStore (Zustand), promotionApi service

### Implementation Approach
Create dedicated `PromotionCard` presentational component following Single Responsibility Principle. Use SWR hooks for server state management and Zustand for global client state. Leverage existing design system components (`atmos-ui`/`spark-ui`) for consistent UI. Prioritize reusability by extending existing hooks and components rather than creating new ones.

### File Organization
Organize new components in `src/components/feature`, hooks in `src/hooks`, stores in `src/stores`, types in `src/types`, and services in `src/services`. All modifications follow existing React project structure conventions and component organization patterns.
```

---

## Hard Constraints

- **All 6 sections required**: New Files, Modified Files, File Tree, API Contract Changes, Key Code Responsibilities, and Design Summary must not be omitted
- **No code implementation**: Only perform architectural planning and file documentation; must not include actual implementation code
- **Reuse first**: Must evaluate whether existing hooks / components can be extended before considering creating new ones
- **Frontend scope only**: Must not plan backend service implementation scope

## Good/Bad Examples

**✅ Good — Key Code Responsibilities clearly marks reuse decisions**
```markdown
**Reuse Existing Components:**
- ✅ Leverage `useProductQuery()` hook instead of creating new `useProductDetailService`
- ✅ Reuse `Card`, `Badge`, `Button` components from `atmos-ui`
- ❌ Do NOT create new `PromotionTagService` - use existing tag utilities
```

**❌ Bad — File Tree missing responsibility attributes**
```markdown
| File Path | Purpose |
|-----------|---------|  
| `src/components/PromotionCard.tsx` | Component |
```
(Missing the Key Responsibilities column; cannot understand each file's responsibility scope)

## Quality Checklist

- [ ] All 6 required sections are included
- [ ] File Tree includes [NEW] / [MODIFIED] markers
- [ ] API Contract Changes includes TypeScript interface definitions
- [ ] Key Code Responsibilities includes reuse decisions (✅ / ❌ markers)
- [ ] Design Summary includes total counts (Files Affected, New, Modified)
- [ ] No actual implementation code included