# Test Data Files for CUA Challenge

This directory contains 3 JSON files with test data for automated agent testing. Each file presents different formatting challenges that require the agent to process and adapt the data before filling out the forms.

## Files

- `test_data_1.json` - Web developer scenario with international formats
- `test_data_2.json` - Mobile developer scenario with varied phone formats
- `test_data_3.json` - Data scientist scenario with maximum format variations

## Data Challenges by Field

### Page 1: Basic Information

#### Date of Birth
**Challenge:** Multiple date formats that need conversion to `YYYY-MM-DD`

| File | Format | Example | Agent Must |
|------|--------|---------|------------|
| test_data_1.json | ISO 8601 with timezone | `1992-03-15T00:00:00Z` | Extract date portion |
| test_data_2.json | ISO date only | `1988-11-22` | Use as-is or validate |
| test_data_3.json | DD/MM/YYYY | `15/07/1990` | Parse and reformat to `1990-07-15` |

#### Phone Number
**Challenge:** Multiple formats that need conversion to `XXX-XXX-XXXX`

| File | Format | Example | Agent Must |
|------|--------|---------|------------|
| test_data_1.json | US parentheses | `(415) 555-0123` | Convert to `415-555-0123` |
| test_data_2.json | International with country code | `1-604-555-3421` | Extract to `604-555-3421` |
| test_data_3.json | Space-separated | `202 555 7890` | Convert to `202-555-7890` |

#### Country
**Challenge:** Full country names need to match dropdown values

| File | Provided | Dropdown Value | Agent Must |
|------|----------|----------------|------------|
| test_data_1.json | "United States" | "us" | Map to correct value |
| test_data_2.json | "Canada" | "ca" | Map to correct value |
| test_data_3.json | "United Kingdom" | "uk" | Map to correct value |

### Page 2: Additional Details

#### Skills
**Challenge:** Ensure at least 2 skills are selected from available options

| File | Skills Provided | Valid Selections |
|------|----------------|------------------|
| test_data_1.json | 3 skills | ✓ All match dropdown |
| test_data_2.json | 4 skills | ✓ All match dropdown |
| test_data_3.json | 2 skills (minimum) | ✓ Exactly minimum |

#### Employment Status
**Challenge:** Match exact dropdown text

All files provide exact matches to test straightforward selection.

### Page 3: Advanced Selection

#### Company (Searchable Dropdown)
**Challenge:** Only hints provided, agent must search and select

| File | Hint Provided | Agent Must |
|------|---------------|------------|
| test_data_1.json | "Search for the company that starts with 'Google'" | Search "Google" and select "Google Inc." |
| test_data_2.json | "Find Meta Platforms" | Search "Meta" and select "Meta Platforms Inc." |
| test_data_3.json | "Search for Apple" | Search "Apple" and select "Apple Inc." |

#### Emergency Contact Phone
**Challenge:** Various phone formats to convert

| File | Format | Example | Agent Must |
|------|--------|---------|------------|
| test_data_1.json | Dot-separated | `415.555.9876` | Convert to `415-555-9876` |
| test_data_2.json | International with spaces | `+1 604 555 8899` | Extract to `604-555-8899` |
| test_data_3.json | Already correct | `202-555-4433` | Use as-is |

#### Product Selection (Table Search)
**Challenge:** Only partial information provided - agent must construct search query

| File | Info Provided | Agent Strategy |
|------|---------------|----------------|
| test_data_1.json | Category: "Electronics", Type: "laptop" | Search "laptop" or "Electronics laptop" |
| test_data_2.json | Name contains: "USB", Price: "$50-$100" | Search "USB" to find USB-C Hub ($79) |
| test_data_3.json | Partial name: "Mechanical", Note: "around $149" | Search "Mechanical" to find Mechanical Keyboard |

### Page 4: Final Challenge

#### Framework (Dependent Field)
**Challenge:** Framework selection depends on project type + hint interpretation

| File | Project Type | Hint | Agent Must Select |
|------|-------------|------|-------------------|
| test_data_1.json | Web Development | "Most popular React-based" | Search for "React" → Select "React" |
| test_data_2.json | Mobile Development | "Choose Flutter" | Search "Flutter" → Select "Flutter" |
| test_data_3.json | Data Science | "Select TensorFlow" | Search "TensorFlow" → Select "TensorFlow" |

#### Vendor Selection (Table Search)
**Challenge:** Multiple search criteria provided - agent must prioritize and search

| File | Criteria Provided | Agent Strategy |
|------|------------------|----------------|
| test_data_1.json | Location: "San Francisco", Rating: 4.8 | Search "San Francisco" or "4.8" → Find TechSolutions Inc. |
| test_data_2.json | Specialization: "Mobile Apps", Location contains: "New York" | Search "Mobile" or "New York" → Find Innovate Systems |
| test_data_3.json | Keyword: "Data", Rating min: "4.7" | Search "Data" → Find DataWise Analytics (4.7 rating) |

#### Timeline Dates
**Challenge:** Various date formats to convert to `YYYY-MM-DD`

| File | Start Date Format | End Date Format | Agent Must |
|------|------------------|-----------------|------------|
| test_data_1.json | ISO with timezone | `2024-02-01T09:00:00-08:00` | Extract date → `2024-02-01` |
| test_data_2.json | ISO milliseconds | `2024-03-15T00:00:00.000Z` | Extract date → `2024-03-15` |
| test_data_3.json | Already correct | `2024-05-01` | Use as-is |

## Agent Processing Requirements

### 1. Date Parsing
The agent must handle:
- ISO 8601 timestamps (with/without timezone)
- ISO date-only format
- DD/MM/YYYY format
- Convert all to YYYY-MM-DD for form input

### 2. Phone Number Normalization
The agent must:
- Remove parentheses, dots, spaces, plus signs
- Remove country code prefix (1-)
- Format as XXX-XXX-XXXX

### 3. Country Mapping
The agent must:
- Map full country names to dropdown values
- Common mappings: US/USA→us, Canada→ca, UK→uk

### 4. Search Strategy
The agent must:
- **Construct search queries** from partial information
- **Test multiple search terms** if first attempt fails
- **Verify results** match the criteria (category, price, location, etc.)
- **Handle pagination** to find items not on first page

### 5. Dependent Field Logic
The agent must:
- Select project type FIRST
- Wait for framework field to appear
- THEN search and select framework

## Usage Example (Elixir)

```elixir
# Load test data
test_data = File.read!("test_data_1.json") |> Jason.decode!()

# Execute task with structured data
task = """
Complete the CUA Challenge form at http://cua-challenge using this information:

Page 1:
- First Name: #{test_data["page1"]["first_name"]}
- Last Name: #{test_data["page1"]["last_name"]}
- Email: #{test_data["page1"]["email"]}
- Date of Birth: #{test_data["page1"]["date_of_birth"]} (convert to YYYY-MM-DD)
- Country: #{test_data["page1"]["country"]}
- Phone: #{test_data["page1"]["phone_number"]} (convert to XXX-XXX-XXXX)

Page 2:
- Address: #{test_data["page2"]["street_address"]}
- City: #{test_data["page2"]["city"]}
- Zip: #{test_data["page2"]["zip_code"]}
- Employment: #{test_data["page2"]["employment_status"]}
- Skills: Select #{Enum.join(test_data["page2"]["skills"], ", ")}
- Experience: #{test_data["page2"]["years_of_experience"]}
- Contact Method: #{test_data["page2"]["preferred_contact_method"]}

Page 3:
- Company: #{test_data["page3"]["company"]["hint"]}
- Emergency Contact: #{test_data["page3"]["emergency_contact"]["name"]}
- Emergency Phone: #{test_data["page3"]["emergency_contact"]["phone"]} (convert to XXX-XXX-XXXX)
- Relationship: #{test_data["page3"]["emergency_contact"]["relationship"]}
- Product: #{test_data["page3"]["product"]["search_hint"]}

Page 4:
- Project Type: #{test_data["page4"]["project_type"]}
- Framework: #{test_data["page4"]["framework"]["hint"]}
- Features: Select #{Enum.join(test_data["page4"]["features"], ", ")}
- Budget: $#{test_data["page4"]["budget"]}
- Team Size: #{test_data["page4"]["team"]["size"]}
- PM Name: #{test_data["page4"]["team"]["project_manager"]}
- Vendor: #{test_data["page4"]["vendor"]["search_hint"]}
- Start Date: #{test_data["page4"]["timeline"]["start_date"]} (convert to YYYY-MM-DD)
- End Date: #{test_data["page4"]["timeline"]["end_date"]} (convert to YYYY-MM-DD)
- Accept agreement checkbox
"""

CuaApp.Agent.execute_task(task)
```

## Validation Criteria

### Success Criteria
✅ All 4 pages completed
✅ All required fields filled
✅ All format validations passed
✅ Correct items selected from searchable tables
✅ Reached success page

### Common Failure Points
❌ Date format not converted properly
❌ Phone format not converted properly
❌ Wrong country dropdown value selected
❌ Search failed to find correct product/vendor
❌ Less than 2 skills selected (page 2)
❌ Less than 3 features selected (page 4)
❌ Framework field not appearing (forgot to select project type first)
❌ Wrong vendor selected (didn't match criteria)

## Difficulty Progression

| Test File | Difficulty | Reason |
|-----------|-----------|--------|
| test_data_3.json | ⭐ Easy | Dates mostly correct, straightforward searches |
| test_data_2.json | ⭐⭐ Medium | International phone format, timezone handling |
| test_data_1.json | ⭐⭐⭐ Hard | Complex ISO timestamps, ambiguous search hints |

## Testing Tips

1. **Start with test_data_3.json** - Least format conversions required
2. **Test date parsing separately** - Common failure point
3. **Verify search strategies** - Agent should try multiple search terms
4. **Check pagination** - Some items may not be on first page
5. **Monitor modal handling** - Modals appear randomly (no hints given)

## Expected Agent Capabilities

To successfully complete these tests, the agent should demonstrate:

1. **Date/Time Parsing** - Handle multiple formats and timezones
2. **String Manipulation** - Format phone numbers, clean search terms
3. **Mapping/Lookup** - Country names to values
4. **Search Strategy** - Construct effective queries from partial data
5. **Result Verification** - Confirm selection matches criteria
6. **Conditional Logic** - Handle dependent fields
7. **Error Recovery** - Retry with different search terms if needed
8. **UI Awareness** - Handle modals, pagination, collapsible sections

---

**Ready to test?** Load a test data file and let your agent work through the challenge! 🤖
