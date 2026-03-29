import 'dart:io';
import 'package:cat_calories_core/http/controller.dart';
import 'package:cat_calories_core/http/router.dart';
import '../auth/auth_middleware.dart';
import '../data/sqlite/user_repository.dart';

class AuthHandler extends Controller {
  final UserRepository users;
  final TokenAuth tokenAuth;

  AuthHandler({required this.users, required this.tokenAuth});

  @override
  void register(Router router) {
    router.post('/auth/register', _register);
    router.post('/auth/login', _login);
  }

  Future<void> _register(HttpRequest request, Map<String, String> params) async {
    final data = await parseJsonBody(request);
    final email = data['email'] as String?;
    final password = data['password'] as String?;
    final name = data['name'] as String? ?? '';

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      respondJson(request, HttpStatus.badRequest, {
        'error': 'email and password are required',
      });
      return;
    }

    final existing = users.findByEmail(email);
    if (existing != null) {
      respondJson(request, HttpStatus.conflict, {'error': 'User already exists'});
      return;
    }

    final userId = users.create(email: email, name: name, password: password);
    final token = tokenAuth.createToken(userId);

    respondJson(request, HttpStatus.created, {'token': token, 'user_id': userId});
  }

  Future<void> _login(HttpRequest request, Map<String, String> params) async {
    final data = await parseJsonBody(request);
    final email = data['email'] as String?;
    final password = data['password'] as String?;

    if (email == null || password == null) {
      respondJson(request, HttpStatus.badRequest, {
        'error': 'email and password are required',
      });
      return;
    }

    final user = users.findByEmail(email);
    if (user == null || !users.verifyPassword(user, password)) {
      respondJson(request, HttpStatus.unauthorized, {'error': 'Invalid credentials'});
      return;
    }

    final token = tokenAuth.createToken(user.id);
    respondJson(request, HttpStatus.ok, {'token': token, 'user_id': user.id});
  }
}
