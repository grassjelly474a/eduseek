package db

import (
	"fmt"
	"server/src/models"
	"time"

	"gorm.io/gorm"
)

// SeedEducationalData populates the database with a small, curated set of educational sites and pages
// if no websites exist in the database yet.
func SeedEducationalData(db *gorm.DB) error {
	var count int64
	if err := db.Model(&models.Website{}).Count(&count).Error; err != nil {
		return fmt.Errorf("failed to count existing websites: %w", err)
	}

	if count > 0 {
		// Data already exists, skip seeding
		return nil
	}

	// Define curated websites
	sites := []models.Website{
		{
			Domain: "ocw.mit.edu",
			Name:   "MIT OpenCourseWare",
		},
		{
			Domain: "khanacademy.org",
			Name:   "Khan Academy",
		},
		{
			Domain: "en.wikipedia.org",
			Name:   "Wikipedia (Educational)",
		},
		{
			Domain: "online.stanford.edu",
			Name:   "Stanford Online",
		},
	}

	// Create websites
	for i := range sites {
		if err := CreateOrUpdateWebsite(db, &sites[i]); err != nil {
			return fmt.Errorf("failed to seed website %s: %w", sites[i].Domain, err)
		}
	}

	// Define webpages for each website
	pages := []models.Webpage{
		// MIT OpenCourseWare
		{
			WebsiteID:   sites[0].ID,
			URL:         "https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/",
			Title:       "MIT Electrical Engineering & Computer Science",
			Description: "Free lecture notes, exams, and videos for undergraduate and graduate courses in EECS.",
			Content:     "Introduction to Computer Science and Programming, algorithms, machine learning, circuits, signals, systems, computer systems engineering, computer graphics, and software engineering. Designed for beginner to advanced learners.",
		},
		{
			WebsiteID:   sites[0].ID,
			URL:         "https://ocw.mit.edu/courses/physics/",
			Title:       "MIT Physics Courses",
			Description: "Study classical mechanics, quantum physics, electromagnetism, and relativity with MIT materials.",
			Content:     "Undergraduate and graduate physics curriculum including statistical physics, astrophysics, quantum mechanics, electromagnetism, optics, thermodynamics, and string theory. Exercises and lecture transcripts included.",
		},
		{
			WebsiteID:   sites[0].ID,
			URL:         "https://ocw.mit.edu/courses/mathematics/",
			Title:       "MIT Mathematics Courses",
			Description: "Free courses in calculus, linear algebra, differential equations, and probability.",
			Content:     "Learn single variable calculus, multivariable calculus, probability and statistics, abstract algebra, number theory, topology, and complex analysis. Study core math concepts using MIT lecture videos and problem sets.",
		},

		// Khan Academy
		{
			WebsiteID:   sites[1].ID,
			URL:         "https://www.khanacademy.org/math/algebra",
			Title:       "Khan Academy Algebra",
			Description: "Learn algebra step-by-step with interactive practices, quizzes, and instructional videos.",
			Content:     "Explore linear equations, quadratic functions, polynomials, systems of equations, matrix operations, graphs, and sequences. Suitable for high school students and college prep.",
		},
		{
			WebsiteID:   sites[1].ID,
			URL:         "https://www.khanacademy.org/science/biology",
			Title:       "Khan Academy Biology",
			Description: "Learn high school and AP biology topics, from cells and genetics to ecology and evolution.",
			Content:     "Covers photosynthesis, cell division, DNA structure, RNA translation, natural selection, human anatomy, ecology, and ecosystems. Interactive articles and diagrams help you master foundational life sciences.",
		},
		{
			WebsiteID:   sites[1].ID,
			URL:         "https://www.khanacademy.org/humanities/art-history",
			Title:       "Khan Academy Art History",
			Description: "Discover how art has shaped culture across historical epochs, from ancient Egypt to contemporary art.",
			Content:     "Explore prehistoric art, Greek and Roman sculpture, Renaissance painting, Baroque architecture, Impressionism, Modernism, and global art trends. Analyzes context, materials, style, and meaning.",
		},

		// Wikipedia
		{
			WebsiteID:   sites[2].ID,
			URL:         "https://en.wikipedia.org/wiki/History_of_science",
			Title:       "History of Science - Wikipedia",
			Description: "The study of the historical development of science, technology, and natural philosophy.",
			Content:     "Details ancient science in Egypt and Mesopotamia, Greek natural philosophy, Islamic Golden Age discoveries, Scientific Revolution, and modern quantum physics and biotechnology advances.",
		},
		{
			WebsiteID:   sites[2].ID,
			URL:         "https://en.wikipedia.org/wiki/Solar_System",
			Title:       "Solar System - Wikipedia",
			Description: "Information about the gravitationally bound system of the Sun and the objects that orbit it.",
			Content:     "Details the terrestrial inner planets (Mercury, Venus, Earth, Mars), the outer gas giants (Jupiter, Saturn), ice giants (Uranus, Neptune), asteroid belt, Kuiper belt, comets, and the Sun's magnetic field.",
		},
		{
			WebsiteID:   sites[2].ID,
			URL:         "https://en.wikipedia.org/wiki/Periodic_table",
			Title:       "Periodic Table of Elements - Wikipedia",
			Description: "A tabular display of the chemical elements, organized by atomic number and electron configuration.",
			Content:     "Shows groups, periods, blocks, chemical properties, metals, metalloids, nonmetals, halogens, noble gases, lanthanides, actinides, and historical contributions by Mendeleev.",
		},

		// Stanford Online
		{
			WebsiteID:   sites[3].ID,
			URL:         "https://online.stanford.edu/courses/cs229-machine-learning",
			Title:       "Stanford Online: Machine Learning",
			Description: "Stanford University's premier course on machine learning and artificial intelligence.",
			Content:     "Topics include supervised learning (linear regression, logistic regression, SVMs, neural networks), unsupervised learning (clustering, dimensionality reduction), and reinforcement learning. Heavy focus on math and practical application.",
		},
		{
			WebsiteID:   sites[3].ID,
			URL:         "https://online.stanford.edu/courses/so-cryptography-i",
			Title:       "Stanford Online: Cryptography I",
			Description: "An introduction to cryptography and security for computer systems.",
			Content:     "Learn symmetric encryption, message authentication codes (MACs), public-key cryptography, RSA, Diffie-Hellman key exchange, digital signatures, and secure network protocols like TLS/HTTPS. Focuses on mathematical basics and common exploits.",
		},
	}

	// Create webpages
	for i := range pages {
		pages[i].LastIndexed = time.Now()
		if err := CreateOrUpdateWebpage(db, &pages[i]); err != nil {
			return fmt.Errorf("failed to seed webpage %s: %w", pages[i].URL, err)
		}
	}

	return nil
}
