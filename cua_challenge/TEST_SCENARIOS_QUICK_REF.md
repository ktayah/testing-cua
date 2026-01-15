# Test Scenarios Quick Reference

## Overview
Three test data files with increasing difficulty and format variations.

## Quick Comparison

| Field | test_data_1.json | test_data_2.json | test_data_3.json |
|-------|------------------|------------------|------------------|
| **Name** | Sarah Mitchell | Marcus Rodriguez | Aisha Okonkwo |
| **DOB Format** | ISO+TZ `...T00:00:00Z` | ISO Date `1988-11-22` | DD/MM/YYYY `15/07/1990` |
| **Phone Format** | `(415) 555-0123` | `1-604-555-3421` | `202 555 7890` |
| **Country** | United States → `us` | Canada → `ca` | United Kingdom → `uk` |
| **Skills Count** | 3 | 4 | 2 (minimum) |
| **Company Search** | "Google" | "Meta" | "Apple" |
| **Product Search** | Electronics + laptop | USB + price range | Mechanical + note |
| **Project Type** | Web | Mobile | Data Science |
| **Framework** | React hint | Flutter explicit | TensorFlow explicit |
| **Vendor Search** | Location + rating | Spec + location | Keyword + rating |
| **Date Complexity** | ISO with timezone | ISO with ms | Already YYYY-MM-DD |

## Expected Conversions

### Date of Birth

```
test_data_1: "1992-03-15T00:00:00Z"        → "1992-03-15"
test_data_2: "1988-11-22"                  → "1988-11-22" (no change)
test_data_3: "15/07/1990"                  → "1990-07-15"
```

### Phone Numbers (to XXX-XXX-XXXX)

```
test_data_1: "(415) 555-0123"              → "415-555-0123"
test_data_2: "1-604-555-3421"              → "604-555-3421"
test_data_3: "202 555 7890"                → "202-555-7890"

Emergency:
test_data_1: "415.555.9876"                → "415-555-9876"
test_data_2: "+1 604 555 8899"             → "604-555-8899"
test_data_3: "202-555-4433"                → "202-555-4433" (no change)
```

### Timeline Dates (to YYYY-MM-DD)

```
test_data_1:
  Start: "2024-02-01T09:00:00-08:00"       → "2024-02-01"
  End:   "2024-08-31T17:00:00-08:00"       → "2024-08-31"

test_data_2:
  Start: "2024-03-15T00:00:00.000Z"        → "2024-03-15"
  End:   "2025-01-15T23:59:59.999Z"        → "2025-01-15"

test_data_3:
  Start: "2024-05-01"                      → "2024-05-01" (no change)
  End:   "2024-11-30"                      → "2024-11-30" (no change)
```

## Search Strategies

### Page 3: Product Selection

| File | Given Info | Search Term | Expected Result |
|------|-----------|-------------|-----------------|
| 1 | category: Electronics, type: laptop | "laptop" OR "electronics" | Professional Laptop |
| 2 | name contains: USB, price: $50-$100 | "USB" | USB-C Hub ($79) |
| 3 | partial: "Mechanical", note: ~$149 | "Mechanical" | Mechanical Keyboard ($149) |

### Page 4: Vendor Selection

| File | Given Info | Search Term | Expected Result |
|------|-----------|-------------|-----------------|
| 1 | location: San Francisco, rating: 4.8 | "San Francisco" OR "4.8" | TechSolutions Inc. |
| 2 | spec: Mobile Apps, location: New York | "Mobile" OR "New York" | Innovate Systems |
| 3 | keyword: Data, rating: 4.7+ | "Data" | DataWise Analytics |

## Framework Selection (Dependent Field)

**Step 1:** Select Project Type
```
test_data_1: Web Development
test_data_2: Mobile Development
test_data_3: Data Science
```

**Step 2:** Wait for framework field to appear

**Step 3:** Search and select framework
```
test_data_1: Search "React" → Select "React"
test_data_2: Search "Flutter" → Select "Flutter"
test_data_3: Search "TensorFlow" → Select "TensorFlow"
```

## Multi-Select Requirements

### Page 2: Skills (minimum 2)
```
test_data_1: 3 skills ✓
test_data_2: 4 skills ✓
test_data_3: 2 skills ✓ (exactly minimum)
```

### Page 4: Features (minimum 3)
```
test_data_1: 4 features ✓
test_data_2: 4 features ✓
test_data_3: 3 features ✓ (exactly minimum)
```

## Difficulty Rating

### test_data_1.json - ⭐⭐⭐ HARD
**Challenges:**
- ISO timestamps with timezone offsets
- Parentheses in phone number
- Ambiguous framework hint ("most popular React-based")
- Multiple vendor criteria

**Good for:** Testing robust date parsing and ambiguous hint interpretation

### test_data_2.json - ⭐⭐ MEDIUM
**Challenges:**
- International phone format with country code
- ISO with milliseconds
- Price range interpretation
- Specialization-based vendor search

**Good for:** Testing international format handling and range-based searches

### test_data_3.json - ⭐ EASY
**Challenges:**
- DD/MM/YYYY date format (non-US)
- Most dates already in correct format
- Straightforward search terms
- Explicit framework selection

**Good for:** Initial testing and verifying basic agent capabilities

## Usage

### Test All Scenarios
```bash
# Test 1
mix run -e "CuaApp.Agent.execute_task_with_file(\"test_data_1.json\")"

# Test 2
mix run -e "CuaApp.Agent.execute_task_with_file(\"test_data_2.json\")"

# Test 3
mix run -e "CuaApp.Agent.execute_task_with_file(\"test_data_3.json\")"
```

### Access Test Data from Web
```
http://localhost:8080/test_data_1.json
http://localhost:8080/test_data_2.json
http://localhost:8080/test_data_3.json
```

## Validation Checklist

For each test file, verify:

- [ ] All 4 pages completed
- [ ] Page 1: All fields filled with correct formats
- [ ] Page 2: At least 2 skills selected
- [ ] Page 2: One radio button selected
- [ ] Page 3: Emergency contact section expanded
- [ ] Page 3: Correct product selected via search
- [ ] Page 4: Project type selected first
- [ ] Page 4: Framework appears and is selected
- [ ] Page 4: At least 3 features selected
- [ ] Page 4: Both collapsible sections expanded
- [ ] Page 4: Correct vendor selected via search
- [ ] Page 4: Agreement checkbox checked
- [ ] Success page reached
- [ ] All data displayed correctly on success page

## Common Agent Mistakes

1. ❌ Using ISO timestamp as-is without extracting date
2. ❌ Not removing country code from phone numbers
3. ❌ Selecting wrong country dropdown value
4. ❌ Searching only one keyword when multiple provided
5. ❌ Not scrolling/paginating to find hidden items
6. ❌ Selecting framework before project type
7. ❌ Selecting only 1 skill or 2 features (under minimum)
8. ❌ Ignoring modal popups
9. ❌ Not expanding collapsible sections
10. ❌ Exact string matching instead of partial search

---

**Pro Tip:** Start with test_data_3.json for initial testing, then progress to harder scenarios! 🚀
