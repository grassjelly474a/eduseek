package db

import (
	"fmt"
	"server/src/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// InitDB initializes the SQLite database connection, runs migrations, and configures FTS5.
func InitDB(dbPath string) (*gorm.DB, error) {
	// Open sqlite using GORM, enabling foreign key constraints via the query string
	dsn := fmt.Sprintf("%s?_pragma=foreign_keys(1)", dbPath)
	db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Enable foreign key constraints explicitly
	if err := db.Exec("PRAGMA foreign_keys = ON;").Error; err != nil {
		return nil, fmt.Errorf("failed to enable foreign key constraints: %w", err)
	}

	// Auto migrate standard models
	err = db.AutoMigrate(&models.Website{}, &models.Webpage{})
	if err != nil {
		return nil, fmt.Errorf("failed to migrate models: %w", err)
	}

	// Setup FTS5 virtual table and triggers
	if err := setupFTS5(db); err != nil {
		return nil, fmt.Errorf("failed to setup FTS5: %w", err)
	}

	return db, nil
}

// setupFTS5 sets up the FTS5 virtual table and synchronization triggers.
func setupFTS5(db *gorm.DB) error {
	// Create the FTS5 virtual table
	createFTSTableSQL := `
	CREATE VIRTUAL TABLE IF NOT EXISTS webpages_fts USING fts5(
		webpage_id UNINDEXED,
		title,
		description,
		content
	);`
	if err := db.Exec(createFTSTableSQL).Error; err != nil {
		return fmt.Errorf("failed to create FTS5 virtual table: %w", err)
	}

	// Create insert trigger to copy new webpages into FTS5
	insertTriggerSQL := `
	CREATE TRIGGER IF NOT EXISTS webpages_after_insert AFTER INSERT ON webpages BEGIN
		INSERT INTO webpages_fts(webpage_id, title, description, content)
		VALUES (new.id, new.title, new.description, new.content);
	END;`
	if err := db.Exec(insertTriggerSQL).Error; err != nil {
		return fmt.Errorf("failed to create FTS5 insert trigger: %w", err)
	}

	// Create update trigger to keep FTS5 in sync when a webpage changes
	updateTriggerSQL := `
	CREATE TRIGGER IF NOT EXISTS webpages_after_update AFTER UPDATE ON webpages BEGIN
		UPDATE webpages_fts SET
			title = new.title,
			description = new.description,
			content = new.content
		WHERE webpage_id = old.id;
	END;`
	if err := db.Exec(updateTriggerSQL).Error; err != nil {
		return fmt.Errorf("failed to create FTS5 update trigger: %w", err)
	}

	// Create delete trigger to remove webpages from FTS5
	deleteTriggerSQL := `
	CREATE TRIGGER IF NOT EXISTS webpages_after_delete AFTER DELETE ON webpages BEGIN
		DELETE FROM webpages_fts WHERE webpage_id = old.id;
	END;`
	if err := db.Exec(deleteTriggerSQL).Error; err != nil {
		return fmt.Errorf("failed to create FTS5 delete trigger: %w", err)
	}

	return nil
}
