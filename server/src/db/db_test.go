package db

import (
	"os"
	"server/src/models"
	"testing"

	"gorm.io/gorm"
)

// setupTestDB creates an in-memory database for testing
func setupTestDB(t *testing.T) *gorm.DB {
	db, err := InitDB(":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize test database: %v", err)
	}
	return db
}

func TestInitDB(t *testing.T) {
	db := setupTestDB(t)
	if db == nil {
		t.Fatal("Database connection should not be nil")
	}

	// Verify tables exist
	if !db.Migrator().HasTable(&models.Website{}) {
		t.Error("Table websites was not created")
	}
	if !db.Migrator().HasTable(&models.Webpage{}) {
		t.Error("Table webpages was not created")
	}

	// Verify virtual table exists by running a simple query on it
	var count int64
	err := db.Table("webpages_fts").Count(&count).Error
	if err != nil {
		t.Errorf("webpages_fts virtual table does not exist or error querying it: %v", err)
	}
}

func TestWebsiteCRUD(t *testing.T) {
	db := setupTestDB(t)

	site := &models.Website{
		Domain: "example.com",
		Name:   "Example Site",
	}

	// Create
	err := CreateOrUpdateWebsite(db, site)
	if err != nil {
		t.Fatalf("Failed to create website: %v", err)
	}
	if site.ID == 0 {
		t.Error("Expected site ID to be populated")
	}

	// Read
	retrieved, err := GetWebsiteByID(db, site.ID)
	if err != nil {
		t.Fatalf("Failed to retrieve website: %v", err)
	}
	if retrieved.Domain != "example.com" || retrieved.Name != "Example Site" {
		t.Errorf("Retrieved website data mismatch: %+v", retrieved)
	}

	// Update (changing name)
	site.Name = "Example Updated"
	err = CreateOrUpdateWebsite(db, site)
	if err != nil {
		t.Fatalf("Failed to update website: %v", err)
	}

	retrievedUpdated, err := GetWebsiteByID(db, site.ID)
	if err != nil {
		t.Fatalf("Failed to retrieve updated website: %v", err)
	}
	if retrievedUpdated.Name != "Example Updated" {
		t.Errorf("Expected name to be 'Example Updated', got %s", retrievedUpdated.Name)
	}

	// Delete
	err = DeleteWebsite(db, site.ID)
	if err != nil {
		t.Fatalf("Failed to delete website: %v", err)
	}

	_, err = GetWebsiteByID(db, site.ID)
	if err == nil {
		t.Error("Expected error (not found) when retrieving deleted website")
	}
}

func TestWebpageCRUDAndHash(t *testing.T) {
	db := setupTestDB(t)

	// Create website first
	site := &models.Website{Domain: "blog.example.com", Name: "Blog"}
	if err := CreateOrUpdateWebsite(db, site); err != nil {
		t.Fatalf("Failed to create site: %v", err)
	}

	page := &models.Webpage{
		WebsiteID:   site.ID,
		URL:         "https://blog.example.com/first-post",
		Title:       "First Post",
		Description: "The very first post of my blog.",
		Content:     "This is some content to search. Go is awesome and SQLite is fast.",
	}

	// Create webpage
	err := CreateOrUpdateWebpage(db, page)
	if err != nil {
		t.Fatalf("Failed to create webpage: %v", err)
	}
	if page.ID == 0 {
		t.Error("Expected page ID to be populated")
	}

	// Verify hashing was done automatically
	expectedHash := ComputeHash(page.Content)
	if page.Hash != expectedHash {
		t.Errorf("Expected hash %s, got %s", expectedHash, page.Hash)
	}

	// Verify LastIndexed was populated
	if page.LastIndexed.IsZero() {
		t.Error("Expected LastIndexed to be set")
	}

	// Retrieve
	retrieved, err := GetWebpageByID(db, page.ID)
	if err != nil {
		t.Fatalf("Failed to retrieve webpage: %v", err)
	}
	if retrieved.Title != "First Post" || retrieved.Hash != expectedHash {
		t.Errorf("Retrieved webpage mismatch: %+v", retrieved)
	}

	// Get webpages by website
	pages, err := GetWebpagesByWebsite(db, site.ID)
	if err != nil {
		t.Fatalf("Failed to get webpages: %v", err)
	}
	if len(pages) != 1 || pages[0].ID != page.ID {
		t.Errorf("Expected 1 page with ID %d, got %d pages", page.ID, len(pages))
	}
}

func TestWebsiteCascadingDelete(t *testing.T) {
	db := setupTestDB(t)

	// Create website
	site := &models.Website{Domain: "delete-me.com", Name: "Temporary"}
	if err := CreateOrUpdateWebsite(db, site); err != nil {
		t.Fatalf("Failed to create site: %v", err)
	}

	// Create two webpages
	p1 := &models.Webpage{WebsiteID: site.ID, URL: "https://delete-me.com/1", Title: "Page 1", Content: "Content 1"}
	p2 := &models.Webpage{WebsiteID: site.ID, URL: "https://delete-me.com/2", Title: "Page 2", Content: "Content 2"}
	if err := CreateOrUpdateWebpage(db, p1); err != nil {
		t.Fatalf("Failed to create webpage 1: %v", err)
	}
	if err := CreateOrUpdateWebpage(db, p2); err != nil {
		t.Fatalf("Failed to create webpage 2: %v", err)
	}

	// Confirm pages exist
	pages, _ := GetWebpagesByWebsite(db, site.ID)
	if len(pages) != 2 {
		t.Fatalf("Expected 2 pages, got %d", len(pages))
	}

	// Delete Website
	if err := DeleteWebsite(db, site.ID); err != nil {
		t.Fatalf("Failed to delete website: %v", err)
	}

	// Verify webpages are deleted by cascade
	pagesAfterDelete, err := GetWebpagesByWebsite(db, site.ID)
	if err != nil {
		t.Fatalf("Failed to query webpages: %v", err)
	}
	if len(pagesAfterDelete) != 0 {
		t.Errorf("Expected 0 webpages after cascading delete, found %d", len(pagesAfterDelete))
	}

	// Verify webpages are also removed from FTS5 table
	var ftsCount int64
	err = db.Table("webpages_fts").Where("webpage_id IN (?, ?)", p1.ID, p2.ID).Count(&ftsCount).Error
	if err != nil {
		t.Fatalf("Failed to query webpages_fts: %v", err)
	}
	if ftsCount != 0 {
		t.Errorf("Expected FTS entries to be cascading-deleted, found %d", ftsCount)
	}
}

func TestSearchFTS5(t *testing.T) {
	db := setupTestDB(t)

	site := &models.Website{Domain: "search.com", Name: "Search Test"}
	if err := CreateOrUpdateWebsite(db, site); err != nil {
		t.Fatalf("Failed to create site: %v", err)
	}

	// Seed documents with specific keywords
	p1 := &models.Webpage{
		WebsiteID:   site.ID,
		URL:         "https://search.com/rust",
		Title:       "Systems Programming",
		Description: "Learning rust language.",
		Content:     "Rust is a systems programming language focused on safety, speed, and concurrency.",
	}
	p2 := &models.Webpage{
		WebsiteID:   site.ID,
		URL:         "https://search.com/go",
		Title:       "Concurrent Programming",
		Description: "Learning go language.",
		Content:     "Go is an open source programming language that makes it easy to build simple, reliable, and efficient software. Go has concurrency built-in.",
	}
	p3 := &models.Webpage{
		WebsiteID:   site.ID,
		URL:         "https://search.com/sqlite",
		Title:       "Database Storage",
		Description: "Learning databases.",
		Content:     "SQLite is a C-language library that implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine.",
	}

	for _, p := range []*models.Webpage{p1, p2, p3} {
		if err := CreateOrUpdateWebpage(db, p); err != nil {
			t.Fatalf("Failed to seed webpage %s: %v", p.URL, err)
		}
	}

	// Allow triggers to commit to in-memory database
	// Search for "programming" (should match p1 and p2)
	results, err := SearchWebpages(db, "programming")
	if err != nil {
		t.Fatalf("Search failed: %v", err)
	}
	if len(results) != 2 {
		t.Errorf("Expected 2 search results for 'programming', got %d", len(results))
	}

	// Verify highlighting and snippets
	foundGo := false
	foundRust := false
	for _, res := range results {
		if res.URL == "https://search.com/go" {
			foundGo = true
			if res.Snippet == "" {
				t.Error("Expected non-empty snippet for Go result")
			}
			// Snippet should contain highlight tags
			if !containsHighlight(res.Snippet, "programming") {
				t.Errorf("Expected snippet to contain highlighted 'programming', got: %s", res.Snippet)
			}
		}
		if res.URL == "https://search.com/rust" {
			foundRust = true
			if !containsHighlight(res.Snippet, "programming") {
				t.Errorf("Expected snippet to contain highlighted 'programming', got: %s", res.Snippet)
			}
		}
	}
	if !foundGo || !foundRust {
		t.Error("Did not find both Go and Rust pages in search results for 'programming'")
	}

	// Search for "efficient database" (should match p2 and p3)
	results2, err := SearchWebpages(db, "efficient OR database")
	if err != nil {
		t.Fatalf("Search failed: %v", err)
	}
	if len(results2) != 2 {
		t.Errorf("Expected 2 search results for 'efficient OR database', got %d", len(results2))
	}

	// Test Update reflecting in Search Results
	p3.Content = "SQLite is a C-language library that implements a small, fast, self-contained, high-reliability, full-featured database. Postgres is also cool but SQLite is embedded."
	if err := CreateOrUpdateWebpage(db, p3); err != nil {
		t.Fatalf("Failed to update p3: %v", err)
	}

	// Search for "Postgres" (should now match p3)
	results3, err := SearchWebpages(db, "Postgres")
	if err != nil {
		t.Fatalf("Search failed: %v", err)
	}
	if len(results3) != 1 || results3[0].URL != p3.URL {
		t.Errorf("Expected 1 result matching updated content for 'Postgres', got %d results", len(results3))
	}
}

// containsHighlight checks if the snippet contains the word wrapped in <mark>...</mark>
func containsHighlight(snippet, word string) bool {
	// Simple check: looking for <mark>word</mark> case insensitively
	// Since the snippet could be e.g. <mark>programming</mark> or <mark>Programming</mark>
	// we check for "<mark>" and "</mark>".
	// Let's do a basic check
	var lowerSnippet = make([]byte, len(snippet))
	for i, c := range snippet {
		if c >= 'A' && c <= 'Z' {
			lowerSnippet[i] = byte(c + 32)
		} else {
			lowerSnippet[i] = byte(c)
		}
	}
	s := string(lowerSnippet)
	return containsSubstring(s, "<mark>") && containsSubstring(s, "</mark>")
}

func containsSubstring(s, sub string) bool {
	if len(sub) == 0 {
		return true
	}
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}

// TestMain ensures tests can run cleanly
func TestMain(m *testing.M) {
	os.Exit(m.Run())
}
