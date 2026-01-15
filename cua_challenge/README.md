# CUA Challenge - Computer Use Agent Testing Platform

A comprehensive web-based challenge application designed to test Computer Use Agents (CUA) capabilities across multiple difficulty levels. This application provides a realistic testing environment for agents to interact with various web form elements, modals, and complex UI patterns.

## 🎯 Overview

The CUA Challenge consists of 4 progressively difficult pages with a total of 12+ different input types and interaction patterns:

- **Page 1 (Easy)**: Basic form inputs, dropdowns, and formatted fields
- **Page 2 (Medium)**: Multi-select, radio buttons, and random popup modals
- **Page 3 (Hard)**: Searchable dropdowns, collapsible sections, and table selection
- **Page 4 (Very Hard)**: Dependent fields, multiple collapsibles, complex table search, and multiple modals

## 🛠️ Technology Stack

This is a **lightweight, zero-dependency** solution using:

- **HTML5** - Structure and content
- **Tailwind CSS** (CDN) - Styling and responsive design
- **Vanilla JavaScript** - All interactions and validation
- **nginx** (Alpine) - Web server for Docker deployment

No build tools, no package managers, no frameworks - just simple, clean web technologies.

## ✨ Features Tested

### Input Types
- ✅ Text input fields
- ✅ Email inputs with validation
- ✅ Telephone inputs with format validation
- ✅ Number inputs with min/max constraints
- ✅ Date inputs with YYYY-MM-DD format requirement
- ✅ Dropdown select menus
- ✅ Multi-select inputs
- ✅ Radio button groups
- ✅ Checkbox inputs

### Interactive Elements
- ✅ Searchable dropdowns with real-time filtering
- ✅ Table search with dynamic row filtering
- ✅ Clickable table rows for selection
- ✅ Collapsible sections (accordion-style)
- ✅ Random popup modals
- ✅ Dependent/conditional fields
- ✅ Form validation with error messages

### Advanced Patterns
- ✅ Multi-page workflow with navigation
- ✅ Session storage for data persistence
- ✅ Format-specific validation (phone, zip, date)
- ✅ Dynamic content generation based on selections
- ✅ Hidden fields revealed by user actions

## 🚀 Quick Start

### Option 1: Docker (Recommended)

1. **Build the Docker image:**
   ```bash
   cd cua_challenge
   docker build -t cua-challenge .
   ```

2. **Run the container:**
   ```bash
   docker run -d -p 8080:80 --name cua-challenge cua-challenge
   ```

3. **Access the application:**
   ```
   http://localhost:8080
   ```

4. **Stop and remove:**
   ```bash
   docker stop cua-challenge
   docker rm cua-challenge
   ```

### Option 2: Python HTTP Server

1. **Navigate to the directory:**
   ```bash
   cd cua_challenge
   ```

2. **Start the server:**
   ```bash
   python3 -m http.server 8080
   ```

3. **Access the application:**
   ```
   http://localhost:8080
   ```

### Option 3: Node.js HTTP Server

1. **Install http-server globally (one-time):**
   ```bash
   npm install -g http-server
   ```

2. **Start the server:**
   ```bash
   cd cua_challenge
   http-server -p 8080
   ```

3. **Access the application:**
   ```
   http://localhost:8080
   ```

## 📋 Challenge Details

### Page 1: Basic Information (Easy)
**Difficulty:** 🟢 Easy

**Fields:**
- First Name (text)
- Last Name (text)
- Email (email with validation)
- Date of Birth (YYYY-MM-DD format)
- Country (dropdown)
- Phone Number (XXX-XXX-XXXX format)

**Skills Tested:**
- Basic form filling
- Format validation
- Dropdown selection

---

### Page 2: Additional Details (Medium)
**Difficulty:** 🟡 Medium

**Fields:**
- Street Address (text)
- City (text)
- Zip Code (5 digits)
- Employment Status (dropdown)
- Skills (multi-select, minimum 2)
- Years of Experience (dropdown)
- Preferred Contact Method (radio buttons)

**Skills Tested:**
- Multi-select interaction
- Radio button selection
- Handling random popup modals
- Format-specific validation

**Challenge:** A random popup modal appears that must be closed to proceed.

---

### Page 3: Advanced Selection (Hard)
**Difficulty:** 🟠 Hard

**Fields:**
- Company (searchable dropdown)
- Emergency Contact Name (hidden in collapsible)
- Emergency Contact Phone (hidden, XXX-XXX-XXXX format)
- Relationship (hidden dropdown)
- Product Selection (from searchable table)

**Skills Tested:**
- Searchable dropdown interaction
- Expanding collapsible sections
- Filling hidden fields
- Table search and row selection
- Handling modals

**Challenges:**
- Fields are hidden behind collapsible section
- Must search and select from a table
- Random popup modal

---

### Page 4: Final Challenge (Very Hard)
**Difficulty:** 🔴 Very Hard

**Fields:**
- Project Type (dropdown, triggers dependent field)
- Framework (searchable dropdown, appears based on project type)
- Required Features (multi-select, minimum 3, hidden in collapsible)
- Project Budget (number input, hidden in collapsible)
- Team Size (dropdown, hidden in collapsible)
- Project Manager Name (text, hidden in collapsible)
- Vendor Selection (from complex searchable table)
- Start Date (YYYY-MM-DD format)
- End Date (YYYY-MM-DD format)
- Agreement Checkbox

**Skills Tested:**
- Conditional/dependent fields
- Multiple collapsible sections
- Complex table search and selection
- Multiple popup modals
- Checkbox interaction
- All previous skills combined

**Challenges:**
- Framework field only appears after selecting project type
- Multiple collapsible sections must be expanded
- Two random popup modals appear at different times
- Complex vendor table with multiple columns

---

### Success Page
Displays a summary of all submitted data across all 4 pages, showing:
- Complete field-by-field breakdown
- Statistics (pages completed, fields filled)
- Feature checklist
- Option to restart or clear data

## 🧪 Testing Your Agent

### Recommended Test Flow

1. **Start with Page 1** to ensure basic form filling works
2. **Progress through each page** sequentially
3. **Monitor for:**
   - Proper field filling
   - Format validation handling
   - Modal detection and closing
   - Collapsible section expansion
   - Table/dropdown searching
   - Multi-select interactions
   - Form validation responses

### Success Criteria

An agent successfully completes the challenge if it:
- ✅ Fills all required fields correctly
- ✅ Handles format-specific inputs (dates, phone, zip)
- ✅ Closes random popup modals when they appear
- ✅ Expands collapsible sections to access hidden fields
- ✅ Searches and selects items from tables
- ✅ Interacts with searchable dropdowns
- ✅ Handles dependent/conditional fields
- ✅ Reaches the success page with all data submitted

## 📁 Project Structure

```
cua_challenge/
├── Dockerfile              # Docker configuration for nginx
├── README.md              # This file
├── index.html             # Page 1 (Easy)
├── page2.html             # Page 2 (Medium)
├── page3.html             # Page 3 (Hard)
├── page4.html             # Page 4 (Very Hard)
├── success.html           # Success/Summary page
└── shared.js              # Shared JavaScript utilities
```

## 🔧 Configuration

### Changing the Port

**Docker:**
```bash
docker run -d -p 3000:80 --name cua-challenge cua-challenge
```

**Python:**
```bash
python3 -m http.server 3000
```

**Node:**
```bash
http-server -p 3000
```

## 📊 Monitoring Agent Performance

The application stores all form data in `sessionStorage`, which allows you to:

1. Track progress across pages
2. Review submitted data on the success page
3. Debug agent behavior by checking browser console

To inspect stored data, use browser DevTools:
```javascript
// In browser console
sessionStorage.getItem('page1Data')
sessionStorage.getItem('page2Data')
sessionStorage.getItem('page3Data')
sessionStorage.getItem('page4Data')
```

## 🎨 Customization

### Adding New Fields

Edit the respective HTML file and add your form field. The validation is handled by `shared.js` and inline JavaScript.

### Adjusting Difficulty

- **Modal Timing:** Edit the delay in `shared.js` (`showRandomModal` function)
- **Validation Rules:** Modify regex patterns in `shared.js`
- **Required Fields:** Add/remove `required` attribute from inputs

### Styling

The application uses Tailwind CSS via CDN. Modify classes directly in HTML files to change appearance.

## 🐛 Troubleshooting

### Docker Issues

**Container won't start:**
```bash
docker logs cua-challenge
```

**Port already in use:**
```bash
# Use a different port
docker run -d -p 8081:80 --name cua-challenge cua-challenge
```

### Browser Issues

**Forms not submitting:**
- Check browser console for JavaScript errors
- Ensure all required fields are filled
- Verify format validations are met

**Modals not appearing:**
- Wait 3-8 seconds after page load
- Check if modal is hidden (may need to be closed)

## 📝 Notes for Agent Developers

### Key Considerations

1. **Timing:** Random modals appear after 3-8 second delays
2. **Hidden Elements:** Some fields are initially hidden (`display: none`)
3. **Format Validation:** Strict format requirements (dates, phones, zips)
4. **Dependencies:** Some fields depend on others (e.g., framework depends on project type)
5. **Multi-step:** Must navigate through all 4 pages sequentially

### Common Pitfalls

- ❌ Not waiting for modals to appear
- ❌ Missing hidden fields in collapsible sections
- ❌ Incorrect date/phone/zip formats
- ❌ Not selecting enough items in multi-selects
- ❌ Clicking "Next" before all required fields are filled

## 📄 License

This is a testing tool for Computer Use Agents. Feel free to modify and use as needed.

## 🤝 Contributing

This is a local testing tool. Modify as needed for your specific testing requirements.

---

**Built with ❤️ for testing Computer Use Agents**
