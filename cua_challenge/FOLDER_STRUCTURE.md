# CUA Challenge - Folder Structure

## Directory Layout

```
cua_challenge/
├── html/                       # HTML pages
│   ├── index.html             # Page 1 (Easy)
│   ├── page2.html             # Page 2 (Medium)
│   ├── page3.html             # Page 3 (Hard)
│   ├── page4.html             # Page 4 (Very Hard)
│   └── success.html           # Success/completion page
│
├── js/                         # JavaScript files
│   └── shared.js              # Shared utilities and functions
│
├── test_data/                  # Test data JSON files
│   ├── test_data_1.json       # Scenario 1 (Hard)
│   ├── test_data_2.json       # Scenario 2 (Medium)
│   ├── test_data_3.json       # Scenario 3 (Easy)
│   └── TEST_DATA_README.md    # Test data documentation
│
├── Dockerfile                  # Docker build configuration
├── .dockerignore              # Files to exclude from Docker build
├── README.md                  # Main documentation
├── TEST_SCENARIOS_QUICK_REF.md # Quick reference guide
├── example_agent_usage.ex     # Elixir usage examples
└── start.sh                   # Quick start script

```

## Docker Image Structure

When built, files are organized in the nginx container as:

```
/usr/share/nginx/html/
├── index.html
├── page2.html
├── page3.html
├── page4.html
├── success.html
├── js/
│   └── shared.js
└── test_data/
    ├── test_data_1.json
    ├── test_data_2.json
    └── test_data_3.json
```

## Access URLs

Once the container is running on `http://localhost:8080`:

### Challenge Pages
- **Homepage (Page 1):** `http://localhost:8080/` or `http://localhost:8080/index.html`
- **Page 2:** `http://localhost:8080/page2.html`
- **Page 3:** `http://localhost:8080/page3.html`
- **Page 4:** `http://localhost:8080/page4.html`
- **Success:** `http://localhost:8080/success.html`

### JavaScript
- **Shared utilities:** `http://localhost:8080/js/shared.js`

### Test Data
- **Scenario 1 (Hard):** `http://localhost:8080/test_data/test_data_1.json`
- **Scenario 2 (Medium):** `http://localhost:8080/test_data/test_data_2.json`
- **Scenario 3 (Easy):** `http://localhost:8080/test_data/test_data_3.json`

## Files Excluded from Docker Image

The `.dockerignore` file excludes these patterns:

```
*.md              # All markdown files
README.md         # Main readme
TEST_*.md         # Test documentation
*.ex              # Elixir example files
start.sh          # Shell scripts
.git              # Git repository
.gitignore        # Git ignore file
```

These files are for development/documentation and not needed in the production container.

## Build Process

The `Dockerfile` copies files in this order:

1. **HTML files** from `html/` → `/usr/share/nginx/html/`
2. **JavaScript** from `js/` → `/usr/share/nginx/html/js/`
3. **Test data** from `test_data/` → `/usr/share/nginx/html/test_data/`

## Benefits of This Structure

### ✅ Organization
- Clear separation of concerns (HTML, JS, Data)
- Easier to navigate and maintain
- Logical grouping of related files

### ✅ Scalability
- Easy to add more pages to `html/`
- Easy to add more scripts to `js/`
- Easy to add more test scenarios to `test_data/`

### ✅ Docker Optimization
- `.dockerignore` reduces image size
- Only production files included
- Documentation stays in source, not in image

### ✅ URL Structure
- Clean, predictable URLs
- RESTful-like organization
- Easy for agents to construct URLs

## Agent Instructions

When instructing your agent to navigate:

### Navigate to challenge:
```
Go to http://cua-challenge/index.html
```

### Load test data:
```javascript
// Fetch test data from container
fetch('http://cua-challenge/test_data/test_data_1.json')
  .then(r => r.json())
  .then(data => console.log(data))
```

### Or from Elixir:
```elixir
# If running from host machine
{:ok, response} = HTTPoison.get("http://localhost:8080/test_data/test_data_1.json")
test_data = Jason.decode!(response.body)

# If running from within Docker network
{:ok, response} = HTTPoison.get("http://cua-challenge/test_data/test_data_1.json")
test_data = Jason.decode!(response.body)
```

## Development Workflow

1. **Edit HTML:** Modify files in `html/`
2. **Edit JS:** Modify files in `js/`
3. **Edit Test Data:** Modify files in `test_data/`
4. **Rebuild:** Run `docker-compose build cua-challenge`
5. **Test:** Run `docker-compose up -d cua-challenge`
6. **Access:** Visit `http://localhost:8080`

## Troubleshooting

### Issue: JavaScript not loading
**Check:** Verify HTML files reference `js/shared.js` (not `shared.js`)

### Issue: Test data 404
**Check:** URL should be `http://localhost:8080/test_data/test_data_1.json`

### Issue: Docker build fails
**Check:**
- All files exist in their respective directories
- No typos in file names
- Run `docker-compose build --no-cache cua-challenge`

---

**Last Updated:** 2026-01-15
**Structure Version:** 2.0
