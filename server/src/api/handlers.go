package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"server/src/db"
	"server/src/models"
	"strconv"

	"gorm.io/gorm"
)

// CreateWebsiteReq defines the payload for creating a website
type CreateWebsiteReq struct {
	Domain string `json:"domain"`
	Name   string `json:"name"`
}

// CreateWebpageReq defines the payload for creating a webpage
type CreateWebpageReq struct {
	WebsiteID   uint   `json:"website_id"`
	URL         string `json:"url"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Content     string `json:"content"`
	RawHTML     string `json:"raw_html"`
}

// RegisterRoutes registers all API routes on the provided multiplexer
func RegisterRoutes(mux *http.ServeMux, dbConn *gorm.DB) {
	mux.HandleFunc("GET /api/search", HandleSearch(dbConn))
	mux.HandleFunc("GET /api/websites", HandleWebsites(dbConn))
	mux.HandleFunc("POST /api/websites", HandleWebsites(dbConn))
	mux.HandleFunc("DELETE /api/websites/{id}", HandleWebsiteByID(dbConn))
	mux.HandleFunc("GET /api/websites/{id}/webpages", HandleWebsiteWebpages(dbConn))
	mux.HandleFunc("POST /api/webpages", HandleWebpages(dbConn))
}

// CORS is a middleware that injects necessary CORS headers for requests
func CORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// HandleSearch processes full-text search queries
func HandleSearch(dbConn *gorm.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query().Get("q")
		if q == "" {
			writeError(w, http.StatusBadRequest, "Query parameter 'q' is required")
			return
		}

		results, err := db.SearchWebpages(dbConn, q)
		if err != nil {
			writeError(w, http.StatusBadRequest, fmt.Sprintf("Search error: %v", err))
			return
		}

		writeJSON(w, http.StatusOK, results)
	}
}

// HandleWebsites manages website listings and registration
func HandleWebsites(dbConn *gorm.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			var sites []models.Website
			if err := dbConn.Find(&sites).Error; err != nil {
				writeError(w, http.StatusInternalServerError, err.Error())
				return
			}
			writeJSON(w, http.StatusOK, sites)

		case http.MethodPost:
			var req CreateWebsiteReq
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				writeError(w, http.StatusBadRequest, "Invalid JSON payload")
				return
			}
			if req.Domain == "" || req.Name == "" {
				writeError(w, http.StatusBadRequest, "Fields 'domain' and 'name' are required")
				return
			}

			site := models.Website{
				Domain: req.Domain,
				Name:   req.Name,
			}
			if err := db.CreateOrUpdateWebsite(dbConn, &site); err != nil {
				writeError(w, http.StatusInternalServerError, err.Error())
				return
			}
			writeJSON(w, http.StatusCreated, site)
		}
	}
}

// HandleWebsiteByID handles operations on a specific website
func HandleWebsiteByID(dbConn *gorm.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		idStr := r.PathValue("id")
		id, err := strconv.ParseUint(idStr, 10, 32)
		if err != nil {
			writeError(w, http.StatusBadRequest, "Invalid website ID")
			return
		}

		switch r.Method {
		case http.MethodDelete:
			if err := db.DeleteWebsite(dbConn, uint(id)); err != nil {
				writeError(w, http.StatusInternalServerError, err.Error())
				return
			}
			writeJSON(w, http.StatusOK, map[string]string{"message": "Website and all associated pages deleted"})
		}
	}
}

// HandleWebsiteWebpages lists all pages indexed under a specific website
func HandleWebsiteWebpages(dbConn *gorm.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		idStr := r.PathValue("id")
		id, err := strconv.ParseUint(idStr, 10, 32)
		if err != nil {
			writeError(w, http.StatusBadRequest, "Invalid website ID")
			return
		}

		pages, err := db.GetWebpagesByWebsite(dbConn, uint(id))
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, pages)
	}
}

// HandleWebpages indices new pages
func HandleWebpages(dbConn *gorm.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req CreateWebpageReq
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeError(w, http.StatusBadRequest, "Invalid JSON payload")
			return
		}
		if req.WebsiteID == 0 || req.URL == "" || req.Content == "" {
			writeError(w, http.StatusBadRequest, "Fields 'website_id', 'url', and 'content' are required")
			return
		}

		// Verify website exists
		if _, err := db.GetWebsiteByID(dbConn, req.WebsiteID); err != nil {
			if err == gorm.ErrRecordNotFound {
				writeError(w, http.StatusBadRequest, "Website not found")
			} else {
				writeError(w, http.StatusInternalServerError, err.Error())
			}
			return
		}

		page := models.Webpage{
			WebsiteID:   req.WebsiteID,
			URL:         req.URL,
			Title:       req.Title,
			Description: req.Description,
			Content:     req.Content,
			RawHTML:     req.RawHTML,
		}

		if err := db.CreateOrUpdateWebpage(dbConn, &page); err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
		writeJSON(w, http.StatusCreated, page)
	}
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
