import 'package:get_it/get_it.dart';

abstract class Locator {
  T get<T extends Object>({
    dynamic param1,
    dynamic param2,
    String? instanceName,
    Type? type,
  });

  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
  });
}

final class GetItLocator extends Locator {
  @override
  T get<T extends Object>({param1, param2, String? instanceName, Type? type}) {
    return GetIt.instance.get<T>(
      param1: param1,
      param2: param2,
      instanceName: instanceName,
      type: type,
    );
  }

  @override
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
  }) {
    GetIt.instance.registerLazySingleton<T>(factory, instanceName: instanceName);
  }
}

final Locator locator = GetItLocator();
