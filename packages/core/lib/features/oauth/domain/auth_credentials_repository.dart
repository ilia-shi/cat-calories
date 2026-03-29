import 'package:cat_calories_core/features/oauth/domain/auth_credentials.dart';

abstract class AuthCredentialsRepositoryInterface {
  Future<AuthCredentials?> findByServer(String serverId);
  Future<AuthCredentials> save(AuthCredentials credentials);
  Future<int> deleteByServer(String serverId);
}
