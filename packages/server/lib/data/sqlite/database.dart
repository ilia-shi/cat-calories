import 'package:sqlite3/sqlite3.dart';

Database openDatabase(String path) {
  final db = sqlite3.open(path);
  db.execute('PRAGMA journal_mode=WAL');
  db.execute('PRAGMA foreign_keys=ON');
  _migrate(db);
  return db;
}

void _migrate(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id            TEXT PRIMARY KEY,
      email         TEXT NOT NULL,
      name          TEXT NOT NULL DEFAULT '',
      password_hash TEXT NOT NULL DEFAULT '',
      provider      TEXT NOT NULL DEFAULT 'local',
      subject       TEXT NOT NULL DEFAULT '',
      created_at    DATETIME NOT NULL DEFAULT (datetime('now')),
      updated_at    DATETIME NOT NULL DEFAULT (datetime('now')),
      UNIQUE(provider, subject)
    );

    CREATE TABLE IF NOT EXISTS profiles (
      id                  TEXT PRIMARY KEY,
      user_id             TEXT NOT NULL REFERENCES users(id),
      name                TEXT NOT NULL DEFAULT '',
      waking_time_seconds INTEGER NOT NULL DEFAULT 57600,
      calories_limit_goal REAL    NOT NULL DEFAULT 2000,
      created_at          INTEGER NOT NULL,
      updated_at          INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS calorie_items (
      id               TEXT PRIMARY KEY,
      profile_id       TEXT    NOT NULL,
      waking_period_id TEXT,
      product_id       TEXT,
      value            REAL    NOT NULL DEFAULT 0,
      description      TEXT    NOT NULL DEFAULT '',
      sort_order       INTEGER NOT NULL DEFAULT 0,
      weight_grams     REAL,
      protein_grams    REAL,
      fat_grams        REAL,
      carb_grams       REAL,
      created_at_day   INTEGER,
      eaten_at         INTEGER,
      created_at       INTEGER NOT NULL,
      updated_at       INTEGER NOT NULL,
      deleted_at       INTEGER
    );

    CREATE TABLE IF NOT EXISTS products (
      id                TEXT PRIMARY KEY,
      profile_id        TEXT    NOT NULL,
      category_id       TEXT,
      title             TEXT    NOT NULL DEFAULT '',
      description       TEXT    NOT NULL DEFAULT '',
      barcode           TEXT,
      calories_per_100g REAL,
      proteins_per_100g REAL,
      fats_per_100g     REAL,
      carbs_per_100g    REAL,
      package_weight_grams REAL,
      uses_count        INTEGER NOT NULL DEFAULT 0,
      last_used_at      INTEGER,
      sort_order        INTEGER NOT NULL DEFAULT 0,
      created_at        INTEGER NOT NULL,
      updated_at        INTEGER NOT NULL,
      deleted_at        INTEGER
    );

    CREATE TABLE IF NOT EXISTS product_categories (
      id         TEXT PRIMARY KEY,
      profile_id TEXT    NOT NULL,
      name       TEXT    NOT NULL DEFAULT '',
      icon_name  TEXT,
      color_hex  TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER
    );

    CREATE TABLE IF NOT EXISTS waking_periods (
      id                          TEXT PRIMARY KEY,
      profile_id                  TEXT    NOT NULL,
      description                 TEXT,
      calories_value              REAL    NOT NULL DEFAULT 0,
      calories_limit_goal         REAL    NOT NULL DEFAULT 0,
      expected_waking_time_seconds INTEGER NOT NULL DEFAULT 0,
      started_at                  INTEGER NOT NULL,
      ended_at                    INTEGER,
      created_at                  INTEGER NOT NULL,
      updated_at                  INTEGER NOT NULL,
      deleted_at                  INTEGER
    );

    CREATE TABLE IF NOT EXISTS sync_entries (
      entity_type TEXT    NOT NULL,
      entity_id   TEXT    NOT NULL,
      scope       TEXT    NOT NULL DEFAULT '',
      user_id     TEXT    NOT NULL,
      client_hlc  TEXT    NOT NULL DEFAULT '',
      server_hlc  TEXT    NOT NULL DEFAULT '',
      version     INTEGER NOT NULL DEFAULT 1,
      is_deleted  INTEGER NOT NULL DEFAULT 0,
      payload     TEXT,
      created_at  DATETIME NOT NULL DEFAULT (datetime('now')),
      PRIMARY KEY (entity_type, entity_id)
    );

    CREATE TABLE IF NOT EXISTS sync_idempotency (
      idempotency_key TEXT PRIMARY KEY,
      user_id         TEXT NOT NULL,
      accepted        INTEGER NOT NULL DEFAULT 0,
      created_at      DATETIME NOT NULL DEFAULT (datetime('now'))
    );

    CREATE INDEX IF NOT EXISTS idx_calorie_items_profile  ON calorie_items(profile_id);
    CREATE INDEX IF NOT EXISTS idx_calorie_items_eaten_at ON calorie_items(eaten_at);
    CREATE INDEX IF NOT EXISTS idx_products_profile       ON products(profile_id);
    CREATE INDEX IF NOT EXISTS idx_products_category      ON products(category_id);
    CREATE INDEX IF NOT EXISTS idx_sync_entries_pull       ON sync_entries(user_id, entity_type, server_hlc);
  ''');
}
