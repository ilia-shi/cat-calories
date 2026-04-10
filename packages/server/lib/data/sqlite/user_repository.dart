import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class User {
  final String id;
  final String email;
  final String name;
  final String passwordHash;
  final String provider;
  final String subject;
  final String createdAt;
  final String updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    required this.provider,
    required this.subject,
    required this.createdAt,
    required this.updatedAt,
  });
}

class UserRepository {
  final Database _db;

  UserRepository(this._db);

  User? findById(String id) {
    final result = _db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return _rowToUser(result.first);
  }

  User? findByEmail(String email) {
    final result = _db.select('SELECT * FROM users WHERE email = ?', [email]);
    if (result.isEmpty) return null;
    return _rowToUser(result.first);
  }

  User? findByProviderSubject(String provider, String subject) {
    final result = _db.select(
      'SELECT * FROM users WHERE provider = ? AND subject = ?',
      [provider, subject],
    );
    if (result.isEmpty) return null;
    return _rowToUser(result.first);
  }

  String create({
    required String email,
    required String name,
    String password = '',
    String provider = 'local',
    String subject = '',
  }) {
    final id = const Uuid().v4();
    final hash = password.isNotEmpty ? _hashPassword(password) : '';

    _db.execute(
      'INSERT INTO users (id, email, name, password_hash, provider, subject) VALUES (?, ?, ?, ?, ?, ?)',
      [id, email, name, hash, provider, subject.isEmpty ? email : subject],
    );

    return id;
  }

  bool verifyPassword(User user, String password) {
    return user.passwordHash == _hashPassword(password);
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Find or create a user for an OAuth provider/subject pair.
  String findOrCreateByProvider(String provider, String subject) {
    final existing = findByProviderSubject(provider, subject);
    if (existing != null) return existing.id;

    return create(
      email: '$subject@$provider',
      name: subject,
      provider: provider,
      subject: subject,
    );
  }

  User _rowToUser(Row row) {
    return User(
      id: row['id'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      passwordHash: row['password_hash'] as String,
      provider: row['provider'] as String,
      subject: row['subject'] as String,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
    );
  }
}
