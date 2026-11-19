import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/interfaces.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthLocalDataSource _dataSource;

  AuthRepositoryImpl({required AuthLocalDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<bool> isLoggedIn() => _dataSource.isLoggedIn();

  @override
  Future<AuthUser?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    String role = 'student',
    String group = 'Thành viên EduMaster',
  }) {
    return _dataSource.register(
      name: name,
      email: email,
      password: password,
      role: role,
      group: group,
    );
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) {
    return _dataSource.login(email: email, password: password);
  }





  @override
  Future<void> logout() => _dataSource.logout();
}
