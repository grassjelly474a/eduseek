package db

import (
	"crypto/sha256"
	"encoding/hex"
	"server/src/models"
	"time"

	"gorm.io/gorm"
)

// CreateOrUpdateWebsite creates a website or updates it if the domain already exists.
func CreateOrUpdateWebsite(db *gorm.DB, site *models.Website) error {
	var existing models.Website
	err := db.Where("domain = ?", site.Domain).First(&existing).Error
	if err == nil {
		// Update existing record
		site.ID = existing.ID
		site.CreatedAt = existing.CreatedAt
		return db.Save(site).Error
	} else if err != gorm.ErrRecordNotFound {
		return err
	}
	// Create new record
	return db.Create(site).Error
}

// GetWebsiteByID retrieves a website by its ID.
func GetWebsiteByID(db *gorm.DB, id uint) (*models.Website, error) {
	var site models.Website
	err := db.First(&site, id).Error
	if err != nil {
		return nil, err
	}
	return &site, nil
}

// DeleteWebsite deletes a website by ID. Cascading delete deletes all related webpages.
func DeleteWebsite(db *gorm.DB, id uint) error {
	return db.Delete(&models.Website{}, id).Error
}

// CreateOrUpdateWebpage creates a webpage or updates it if the URL already exists.
// It automatically computes the SHA-256 hash of the page content and updates LastIndexed.
func CreateOrUpdateWebpage(db *gorm.DB, page *models.Webpage) error {
	// Automatically hash content if empty or compute it to guarantee consistency
	if page.Content != "" {
		page.Hash = ComputeHash(page.Content)
	}
	if page.LastIndexed.IsZero() {
		page.LastIndexed = time.Now()
	}

	var existing models.Webpage
	err := db.Where("url = ?", page.URL).First(&existing).Error
	if err == nil {
		// Update existing record
		page.ID = existing.ID
		page.CreatedAt = existing.CreatedAt
		if page.WebsiteID == 0 {
			page.WebsiteID = existing.WebsiteID
		}
		return db.Save(page).Error
	} else if err != gorm.ErrRecordNotFound {
		return err
	}
	// Create new record
	return db.Create(page).Error
}

// GetWebpageByID retrieves a webpage by its ID.
func GetWebpageByID(db *gorm.DB, id uint) (*models.Webpage, error) {
	var page models.Webpage
	err := db.First(&page, id).Error
	if err != nil {
		return nil, err
	}
	return &page, nil
}

// GetWebpagesByWebsite retrieves all webpages associated with a website ID.
func GetWebpagesByWebsite(db *gorm.DB, websiteID uint) ([]models.Webpage, error) {
	var pages []models.Webpage
	err := db.Where("website_id = ?", websiteID).Find(&pages).Error
	return pages, err
}

// DeleteWebpage deletes a webpage by ID.
func DeleteWebpage(db *gorm.DB, id uint) error {
	return db.Delete(&models.Webpage{}, id).Error
}

// SearchResult represents a search hit including the webpage data,
// a snippet highlighting the matched term, and the bm25 ranking score.
type SearchResult struct {
	models.Webpage
	Snippet string  `gorm:"column:snippet"`
	Rank    float64 `gorm:"column:rank"`
}

// SearchWebpages searches indexed webpage content using SQLite FTS5.
// The searchPhrase can contain standard FTS5 search queries.
// It returns matching webpages ordered by relevance (BM25 ranking), including HTML snippets highlighting matched words.
func SearchWebpages(db *gorm.DB, searchPhrase string) ([]SearchResult, error) {
	var results []SearchResult
	// We match against the webpages_fts virtual table.
	// Columns in webpages_fts: webpage_id (0), title (1), description (2), content (3)
	// We extract a highlighted snippet from column 3 (content).
	sql := `
	SELECT w.*, snippet(webpages_fts, 3, '<mark>', '</mark>', '...', 32) as snippet, bm25(webpages_fts) as rank
	FROM webpages w
	JOIN webpages_fts ON w.id = webpages_fts.webpage_id
	WHERE webpages_fts MATCH ?
	ORDER BY rank ASC
	`
	err := db.Raw(sql, searchPhrase).Scan(&results).Error
	return results, err
}

// ComputeHash calculates the SHA-256 hash of the input string.
func ComputeHash(input string) string {
	h := sha256.New()
	h.Write([]byte(input))
	return hex.EncodeToString(h.Sum(nil))
}
