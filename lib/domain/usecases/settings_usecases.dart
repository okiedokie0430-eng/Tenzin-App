import '../../data/models/user_settings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/error/failures.dart';

class GetUserSettingsUseCase {
  final SettingsRepository _repository;

  GetUserSettingsUseCase(this._repository);

  Future<({UserSettingsModel? settings, Failure? failure})> call(
    String userId,
  ) {
    return _repository.getSettings(userId);
  }
}

class UpdateUserSettingsUseCase {
  final SettingsRepository _repository;

  UpdateUserSettingsUseCase(this._repository);

  Future<({UserSettingsModel? settings, Failure? failure})> call(
    UserSettingsModel settings,
  ) {
    return _repository.updateSettings(settings);
  }
}

class UpdateNotificationSettingUseCase {
  final SettingsRepository _repository;

  UpdateNotificationSettingUseCase(this._repository);

  Future<Failure?> call({
    required String userId,
    required String settingKey,
    required bool value,
  }) {
    return _repository.updateNotificationSetting(
      userId: userId,
      settingKey: settingKey,
      value: value,
    );
  }
}
