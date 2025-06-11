package main

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"
)

type OnboardRequest struct {
	UserID string `json:"user_id"`
	Name   string `json:"name"`
}

type OnboardResponse struct {
	UserID string `json:"user_id"`
	Status string `json:"status"`
}

var (
	requestCount = make(map[string]int) // Tracks number of requests per user
	mu          sync.Mutex              // Ensures thread safety
)

// Cleanup function to remove "Ready" users after 5 minutes
func cleanupUser(userID string) {
	time.Sleep(5 * time.Minute) // Wait for 5 minutes

	mu.Lock()
	defer mu.Unlock()

	// Double-check before deletion to avoid race conditions
	if requestCount[userID] >= 3 {
		delete(requestCount, userID)
		log.Printf("User %s removed from cache after 5 minutes", userID)
	}
}

func onboardHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	var req OnboardRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	// Increment request count for this user
	requestCount[req.UserID]++

	// Determine response status
	status := "In Progress"
	if requestCount[req.UserID] >= 3 {
		status = "Ready"

		// Start a goroutine to clean up this user after 5 minutes
		go cleanupUser(req.UserID)
	}

	resp := OnboardResponse{
		UserID: req.UserID,
		Status: status,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func main() {
	http.HandleFunc("/onboard", onboardHandler)
	log.Println("Server is running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
