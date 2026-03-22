package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"

	"cat-calories-server/internal/config"
	"cat-calories-server/internal/database"
	"cat-calories-server/internal/repository/sqlite"
	"cat-calories-server/internal/usecase"
)

func main() {
	cfg := config.Load()

	db, err := database.Open(cfg.DatabasePath)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer db.Close()

	if err := database.Migrate(db); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Email: ")
	email, _ := reader.ReadString('\n')
	email = strings.TrimSpace(email)

	fmt.Print("Password: ")
	password, _ := reader.ReadString('\n')
	password = strings.TrimSpace(password)

	authUC := &usecase.AuthUseCase{
		Users:  &sqlite.UserRepo{DB: db},
		Secret: cfg.ServerSecret,
	}

	token, err := authUC.Register(email, password, "")
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	fmt.Printf("User created. Token: %s\n", token)
}
