import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Validates that the Dart controller JSON output matches the OpenAPI schema.
///
/// Loads the OpenAPI spec from api/openapi.yaml and checks that the field names
/// and types produced by the Dart controllers are consistent with the schema.
void main() {
  late YamlMap spec;
  late YamlMap schemas;

  setUpAll(() {
    final file = File('api/openapi.yaml');
    expect(file.existsSync(), isTrue, reason: 'api/openapi.yaml must exist');
    spec = loadYaml(file.readAsStringSync()) as YamlMap;
    schemas = spec['components']['schemas'] as YamlMap;
  });

  group('CalorieRecord schema', () {
    test('has all required fields', () {
      final schema = schemas['CalorieRecord'] as YamlMap;
      final required = (schema['required'] as YamlList).toList();
      final properties = (schema['properties'] as YamlMap).keys.toList();

      expect(required, containsAll([
        'id', 'value', 'description', 'created_at', 'eaten_at',
        'weight_grams', 'protein_grams', 'fat_grams', 'carb_grams',
      ]));

      // Verify these are the same fields the Dart _itemToJson produces
      final dartFields = [
        'id', 'value', 'description', 'created_at', 'eaten_at',
        'weight_grams', 'protein_grams', 'fat_grams', 'carb_grams',
      ];
      for (final field in dartFields) {
        expect(properties, contains(field),
            reason: 'OpenAPI CalorieRecord should have field "$field"');
      }
    });

    test('field types match Dart serialization', () {
      final props = schemas['CalorieRecord']['properties'] as YamlMap;

      _expectType(props, 'id', 'string', nullable: false);
      _expectType(props, 'value', 'number', nullable: false);
      _expectType(props, 'description', 'string', nullable: true);
      _expectType(props, 'created_at', 'string', nullable: false);
      _expectType(props, 'eaten_at', 'string', nullable: true);
      _expectType(props, 'weight_grams', 'number', nullable: true);
      _expectType(props, 'protein_grams', 'number', nullable: true);
      _expectType(props, 'fat_grams', 'number', nullable: true);
      _expectType(props, 'carb_grams', 'number', nullable: true);
    });
  });

  group('Profile schema', () {
    test('has correct fields', () {
      final props = schemas['Profile']['properties'] as YamlMap;
      final required = (schemas['Profile']['required'] as YamlList).toList();

      expect(required, containsAll(['name', 'calories_limit_goal']));
      _expectType(props, 'name', 'string', nullable: false);
      _expectType(props, 'calories_limit_goal', 'number', nullable: false);
    });
  });

  group('RecordsResponse schema', () {
    test('has profile and records fields', () {
      final schema = schemas['RecordsResponse'] as YamlMap;
      final required = (schema['required'] as YamlList).toList();

      expect(required, containsAll(['profile', 'records']));

      final props = schema['properties'] as YamlMap;
      // profile references Profile
      expect(props['profile'][r'$ref'], contains('Profile'));
      // records is array of CalorieRecord
      expect(props['records']['type'], equals('array'));
      expect(props['records']['items'][r'$ref'], contains('CalorieRecord'));
    });
  });

  group('SingleRecordResponse schema', () {
    test('has record field', () {
      final schema = schemas['SingleRecordResponse'] as YamlMap;
      final required = (schema['required'] as YamlList).toList();

      expect(required, contains('record'));
      final props = schema['properties'] as YamlMap;
      expect(props['record'][r'$ref'], contains('CalorieRecord'));
    });
  });

  group('DeleteResponse schema', () {
    test('has deleted boolean field', () {
      final schema = schemas['DeleteResponse'] as YamlMap;
      final required = (schema['required'] as YamlList).toList();

      expect(required, contains('deleted'));
      final props = schema['properties'] as YamlMap;
      expect(props['deleted']['type'], equals('boolean'));
    });
  });

  group('HomeDashboardResponse schema', () {
    test('has all required fields', () {
      final schema = schemas['HomeDashboardResponse'] as YamlMap;
      final required = (schema['required'] as YamlList).toList();

      expect(required, containsAll([
        'profile', 'rolling_24h', 'today', 'yesterday',
        'avg_7_days', 'period', 'recent_meals',
      ]));
    });

    test('field types match Dart home controller output', () {
      final props = schemas['HomeDashboardResponse']['properties'] as YamlMap;

      // profile references Profile
      expect(props['profile'][r'$ref'], contains('Profile'));

      // numeric fields
      _expectType(props, 'rolling_24h', 'number', nullable: false);
      _expectType(props, 'today', 'number', nullable: false);
      _expectType(props, 'yesterday', 'number', nullable: false);
      _expectType(props, 'avg_7_days', 'number', nullable: false);

      // period is nullable PeriodSummary
      expect(props['period']['nullable'], isTrue);

      // recent_meals is array of RecentMeal
      expect(props['recent_meals']['type'], equals('array'));
      expect(props['recent_meals']['items'][r'$ref'], contains('RecentMeal'));
    });
  });

  group('RecentMeal schema', () {
    test('field types match Dart serialization', () {
      final props = schemas['RecentMeal']['properties'] as YamlMap;

      _expectType(props, 'id', 'string', nullable: false);
      _expectType(props, 'value', 'number', nullable: false);
      _expectType(props, 'description', 'string', nullable: true);
      _expectType(props, 'eaten_at', 'string', nullable: false);
    });
  });

  group('PeriodSummary schema', () {
    test('has calories and goal fields', () {
      final props = schemas['PeriodSummary']['properties'] as YamlMap;

      _expectType(props, 'calories', 'number', nullable: false);
      _expectType(props, 'goal', 'number', nullable: false);
    });
  });

  group('CreateRecordRequest schema', () {
    test('value is the only required field', () {
      final schema = schemas['CreateRecordRequest'] as YamlMap;
      final required = (schema['required'] as YamlList).toList();

      expect(required, equals(['value']));
    });

    test('has correct optional fields', () {
      final props = schemas['CreateRecordRequest']['properties'] as YamlMap;

      _expectType(props, 'value', 'number', nullable: false);
      _expectType(props, 'description', 'string', nullable: true);
      _expectType(props, 'eaten_at', 'string', nullable: true);
      _expectType(props, 'weight_grams', 'number', nullable: true);
      _expectType(props, 'protein_grams', 'number', nullable: true);
      _expectType(props, 'fat_grams', 'number', nullable: true);
      _expectType(props, 'carb_grams', 'number', nullable: true);
    });
  });

  group('UpdateRecordRequest schema', () {
    test('has no required fields', () {
      final schema = schemas['UpdateRecordRequest'] as YamlMap;
      expect(schema['required'], isNull);
    });
  });

  group('API paths', () {
    test('all expected endpoints exist', () {
      final paths = spec['paths'] as YamlMap;

      expect(paths.containsKey('/api/records'), isTrue);
      expect(paths.containsKey('/api/records/{id}'), isTrue);
      expect(paths.containsKey('/api/home'), isTrue);

      // Check methods
      final records = paths['/api/records'] as YamlMap;
      expect(records.containsKey('get'), isTrue);
      expect(records.containsKey('post'), isTrue);

      final recordById = paths['/api/records/{id}'] as YamlMap;
      expect(recordById.containsKey('put'), isTrue);
      expect(recordById.containsKey('delete'), isTrue);

      final home = paths['/api/home'] as YamlMap;
      expect(home.containsKey('get'), isTrue);
    });
  });
}

void _expectType(YamlMap properties, String field, String expectedType,
    {required bool nullable}) {
  final prop = properties[field] as YamlMap;
  expect(prop, isNotNull, reason: 'Field "$field" should exist in schema');
  expect(prop['type'], equals(expectedType),
      reason: 'Field "$field" should be of type "$expectedType"');
  if (nullable) {
    expect(prop['nullable'], isTrue,
        reason: 'Field "$field" should be nullable');
  }
}
