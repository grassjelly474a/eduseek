package main

import (
	"fmt"
	"github.com/joho/godotenv"
	"log"
	"net/http"
	"os"
	"server/src/api"
	"server/src/db"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Failed to load environment file")
	}
	dbFile := os.Getenv("DB_PATH")
	port := os.Getenv("PORT")

	fmt.Println("Initializing SQLite database...")
	database, err := db.InitDB(dbFile)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer func() {
		sqlDB, err := database.DB()
		if err == nil {
			sqlDB.Close()
		}
	}()

	fmt.Println("Database initialized successfully.")

	fmt.Println("Seeding educational websites/indices if necessary...")
	if err := db.SeedEducationalData(database); err != nil {
		log.Fatalf("Failed to seed educational data: %v", err)
	}

	mux := http.NewServeMux()
	api.RegisterRoutes(mux, database)

	fmt.Printf("HTTP Server is starting on port %s...\n", port)

	// Apply CORS middleware
	serverHandler := api.CORS(mux)

	if err := http.ListenAndServe(port, serverHandler); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
