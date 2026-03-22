package database

import "github.com/jmoiron/sqlx"

func Migrate(db *sqlx.DB) error {
	_, err := db.Exec(`
	CREATE TABLE IF NOT EXISTS schema_version (
		version INTEGER NOT NULL
	);

	CREATE TABLE IF NOT EXISTS users (
		id            TEXT PRIMARY KEY,
		email         TEXT NOT NULL,
		name          TEXT NOT NULL DEFAULT '',
		password_hash TEXT NOT NULL DEFAULT '',
		provider      TEXT NOT NULL,
		subject       TEXT NOT NULL,
		created_at    DATETIME NOT NULL DEFAULT (datetime('now')),
		updated_at    DATETIME NOT NULL DEFAULT (datetime('now')),
		UNIQUE(provider, subject)
	);

	CREATE TABLE IF NOT EXISTS profiles (
		id                  INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id             TEXT NOT NULL REFERENCES users(id),
		name                TEXT NOT NULL DEFAULT '',
		waking_time_seconds INTEGER NOT NULL DEFAULT 57600,
		calories_limit_goal INTEGER NOT NULL DEFAULT 2000,
		created_at          DATETIME NOT NULL DEFAULT (datetime('now')),
		updated_at          DATETIME NOT NULL DEFAULT (datetime('now'))
	);

	CREATE TABLE IF NOT EXISTS waking_periods (
		id                        INTEGER PRIMARY KEY AUTOINCREMENT,
		profile_id                INTEGER NOT NULL REFERENCES profiles(id),
		description               TEXT    NOT NULL DEFAULT '',
		calories_value            REAL    NOT NULL DEFAULT 0,
		calories_limit_goal       INTEGER NOT NULL DEFAULT 0,
		expected_waking_time_sec  INTEGER NOT NULL DEFAULT 0,
		started_at                DATETIME NOT NULL,
		ended_at                  DATETIME,
		created_at                DATETIME NOT NULL DEFAULT (datetime('now')),
		updated_at                DATETIME NOT NULL DEFAULT (datetime('now')),
		deleted_at                DATETIME
	);

	CREATE TABLE IF NOT EXISTS calorie_items (
		id               TEXT    PRIMARY KEY,
		profile_id       INTEGER NOT NULL REFERENCES profiles(id),
		waking_period_id INTEGER REFERENCES waking_periods(id),
		product_id       TEXT,
		value            REAL    NOT NULL DEFAULT 0,
		description      TEXT    NOT NULL DEFAULT '',
		sort_order       INTEGER NOT NULL DEFAULT 0,
		weight_grams     REAL,
		protein_grams    REAL,
		fat_grams        REAL,
		carb_grams       REAL,
		eaten_at         DATETIME NOT NULL DEFAULT (datetime('now')),
		created_at       DATETIME NOT NULL DEFAULT (datetime('now')),
		updated_at       DATETIME NOT NULL DEFAULT (datetime('now')),
		deleted_at       DATETIME
	);

	CREATE TABLE IF NOT EXISTS products (
		id                TEXT    PRIMARY KEY,
		profile_id        INTEGER NOT NULL REFERENCES profiles(id),
		category_id       TEXT,
		title             TEXT    NOT NULL DEFAULT '',
		description       TEXT    NOT NULL DEFAULT '',
		barcode           TEXT,
		calories_per_100g REAL,
		proteins_per_100g REAL,
		fats_per_100g     REAL,
		carbs_per_100g    REAL,
		package_weight_g  REAL,
		uses_count        INTEGER NOT NULL DEFAULT 0,
		last_used_at      DATETIME,
		sort_order        INTEGER NOT NULL DEFAULT 0,
		created_at        DATETIME NOT NULL DEFAULT (datetime('now')),
		updated_at        DATETIME NOT NULL DEFAULT (datetime('now')),
		deleted_at        DATETIME
	);

	CREATE TABLE IF NOT EXISTS product_categories (
		id         TEXT    PRIMARY KEY,
		profile_id INTEGER NOT NULL REFERENCES profiles(id),
		name       TEXT    NOT NULL DEFAULT '',
		icon_name  TEXT    NOT NULL DEFAULT '',
		color_hex  TEXT    NOT NULL DEFAULT '',
		sort_order INTEGER NOT NULL DEFAULT 0,
		created_at DATETIME NOT NULL DEFAULT (datetime('now')),
		updated_at DATETIME NOT NULL DEFAULT (datetime('now')),
		deleted_at DATETIME
	);

	CREATE INDEX IF NOT EXISTS idx_calorie_items_profile  ON calorie_items(profile_id);
	CREATE INDEX IF NOT EXISTS idx_calorie_items_eaten_at ON calorie_items(eaten_at);
	CREATE INDEX IF NOT EXISTS idx_products_profile       ON products(profile_id);
	CREATE INDEX IF NOT EXISTS idx_products_category      ON products(category_id);
	`)
	if err != nil {
		return err
	}

	// Run versioned migrations for existing databases
	var version int
	_ = db.Get(&version, "SELECT COALESCE(MAX(version), 0) FROM schema_version")

	if version < 1 {
		// Migration 1: recreate users table with TEXT id if it had INTEGER id
		var idType string
		_ = db.Get(&idType, "SELECT type FROM pragma_table_info('users') WHERE name='id'")
		if idType == "INTEGER" {
			_, err = db.Exec(`
				ALTER TABLE users RENAME TO users_old;
				CREATE TABLE users (
					id            TEXT PRIMARY KEY,
					email         TEXT NOT NULL,
					name          TEXT NOT NULL DEFAULT '',
					password_hash TEXT NOT NULL DEFAULT '',
					provider      TEXT NOT NULL,
					subject       TEXT NOT NULL,
					created_at    DATETIME NOT NULL DEFAULT (datetime('now')),
					updated_at    DATETIME NOT NULL DEFAULT (datetime('now')),
					UNIQUE(provider, subject)
				);
				DROP TABLE users_old;
			`)
			if err != nil {
				return err
			}
		}
		_, err = db.Exec("INSERT INTO schema_version (version) VALUES (1)")
		if err != nil {
			return err
		}
	}

	return nil
}
