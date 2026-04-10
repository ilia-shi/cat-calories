import 'package:sqflite/sqflite.dart';
import 'package:cat_calories/database/migrations/migration.dart';

class V001InitialSchema extends Migration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE profiles(
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT,
        created_at INT,
        updated_at INT,
        waking_time_seconds INT,
        calories_limit_goal REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE waking_periods (
        id TEXT PRIMARY KEY NOT NULL,
        description TEXT NULL,
        created_at INT,
        updated_at INT,
        started_at INT,
        ended_at INT NULL,
        calories_value REAL,
        profile_id TEXT,
        expected_waking_time_seconds INT,
        calories_limit_goal REAL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE calorie_items (
        id TEXT PRIMARY KEY NOT NULL,
        value REAL,
        title TEXT NULL,
        description TEXT NULL,
        sort_order INT,
        created_at INT,
        created_at_day INT,
        eaten_at INT NULL,
        updated_at INT,
        profile_id TEXT,
        waking_period_id TEXT,
        weight_grams REAL NULL,
        protein_grams REAL NULL,
        fat_grams REAL NULL,
        carb_grams REAL NULL,
        product_id TEXT NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id),
        FOREIGN KEY(waking_period_id) REFERENCES waking_periods(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE product_categories(
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        icon_name TEXT NULL,
        color_hex TEXT NULL,
        sort_order INT DEFAULT 0,
        profile_id TEXT NOT NULL,
        created_at INT NOT NULL,
        updated_at INT NOT NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT,
        description TEXT NULL,
        created_at INT,
        updated_at INT,
        uses_count INT,
        profile_id TEXT,
        sort_order INT DEFAULT 0,
        barcode TEXT NULL,
        calories_per_100g REAL NULL,
        proteins_per_100g REAL NULL,
        fats_per_100g REAL NULL,
        carbs_per_100g REAL NULL,
        package_weight_grams REAL NULL,
        category_id TEXT NULL,
        last_used_at INT NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id),
        FOREIGN KEY(category_id) REFERENCES product_categories(id)
      )
    ''');

    await db.execute(
        'CREATE INDEX calorie_items_created_at_day_idx ON calorie_items(created_at_day)');
    await db.execute(
        'CREATE INDEX calorie_items_product_id_idx ON calorie_items(product_id)');
    await db.execute(
        'CREATE INDEX products_category_id_idx ON products(category_id)');
    await db.execute(
        'CREATE INDEX products_last_used_at_idx ON products(last_used_at)');

    await db.execute('''
      CREATE TABLE sync_servers(
        id TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        server_url TEXT NOT NULL DEFAULT '',
        server_urls TEXT NOT NULL DEFAULT '[]',
        transport_type TEXT NOT NULL DEFAULT 'rest',
        transport_json TEXT NOT NULL,
        is_active INT NOT NULL DEFAULT 1,
        created_at INT NOT NULL,
        last_seen_at INT NULL,
        protocol_version INT NOT NULL DEFAULT 1,
        server_version TEXT NULL,
        auth_json TEXT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE scoped_server_links(
        id TEXT PRIMARY KEY NOT NULL,
        scope TEXT NOT NULL,
        server_id TEXT NOT NULL,
        sync_enabled INT NOT NULL DEFAULT 1,
        linked_at INT NOT NULL,
        FOREIGN KEY(server_id) REFERENCES sync_servers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE auth_credentials(
        id TEXT PRIMARY KEY NOT NULL,
        server_id TEXT NOT NULL UNIQUE,
        access_token TEXT NOT NULL,
        token_type TEXT NOT NULL DEFAULT 'bearer',
        created_at INT NOT NULL,
        expires_at INT NULL,
        FOREIGN KEY(server_id) REFERENCES sync_servers(id) ON DELETE CASCADE
      )
    ''');
  }
}
