package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"cat-calories-server/internal/config"
	"cat-calories-server/internal/database"
	"cat-calories-server/internal/model"
	"cat-calories-server/internal/repository/sqlite"
	"cat-calories-server/internal/usecase"
)

func main() {
	email := flag.String("email", "", "user email")
	password := flag.String("password", "", "user password")
	flag.Parse()

	cfg := config.Load()

	// Remove existing database
	os.Remove(cfg.DatabasePath)

	db, err := database.Open(cfg.DatabasePath)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer db.Close()

	if err := database.Migrate(db); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	// Prompt interactively if flags not provided
	if *email == "" || *password == "" {
		reader := bufio.NewReader(os.Stdin)
		if *email == "" {
			fmt.Print("Email: ")
			line, _ := reader.ReadString('\n')
			*email = strings.TrimSpace(line)
		}
		if *password == "" {
			fmt.Print("Password: ")
			line, _ := reader.ReadString('\n')
			*password = strings.TrimSpace(line)
		}
	}

	userRepo := &sqlite.UserRepo{DB: db}
	profileRepo := &sqlite.ProfileRepo{DB: db}

	authUC := &usecase.AuthUseCase{
		Users:  userRepo,
		Secret: cfg.ServerSecret,
	}

	_, err = authUC.Register(*email, *password, "")
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	// Create a default profile for the user
	user, err := userRepo.FindByEmail(*email)
	if err != nil {
		log.Fatalf("find user: %v", err)
	}

	now := time.Now()
	err = profileRepo.Upsert(user.ID, model.Profile{
		ID:                1,
		UserID:            user.ID,
		Name:              "Default",
		CaloriesLimitGoal: 2000,
		CreatedAt:         now,
		UpdatedAt:         now,
	})
	if err != nil {
		log.Fatalf("create profile: %v", err)
	}

	fmt.Println("Database initialized.")
	fmt.Printf("User: %s\n", *email)
}
