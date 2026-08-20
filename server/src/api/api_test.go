package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"server/src/db"
	"server/src/models"
	"testing"

	"gorm.io/gorm"
)

func setupTestRouter(t *testing.T) (*http.ServeMux, *gorm.DB) {
	// Init DB in memory
	dbConn, err := db.InitDB(":memory:")
	if err != nil {
		t.Fatalf("Failed to initialize test database: %v", err)
	}

	// Seed educational data
	if err := db.SeedEducationalData(dbConn); err != nil {
		t.Fatalf("Failed to seed educational data: %v", err)
	}

	mux := http.NewServeMux()
	RegisterRoutes(mux, dbConn)

	return mux, dbConn
}

func TestGetWebsites(t *testing.T) {
	mux, _ := setupTestRouter(t)

	req := httptest.NewRequest("GET", "/api/websites", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", rec.Code)
	}

	var sites []models.Website
	if err := json.NewDecoder(rec.Body).Decode(&sites); err != nil {
		t.Fatalf("Failed to decode websites: %v", err)
	}

	// We expect 4 seeded websites
	if len(sites) != 4 {
		t.Errorf("Expected 4 seeded websites, got %d", len(sites))
	}
}

func TestCreateWebsite(t *testing.T) {
	mux, _ := setupTestRouter(t)

	payload := CreateWebsiteReq{
		Domain: "newedu.org",
		Name:   "New Education Initiative",
	}
	body, _ := json.Marshal(payload)

	req := httptest.NewRequest("POST", "/api/websites", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Errorf("Expected status 201, got %d", rec.Code)
	}

	var site models.Website
	if err := json.NewDecoder(rec.Body).Decode(&site); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}

	if site.Domain != "newedu.org" || site.Name != "New Education Initiative" {
		t.Errorf("Website fields mismatch: %+v", site)
	}
}

func TestCreateWebpage(t *testing.T) {
	mux, _ := setupTestRouter(t)

	// Post a page to site 1 (MIT OpenCourseWare)
	payload := CreateWebpageReq{
		WebsiteID:   1,
		URL:         "https://ocw.mit.edu/courses/new-physics-course",
		Title:       "Advanced String Theory",
		Description: "Graduate-level physics.",
		Content:     "We explore the basics of string theory and quantum gravity in 11 dimensions.",
	}
	body, _ := json.Marshal(payload)

	req := httptest.NewRequest("POST", "/api/webpages", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Errorf("Expected status 201, got %d. Body: %s", rec.Code, rec.Body.String())
	}

	var page models.Webpage
	if err := json.NewDecoder(rec.Body).Decode(&page); err != nil {
		t.Fatalf("Failed to decode webpage response: %v", err)
	}

	if page.Title != "Advanced String Theory" || page.Hash == "" {
		t.Errorf("Webpage fields mismatch or hash not generated: %+v", page)
	}
}

func TestSearchWebpagesAPI(t *testing.T) {
	mux, _ := setupTestRouter(t)

	// Search for seeded physics pages
	req := httptest.NewRequest("GET", "/api/search?q=physics", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", rec.Code)
	}

	var results []db.SearchResult
	if err := json.NewDecoder(rec.Body).Decode(&results); err != nil {
		t.Fatalf("Failed to decode search results: %v", err)
	}

	// Should match MIT Physics and Wikipedia History of Science / Solar System
	if len(results) == 0 {
		t.Error("Expected to find at least one match for query 'physics'")
	}

	for _, res := range results {
		if res.Snippet == "" {
			t.Error("Expected matching search result to contain snippet highlighting")
		}
	}
}

func TestDeleteWebsiteAPI(t *testing.T) {
	mux, _ := setupTestRouter(t)

	// Delete site 1 (MIT OpenCourseWare)
	req := httptest.NewRequest("DELETE", "/api/websites/1", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", rec.Code)
	}

	// Verify that site 1 is no longer in website listing
	reqList := httptest.NewRequest("GET", "/api/websites", nil)
	recList := httptest.NewRecorder()
	mux.ServeHTTP(recList, reqList)

	var sites []models.Website
	json.NewDecoder(recList.Body).Decode(&sites)

	for _, s := range sites {
		if s.ID == 1 {
			t.Error("Expected website with ID 1 to be deleted")
		}
	}
}
