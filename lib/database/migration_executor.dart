import 'package:sqflite/sqflite.dart';

/// Handles database migrations for the Cat Calories app
class MigrationExecutor {
  /// Current database version
  static const int currentVersion = 12;

  /// Upgrade the database schema
  Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    // Run migrations sequentially
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _runMigration(db, version);
    }
  }

  /// Downgrade the database schema (if needed)
  Future<void> downgrade(Database db, int oldVersion, int newVersion) async {
    print('Downgrading database from version $oldVersion to $newVersion');
    // Generally, we don't support downgrades, but this is required by sqflite
  }

  /// Run a specific migration version
  Future<void> _runMigration(Database db, int version) async {
    print('Running migration for version $version');

    switch (version) {
      case 2:
        await _migrateToVersion2(db);
        break;
      case 3:
        await _migrateToVersion3(db);
        break;
      case 4:
        await _migrateToVersion4(db);
        break;
      case 5:
        await _migrateToVersion5(db);
        break;
      case 6:
        await _migrateCalorieItemsToUuid(db);
        break;
      case 7:
        await _migrateToVersion7(db);
        break;
      case 8:
        await _migrateProfilesToUuid(db);
        break;
      case 9:
        await _migrateWakingPeriodsToUuid(db);
        break;
      case 10:
        await _migrateToVersion10(db);
        break;
      case 11:
        await _migrateToVersion11(db);
        break;
      case 12:
        await _migrateToVersion12(db);
        break;
    }
  }

  Future<void> _migrateToVersion10(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_servers (
        id TEXT PRIMARY KEY NOT NULL,
        display_name TEXT NOT NULL,
        server_url TEXT NOT NULL,
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
      CREATE TABLE IF NOT EXISTS scoped_server_links (
        id TEXT PRIMARY KEY NOT NULL,
        scope TEXT NOT NULL,
        server_id TEXT NOT NULL,
        sync_enabled INT NOT NULL DEFAULT 1,
        linked_at INT NOT NULL,
        FOREIGN KEY(server_id) REFERENCES sync_servers(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _migrateToVersion11(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auth_credentials (
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

  Future<void> _migrateToVersion12(Database db) async {
    await _addColumnIfNotExists(
        db, 'sync_servers', 'server_urls', "TEXT NOT NULL DEFAULT '[]'");
    // Migrate existing server_url values into the new server_urls column
    await db.execute('''
      UPDATE sync_servers
      SET server_urls = '["' || server_url || '"]'
      WHERE server_url IS NOT NULL AND server_url != ''
    ''');
  }

  /// Migration to version 2: Add nutrition columns to calorie_items
  Future<void> _migrateToVersion2(Database db) async {
    await _addColumnIfNotExists(db, 'calorie_items', 'weight_grams', 'REAL NULL');
    await _addColumnIfNotExists(db, 'calorie_items', 'protein_grams', 'REAL NULL');
    await _addColumnIfNotExists(db, 'calorie_items', 'fat_grams', 'REAL NULL');
    await _addColumnIfNotExists(db, 'calorie_items', 'carb_grams', 'REAL NULL');
  }

  /// Migration to version 3: Add package weight to products
  Future<void> _migrateToVersion3(Database db) async {
    await _addColumnIfNotExists(db, 'products', 'package_weight_grams', 'REAL NULL');
  }

  /// Migration to version 4: Rename product nutrition fields and add category support
  Future<void> _migrateToVersion4(Database db) async {
    // Create product_categories table with UUID primary key
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_categories (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        icon_name TEXT NULL,
        color_hex TEXT NULL,
        sort_order INT DEFAULT 0,
        profile_id INT NOT NULL,
        created_at INT NOT NULL,
        updated_at INT NOT NULL,
        FOREIGN KEY(profile_id) REFERENCES profiles(id)
      )
    ''');

    // Add new columns to products table
    await _addColumnIfNotExists(db, 'products', 'category_id', 'TEXT NULL');
    await _addColumnIfNotExists(db, 'products', 'last_used_at', 'INT NULL');

    // Add renamed columns (keeping old columns for backward compatibility during migration)
    await _addColumnIfNotExists(db, 'products', 'calories_per_100g', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'proteins_per_100g', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'fats_per_100g', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'carbs_per_100g', 'REAL NULL');

    // Copy data from old columns to new columns
    await db.execute('''
      UPDATE products 
      SET calories_per_100g = calorie_content,
          proteins_per_100g = proteins,
          fats_per_100g = fats,
          carbs_per_100g = carbohydrates
      WHERE calorie_content IS NOT NULL OR proteins IS NOT NULL OR fats IS NOT NULL OR carbohydrates IS NOT NULL
    ''');

    print('Migration to version 4 completed: Renamed product nutrition fields and added category support');
  }

  /// Migration to version 5: Add description field to calorie_items for product name tracking
  Future<void> _migrateToVersion5(Database db) async {
    await _addColumnIfNotExists(db, 'calorie_items', 'product_id', 'TEXT NULL');

    // Create index for product lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS calorie_items_product_id_idx ON calorie_items(product_id)
    ''');

    // Create index for category lookups
    await db.execute('''
      CREATE INDEX IF NOT EXISTS products_category_id_idx ON products(category_id)
    ''');

    // Create index for last_used_at sorting
    await db.execute('''
      CREATE INDEX IF NOT EXISTS products_last_used_at_idx ON products(last_used_at)
    ''');

    print('Migration to version 5 completed: Added product_id to calorie_items and created indexes');
  }

  /// Migration to version 7: Add updated_at column to calorie_items
  Future<void> _migrateToVersion7(Database db) async {
    await _addColumnIfNotExists(db, 'calorie_items', 'updated_at', 'INT');
    // Initialize updated_at from created_at for existing rows
    await db.execute('UPDATE calorie_items SET updated_at = created_at WHERE updated_at IS NULL');
    print('Migration to version 7 completed: Added updated_at to calorie_items');
  }

  /// Migration to version 8: Migrate profiles from INTEGER id to TEXT UUID
  Future<void> _migrateProfilesToUuid(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='profiles'"
    );

    if (tables.isEmpty) {
      return; // Table doesn't exist, onCreate will handle it
    }

    // Check if id column is already TEXT
    final tableInfo = await db.rawQuery('PRAGMA table_info(profiles)');
    String? idType;
    for (final row in tableInfo) {
      if (row['name'] == 'id') {
        idType = (row['type'] as String?)?.toUpperCase() ?? '';
        break;
      }
    }

    final isTextId = idType != null && idType.isNotEmpty && idType.contains('TEXT');
    if (isTextId) {
      print('profiles already has TEXT id, skipping migration');
      return;
    }

    print('Migrating profiles table to UUID schema (current id type: "$idType")...');

    try {
      await db.execute('DROP TABLE IF EXISTS profiles_new');

      await db.execute('''
        CREATE TABLE profiles_new (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT,
          created_at INT,
          updated_at INT,
          waking_time_seconds INT,
          calories_limit_goal REAL
        )
      ''');

      // Read existing profiles and build id mapping
      final oldProfiles = await db.query('profiles');
      final idMapping = <String, String>{}; // old int id (as string) -> new UUID

      for (final profile in oldProfiles) {
        final oldId = profile['id'].toString();
        final uuidResult = await db.rawQuery('''
          SELECT lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
                substr(hex(randomblob(2)),2) || '-' ||
                substr('89ab', abs(random()) % 4 + 1, 1) ||
                substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))) as uuid
        ''');
        final newId = uuidResult.first['uuid'] as String;
        idMapping[oldId] = newId;

        await db.insert('profiles_new', {
          'id': newId,
          'name': profile['name'],
          'created_at': profile['created_at'],
          'updated_at': profile['updated_at'],
          'waking_time_seconds': profile['waking_time_seconds'],
          'calories_limit_goal': profile['calories_limit_goal'],
        });
      }

      // Drop old table and rename
      await db.execute('DROP TABLE profiles');
      await db.execute('ALTER TABLE profiles_new RENAME TO profiles');

      // Update profile_id foreign keys in all related tables
      // Use int for WHERE clause since the old profile_id columns store integer values
      // SQLite won't match text "1" against integer 1
      for (final entry in idMapping.entries) {
        final oldIdInt = int.parse(entry.key);
        await db.execute(
          'UPDATE waking_periods SET profile_id = ? WHERE profile_id = ?',
          [entry.value, oldIdInt],
        );
        await db.execute(
          'UPDATE calorie_items SET profile_id = ? WHERE profile_id = ?',
          [entry.value, oldIdInt],
        );
        await db.execute(
          'UPDATE products SET profile_id = ? WHERE profile_id = ?',
          [entry.value, oldIdInt],
        );
        await db.execute(
          'UPDATE product_categories SET profile_id = ? WHERE profile_id = ?',
          [entry.value, oldIdInt],
        );
      }

      print('profiles table migrated to UUID successfully');
    } catch (e) {
      print('Error during profiles table migration: $e');
      try {
        await db.execute('DROP TABLE IF EXISTS profiles_new');
      } catch (_) {}
      rethrow;
    }
  }

  /// Migration to version 9: Migrate waking_periods from INTEGER id to TEXT UUID
  Future<void> _migrateWakingPeriodsToUuid(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='waking_periods'"
    );

    if (tables.isEmpty) {
      return; // Table doesn't exist, onCreate will handle it
    }

    // Check if id column is already TEXT
    final tableInfo = await db.rawQuery('PRAGMA table_info(waking_periods)');
    String? idType;
    for (final row in tableInfo) {
      if (row['name'] == 'id') {
        idType = (row['type'] as String?)?.toUpperCase() ?? '';
        break;
      }
    }

    final isTextId = idType != null && idType.isNotEmpty && idType.contains('TEXT');
    if (isTextId) {
      print('waking_periods already has TEXT id, skipping migration');
      return;
    }

    print('Migrating waking_periods table to UUID schema (current id type: "$idType")...');

    try {
      await db.execute('DROP TABLE IF EXISTS waking_periods_new');

      await db.execute('''
        CREATE TABLE waking_periods_new (
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

      // Read existing waking periods and build id mapping
      final oldPeriods = await db.query('waking_periods');
      final idMapping = <String, String>{}; // old int id (as string) -> new UUID

      for (final period in oldPeriods) {
        final oldId = period['id'].toString();
        final uuidResult = await db.rawQuery('''
          SELECT lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
                substr(hex(randomblob(2)),2) || '-' ||
                substr('89ab', abs(random()) % 4 + 1, 1) ||
                substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))) as uuid
        ''');
        final newId = uuidResult.first['uuid'] as String;
        idMapping[oldId] = newId;

        await db.insert('waking_periods_new', {
          'id': newId,
          'description': period['description'],
          'created_at': period['created_at'],
          'updated_at': period['updated_at'],
          'started_at': period['started_at'],
          'ended_at': period['ended_at'],
          'calories_value': period['calories_value'],
          'profile_id': period['profile_id'],
          'expected_waking_time_seconds': period['expected_waking_time_seconds'],
          'calories_limit_goal': period['calories_limit_goal'],
        });
      }

      // Drop old table and rename
      await db.execute('DROP TABLE waking_periods');
      await db.execute('ALTER TABLE waking_periods_new RENAME TO waking_periods');

      // Update waking_period_id foreign keys in calorie_items
      for (final entry in idMapping.entries) {
        final oldIdInt = int.parse(entry.key);
        await db.execute(
          'UPDATE calorie_items SET waking_period_id = ? WHERE waking_period_id = ?',
          [entry.value, oldIdInt],
        );
      }

      print('waking_periods table migrated to UUID successfully');
    } catch (e) {
      print('Error during waking_periods table migration: $e');
      try {
        await db.execute('DROP TABLE IF EXISTS waking_periods_new');
      } catch (_) {}
      rethrow;
    }
  }

  /// Repair stale integer profile_id values in child tables.
  /// After migrating profiles to UUID, child tables may still have old integer
  /// profile_id values if the migration had a type mismatch bug.
  Future<void> _repairProfileIdForeignKeys(Database db) async {
    // Get all profiles with their UUID ids
    final profiles = await db.query('profiles');
    if (profiles.isEmpty) return;

    // Check if any child table has integer profile_id values that don't match any UUID
    final childTables = ['waking_periods', 'calorie_items', 'products', 'product_categories'];

    for (final table in childTables) {
      final tableExists = await _tableExists(db, table);
      if (!tableExists) continue;

      // Find rows where profile_id looks like an integer (doesn't contain '-')
      final staleRows = await db.rawQuery(
        "SELECT DISTINCT profile_id FROM $table WHERE profile_id NOT LIKE '%-%' AND profile_id IS NOT NULL AND profile_id != ''",
      );

      if (staleRows.isEmpty) continue;

      print('Repairing $table: found ${staleRows.length} stale integer profile_id value(s)');

      // If there's exactly one profile, assign all stale rows to it
      if (profiles.length == 1) {
        final uuid = profiles.first['id'] as String;
        await db.execute(
          "UPDATE $table SET profile_id = ? WHERE profile_id NOT LIKE '%-%'",
          [uuid],
        );
        print('Assigned all stale profile_ids in $table to $uuid');
      } else {
        // Multiple profiles: try to match by old integer id order
        // Sort profiles by created_at to match the original integer id order
        final sortedProfiles = List<Map<String, dynamic>>.from(profiles)
          ..sort((a, b) => (a['created_at'] as int).compareTo(b['created_at'] as int));

        for (int i = 0; i < sortedProfiles.length; i++) {
          final uuid = sortedProfiles[i]['id'] as String;
          final oldIntId = i + 1; // INTEGER PRIMARY KEY starts at 1
          await db.execute(
            'UPDATE $table SET profile_id = ? WHERE CAST(profile_id AS INTEGER) = ?',
            [uuid, oldIntId],
          );
        }
        print('Repaired profile_ids in $table by matching integer order');
      }
    }
  }

  /// Helper method to check if a column exists
  Future<bool> _columnExists(Database db, String table, String column) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    return result.any((row) => row['name'] == column);
  }

  /// Helper method to add a column if it doesn't exist
  Future<void> _addColumnIfNotExists(
      Database db, String table, String column, String type) async {
    if (!await _columnExists(db, table, column)) {
      print('Adding column $column to $table...');
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  /// Migration to version 6: Migrate calorie_items from INTEGER id to TEXT UUID
  Future<void> _migrateCalorieItemsToUuid(Database db) async {
    await _migrateCalorieItemsTableToUuid(db);
    print('Migration to version 6 completed: calorie_items now uses UUID primary key');
  }

  /// Migrate calorie_items table from INTEGER id to TEXT UUID
  Future<void> _migrateCalorieItemsTableToUuid(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='calorie_items'"
    );

    if (tables.isEmpty) {
      return; // Table doesn't exist, onCreate will handle it
    }

    // Check if id column is already TEXT
    final tableInfo = await db.rawQuery('PRAGMA table_info(calorie_items)');
    String? idType;
    for (final row in tableInfo) {
      if (row['name'] == 'id') {
        idType = (row['type'] as String?)?.toUpperCase() ?? '';
        break;
      }
    }

    final isTextId = idType != null && idType.isNotEmpty && idType.contains('TEXT');
    if (isTextId) {
      print('calorie_items already has TEXT id, skipping migration');
      return;
    }

    print('Migrating calorie_items table to UUID schema (current id type: "$idType")...');

    try {
      await db.execute('DROP TABLE IF EXISTS calorie_items_new');

      await db.execute('''
        CREATE TABLE calorie_items_new (
          id TEXT PRIMARY KEY NOT NULL,
          value REAL,
          title TEXT NULL,
          description TEXT NULL,
          sort_order INT,
          created_at INT,
          created_at_day INT,
          eaten_at INT NULL,
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

      // Get columns that exist in both old and new tables (excluding id)
      final newTableInfo = await db.rawQuery('PRAGMA table_info(calorie_items_new)');
      final newColumnNames = newTableInfo.map((r) => r['name'] as String).toSet();
      final oldColumns = tableInfo
          .map((r) => r['name'] as String)
          .where((c) => c != 'id' && newColumnNames.contains(c))
          .toList();
      final columnList = oldColumns.join(', ');

      // Copy data with generated UUIDs
      await db.execute('''
        INSERT INTO calorie_items_new (id, $columnList)
        SELECT
          lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
                substr(hex(randomblob(2)),2) || '-' ||
                substr('89ab', abs(random()) % 4 + 1, 1) ||
                substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))),
          $columnList
        FROM calorie_items
      ''');

      await db.execute('DROP TABLE calorie_items');
      await db.execute('ALTER TABLE calorie_items_new RENAME TO calorie_items');

      // Recreate indexes
      await db.execute('CREATE INDEX IF NOT EXISTS calorie_items_created_at_day_idx ON calorie_items(created_at_day)');
      await db.execute('CREATE INDEX IF NOT EXISTS calorie_items_product_id_idx ON calorie_items(product_id)');

      print('calorie_items table migrated to UUID successfully');
    } catch (e) {
      print('Error during calorie_items table migration: $e');
      try {
        await db.execute('DROP TABLE IF EXISTS calorie_items_new');
      } catch (_) {}
      rethrow;
    }
  }

  /// Check if the id column type is INTEGER (needs migration to TEXT UUID)
  Future<bool> _isIdColumnInteger(Database db, String table) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');
    for (final row in result) {
      if (row['name'] == 'id') {
        final type = (row['type'] as String?)?.toUpperCase() ?? '';
        print('Table $table id column type: $type');
        // Check for INTEGER or empty (SQLite uses empty string for INTEGER PRIMARY KEY)
        return type.contains('INT') || type.isEmpty || type == 'INTEGER';
      }
    }
    // If no id column found, assume we need to create the table
    return true;
  }

  /// Migrate products table from INTEGER id to TEXT UUID
  Future<void> _migrateProductsTableToUuid(Database db) async {
    // Check if table exists
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='products'"
    );

    if (tables.isEmpty) {
      // Table doesn't exist, create it with UUID schema
      print('Creating products table with UUID schema...');
      await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY NOT NULL,
          title TEXT,
          description TEXT NULL,
          created_at INT,
          updated_at INT,
          uses_count INT DEFAULT 0,
          profile_id TEXT NOT NULL,
          sort_order INT DEFAULT 0,
          barcode TEXT NULL,
          calories_per_100g REAL NULL,
          proteins_per_100g REAL NULL,
          fats_per_100g REAL NULL,
          carbs_per_100g REAL NULL,
          package_weight_grams REAL NULL,
          category_id TEXT NULL,
          last_used_at INT NULL
        )
      ''');
      return;
    }

    // Check if id column is TEXT (already migrated)
    final tableInfo = await db.rawQuery('PRAGMA table_info(products)');
    String? idType;
    bool hasProfileId = false;
    for (final row in tableInfo) {
      final colName = row['name'] as String?;
      final colType = row['type'] as String?;
      print('Column: $colName, Type: $colType');
      if (colName == 'id') {
        idType = colType?.toUpperCase();
      }
      if (colName == 'profile_id') {
        hasProfileId = true;
      }
    }

    print('Products table id type: "$idType", has profile_id: $hasProfileId');

    // If id is already TEXT, skip migration
    // SQLite PRAGMA returns uppercase types, but we check case-insensitively to be safe
    // Note: SQLite might return empty string for INTEGER PRIMARY KEY (rowid alias)
    final isTextId = idType != null && idType.isNotEmpty && idType.contains('TEXT');
    if (isTextId) {
      print('Products table already has TEXT id, skipping migration');
      // Still ensure all columns exist
      await _ensureProductsColumns(db);
      return;
    }

    // If idType is INTEGER, empty, or anything else, we need to migrate to TEXT UUID
    print('Migrating products table to UUID schema (current id type: "$idType")...');

    try {
      // Clean up any leftover from previous failed migration
      await db.execute('DROP TABLE IF EXISTS products_new');

      // Create new table with UUID schema
      await db.execute('''
        CREATE TABLE products_new (
          id TEXT PRIMARY KEY NOT NULL,
          title TEXT,
          description TEXT NULL,
          created_at INT,
          updated_at INT,
          uses_count INT DEFAULT 0,
          profile_id TEXT NOT NULL DEFAULT '',
          sort_order INT DEFAULT 0,
          barcode TEXT NULL,
          calorie_content REAL NULL,
          proteins REAL NULL,
          fats REAL NULL,
          carbohydrates REAL NULL,
          calories_per_100g REAL NULL,
          proteins_per_100g REAL NULL,
          fats_per_100g REAL NULL,
          carbs_per_100g REAL NULL,
          package_weight_grams REAL NULL,
          category_id TEXT NULL,
          last_used_at INT NULL
        )
      ''');

      // Get column names from old table to build dynamic INSERT
      final oldColumns = tableInfo.map((r) => r['name'] as String).toList();

      // Columns that exist in both old and new tables (excluding id which we regenerate)
      final commonColumns = <String>[];
      final newTableColumns = [
        'title', 'description', 'created_at', 'updated_at', 'uses_count',
        'profile_id', 'sort_order', 'barcode', 'calorie_content', 'proteins',
        'fats', 'carbohydrates', 'calories_per_100g', 'proteins_per_100g',
        'fats_per_100g', 'carbs_per_100g', 'package_weight_grams',
        'category_id', 'last_used_at'
      ];

      for (final col in newTableColumns) {
        if (oldColumns.contains(col)) {
          commonColumns.add(col);
        }
      }

      print('Migrating columns: $commonColumns from old columns: $oldColumns');

      // Copy data with UUID conversion
      if (commonColumns.isNotEmpty) {
        final columnList = commonColumns.join(', ');
        await db.execute('''
          INSERT INTO products_new (id, $columnList)
          SELECT 
            lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || 
                  substr(hex(randomblob(2)),2) || '-' || 
                  substr('89ab', abs(random()) % 4 + 1, 1) || 
                  substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))),
            $columnList
          FROM products
        ''');
      }

      // Drop old table and rename new one
      await db.execute('DROP TABLE products');
      await db.execute('ALTER TABLE products_new RENAME TO products');

      print('Products table migrated to UUID successfully');
    } catch (e) {
      print('Error during products table migration: $e');
      // Clean up if migration failed
      try {
        await db.execute('DROP TABLE IF EXISTS products_new');
      } catch (_) {}
      rethrow;
    }

    // Ensure all columns exist after migration
    await _ensureProductsColumns(db);
  }

  /// Ensure products table has all required columns
  Future<void> _ensureProductsColumns(Database db) async {
    await _addColumnIfNotExists(db, 'products', 'profile_id', 'TEXT NOT NULL DEFAULT \'\'');
    await _addColumnIfNotExists(db, 'products', 'package_weight_grams', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'category_id', 'TEXT NULL');
    await _addColumnIfNotExists(db, 'products', 'last_used_at', 'INT NULL');
    await _addColumnIfNotExists(db, 'products', 'calories_per_100g', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'proteins_per_100g', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'fats_per_100g', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'carbs_per_100g', 'REAL NULL');
    await _addColumnIfNotExists(db, 'products', 'uses_count', 'INT DEFAULT 0');
    await _addColumnIfNotExists(db, 'products', 'sort_order', 'INT DEFAULT 0');
    await _addColumnIfNotExists(db, 'products', 'barcode', 'TEXT NULL');
    await _addColumnIfNotExists(db, 'products', 'description', 'TEXT NULL');
  }

  /// Migrate product_categories table from INTEGER id to TEXT UUID
  Future<void> _migrateProductCategoriesTableToUuid(Database db) async {
    // Check if table exists
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='product_categories'"
    );

    if (tables.isEmpty) {
      // Table doesn't exist, create it with UUID schema
      print('Creating product_categories table with UUID schema...');
      await db.execute('''
        CREATE TABLE product_categories (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          icon_name TEXT NULL,
          color_hex TEXT NULL,
          sort_order INT DEFAULT 0,
          profile_id TEXT NOT NULL DEFAULT '',
          created_at INT NOT NULL DEFAULT 0,
          updated_at INT NOT NULL DEFAULT 0
        )
      ''');
      return;
    }

    // Check if id column is already TEXT
    final tableInfo = await db.rawQuery('PRAGMA table_info(product_categories)');
    String? idType;
    for (final row in tableInfo) {
      if (row['name'] == 'id') {
        idType = (row['type'] as String?)?.toUpperCase() ?? '';
        break;
      }
    }

    print('Product_categories table id type: $idType');

    if (idType != null && idType.toUpperCase() == 'TEXT') {
      print('Product_categories table already has TEXT id, skipping migration');
      return;
    }

    print('Migrating product_categories table to UUID schema...');

    // Store old id -> new UUID mapping for updating products.category_id
    final oldCategories = await db.query('product_categories');
    final idMapping = <String, String>{}; // old id (as string) -> new UUID

    // Create new table with UUID schema
    await db.execute('''
      CREATE TABLE product_categories_new (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        icon_name TEXT NULL,
        color_hex TEXT NULL,
        sort_order INT DEFAULT 0,
        profile_id TEXT NOT NULL DEFAULT '',
        created_at INT NOT NULL DEFAULT 0,
        updated_at INT NOT NULL DEFAULT 0
      )
    ''');

    // Insert data with new UUIDs and track mapping
    for (final cat in oldCategories) {
      final oldId = cat['id'].toString();
      // Generate a UUID using SQLite
      final uuidResult = await db.rawQuery('''
        SELECT lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || 
              substr(hex(randomblob(2)),2) || '-' || 
              substr('89ab', abs(random()) % 4 + 1, 1) || 
              substr(hex(randomblob(2)),2) || '-' || hex(randomblob(6))) as uuid
      ''');
      final newId = uuidResult.first['uuid'] as String;
      idMapping[oldId] = newId;

      await db.insert('product_categories_new', {
        'id': newId,
        'name': cat['name'] ?? 'Unnamed',
        'icon_name': cat['icon_name'],
        'color_hex': cat['color_hex'],
        'sort_order': cat['sort_order'] ?? 0,
        'profile_id': cat['profile_id'] ?? 1,
        'created_at': cat['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
        'updated_at': cat['updated_at'] ?? DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Update products.category_id to use new UUIDs
    for (final entry in idMapping.entries) {
      await db.execute(
        'UPDATE products SET category_id = ? WHERE category_id = ?',
        [entry.value, entry.key],
      );
    }

    // Drop old table and rename new one
    await db.execute('DROP TABLE product_categories');
    await db.execute('ALTER TABLE product_categories_new RENAME TO product_categories');

    print('Product_categories table migrated to UUID successfully');
  }

  /// Force migration: Run all migrations needed for new installations
  /// This ensures all tables and columns exist even if the database version is already current
  static Future<void> forceMigration(Database db) async {
    print('Running force migration to ensure all schema elements exist...');

    final executor = MigrationExecutor();

    // FIRST: Ensure all required tables exist (create them if they don't)
    await executor._ensureTablesExist(db);

    // Ensure calorie_items has nutrition columns
    await executor._addColumnIfNotExists(db, 'calorie_items', 'weight_grams', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'calorie_items', 'protein_grams', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'calorie_items', 'fat_grams', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'calorie_items', 'carb_grams', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'calorie_items', 'product_id', 'TEXT NULL');
    await executor._addColumnIfNotExists(db, 'calorie_items', 'updated_at', 'INT');
    // Initialize updated_at from created_at for existing rows
    await db.execute('UPDATE calorie_items SET updated_at = created_at WHERE updated_at IS NULL');

    // Check if products table needs to be migrated from INTEGER to TEXT id
    await executor._migrateProductsTableToUuid(db);

    // Ensure products has all new columns
    await executor._addColumnIfNotExists(db, 'products', 'package_weight_grams', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'products', 'category_id', 'TEXT NULL');
    await executor._addColumnIfNotExists(db, 'products', 'last_used_at', 'INT NULL');
    await executor._addColumnIfNotExists(db, 'products', 'calories_per_100g', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'products', 'proteins_per_100g', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'products', 'fats_per_100g', 'REAL NULL');
    await executor._addColumnIfNotExists(db, 'products', 'carbs_per_100g', 'REAL NULL');

    // Check if product_categories table needs to be migrated from INTEGER to TEXT id
    await executor._migrateProductCategoriesTableToUuid(db);

    // Check if calorie_items table needs to be migrated from INTEGER to TEXT UUID id
    await executor._migrateCalorieItemsTableToUuid(db);

    // Check if profiles table needs to be migrated from INTEGER to TEXT UUID id
    await executor._migrateProfilesToUuid(db);

    // Check if waking_periods table needs to be migrated from INTEGER to TEXT UUID id
    await executor._migrateWakingPeriodsToUuid(db);

    // Repair stale integer profile_id values in child tables
    // This fixes databases where migration v8 ran with a bug that failed to update
    // foreign keys (SQLite doesn't match integer 1 against text "1")
    await executor._repairProfileIdForeignKeys(db);

    // Ensure product_categories has all required columns (for tables created with old schema)
    await executor._addColumnIfNotExists(db, 'product_categories', 'profile_id', 'TEXT NOT NULL DEFAULT \'\'');
    await executor._addColumnIfNotExists(db, 'product_categories', 'icon_name', 'TEXT NULL');
    await executor._addColumnIfNotExists(db, 'product_categories', 'color_hex', 'TEXT NULL');
    await executor._addColumnIfNotExists(db, 'product_categories', 'sort_order', 'INT DEFAULT 0');
    await executor._addColumnIfNotExists(db, 'product_categories', 'created_at', 'INT NOT NULL DEFAULT 0');
    await executor._addColumnIfNotExists(db, 'product_categories', 'updated_at', 'INT NOT NULL DEFAULT 0');

    // Copy data from old columns to new columns if needed
    try {
      final products = await db.query('products');
      for (final product in products) {
        final updates = <String, dynamic>{};

        if (product['calories_per_100g'] == null && product['calorie_content'] != null) {
          updates['calories_per_100g'] = product['calorie_content'];
        }
        if (product['proteins_per_100g'] == null && product['proteins'] != null) {
          updates['proteins_per_100g'] = product['proteins'];
        }
        if (product['fats_per_100g'] == null && product['fats'] != null) {
          updates['fats_per_100g'] = product['fats'];
        }
        if (product['carbs_per_100g'] == null && product['carbohydrates'] != null) {
          updates['carbs_per_100g'] = product['carbohydrates'];
        }

        if (updates.isNotEmpty) {
          await db.update('products', updates, where: 'id = ?', whereArgs: [product['id']]);
        }
      }
    } catch (e) {
      print('Error copying data from old columns: $e');
    }

    // Create indexes if not exist
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS calorie_items_product_id_idx ON calorie_items(product_id)');
    } catch (e) {
      print('Index calorie_items_product_id_idx might already exist: $e');
    }

    try {
      await db.execute('CREATE INDEX IF NOT EXISTS products_category_id_idx ON products(category_id)');
    } catch (e) {
      print('Index products_category_id_idx might already exist: $e');
    }

    try {
      await db.execute('CREATE INDEX IF NOT EXISTS products_last_used_at_idx ON products(last_used_at)');
    } catch (e) {
      print('Index products_last_used_at_idx might already exist: $e');
    }

    print('Force migration completed successfully');
  }

  /// Ensure all required tables exist - creates them if they don't
  Future<void> _ensureTablesExist(Database db) async {
    print('Checking that all required tables exist...');

    // Check and create product_categories table
    final categoriesExists = await _tableExists(db, 'product_categories');
    if (!categoriesExists) {
      print('Creating product_categories table...');
      await db.execute('''
        CREATE TABLE product_categories (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          icon_name TEXT NULL,
          color_hex TEXT NULL,
          sort_order INT DEFAULT 0,
          profile_id TEXT NOT NULL DEFAULT '',
          created_at INT NOT NULL DEFAULT 0,
          updated_at INT NOT NULL DEFAULT 0
        )
      ''');
      print('product_categories table created successfully');
    }

    // Check and create products table
    final productsExists = await _tableExists(db, 'products');
    if (!productsExists) {
      print('Creating products table...');
      await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY NOT NULL,
          title TEXT,
          description TEXT NULL,
          created_at INT,
          updated_at INT,
          uses_count INT DEFAULT 0,
          profile_id TEXT NOT NULL,
          sort_order INT DEFAULT 0,
          barcode TEXT NULL,
          calories_per_100g REAL NULL,
          proteins_per_100g REAL NULL,
          fats_per_100g REAL NULL,
          carbs_per_100g REAL NULL,
          package_weight_grams REAL NULL,
          category_id TEXT NULL,
          last_used_at INT NULL
        )
      ''');
      print('products table created successfully');
    }
  }

  /// Check if a table exists in the database
  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName]
    );
    return result.isNotEmpty;
  }
}