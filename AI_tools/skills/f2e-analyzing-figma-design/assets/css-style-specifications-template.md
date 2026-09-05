```markdown
## Button Styles

### Primary Button
```css
.btn-primary {
  /* Layout */
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 120px;
  height: 40px;
  padding: 8px 16px;
  
  /* Typography */
  font-family: 'Noto Sans TC', sans-serif;
  font-size: 14px;
  font-weight: 500;
  line-height: 1.8;
  letter-spacing: 1.2px;
  color: #FFFFFF;
  text-align: center;
  
  /* Visual */
  background-color: #3B82F6;
  border: none;
  border-radius: 4px;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  
  /* Interaction */
  cursor: pointer;
  transition: all 0.2s ease-in-out;
}

.btn-primary:hover {
  background-color: #2563EB;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.btn-primary:focus-visible {
  outline: 2px solid #3B82F6;
  outline-offset: 2px;
}

.btn-primary:active {
  background-color: #1D4ED8;
  transform: scale(0.98);
}

.btn-primary:disabled {
  background-color: #9CA3AF;
  cursor: not-allowed;
  opacity: 0.6;
}
```
```