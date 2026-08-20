package models

import (
	"time"
)

// Website represents a site that is indexed
type Website struct {
	ID        uint      `gorm:"primaryKey"`
	CreatedAt time.Time
	UpdatedAt time.Time
	Domain    string    `gorm:"uniqueIndex;not null"`
	Name      string    `gorm:"not null"`
	Webpages  []Webpage `gorm:"constraint:OnDelete:CASCADE;"`
}

// Webpage represents a single indexed page of a website
type Webpage struct {
	ID          uint      `gorm:"primaryKey"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
	WebsiteID   uint      `gorm:"not null;index"`
	Website     Website   `gorm:"constraint:OnDelete:CASCADE;"`
	URL         string    `gorm:"uniqueIndex;not null"`
	Title       string    `gorm:"type:text"`
	Description string    `gorm:"type:text"`
	Content     string    `gorm:"type:text"`       // Cleaned text content of the page for search
	RawHTML     string    `gorm:"type:text"`       // Original HTML content (optional)
	Hash        string    `gorm:"type:varchar(64)"` // Content hash (SHA-256) to check if page needs re-indexing
	LastIndexed time.Time `gorm:"not null"`
}
