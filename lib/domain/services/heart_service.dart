import 'dart:async';
import '../../data/models/heart_state.dart';
import '../../data/repositories/heart_repository.dart';
import '../../core/utils/logger.dart';
import '../../core/platform/secure_storage.dart';

/// Heart system service for managing hearts with regeneration
class HeartService {
  final HeartRepository _repository;
  final SecureStorageService _storage;
  
  Timer? _regenerationTimer;
  Timer? _countdownTimer;
  
  HeartStateModel? _currentState;
  final _stateController = StreamController<HeartStateModel>.broadcast();
  final _timerController = StreamController<Duration>.broadcast();
  
  Stream<HeartStateModel> get stateStream => _stateController.stream;
  Stream<Duration> get timerStream => _timerController.stream;
  
  HeartStateModel? get currentState => _currentState;
  
  static const String _lastKnownHeartsKey = 'last_known_hearts';
  static const String _lastLossTimeKey = 'last_heart_loss_time';

  HeartService({
    required HeartRepository repository,
    required SecureStorageService storage,
  })  : _repository = repository,
        _storage = storage;

  /// Initialize heart state for user
  Future<void> initialize(String userId) async {
    AppLogger.info('Initializing heart service for user: $userId');
    
    // Try to restore from local storage first
    final storedHearts = await _storage.read(_lastKnownHeartsKey);
    final storedLossTime = await _storage.read(_lastLossTimeKey);
    
    // Load from repository
    final result = await _repository.getHeartState(userId);
    
    if (result.heartState != null) {
      _currentState = result.heartState;
      
      // Apply any regeneration that should have happened
      if (_currentState != null && !_currentState!.isFull) {
        final regenerated = _currentState!.regenerate();
        if (regenerated.currentHearts != _currentState!.currentHearts) {
          _currentState = regenerated;
          await _repository.updateHeartState(_currentState!);
        }
      }
      
      _stateController.add(_currentState!);
      _startTimers();
    } else if (storedHearts != null && storedLossTime != null) {
      // Restore from local storage
      final hearts = int.tryParse(storedHearts) ?? HeartStateModel.maxHearts;
      final lossTime = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(storedLossTime) ?? DateTime.now().millisecondsSinceEpoch,
      );
      
      _currentState = HeartStateModel(
        userId: userId,
        currentHearts: hearts,
        lastHeartLossAt: lossTime,
        lastRegenerationAt: lossTime,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      ).regenerate();
      
      await _repository.updateHeartState(_currentState!);
      _stateController.add(_currentState!);
      _startTimers();
    } else {
      // Create new state
      _currentState = HeartStateModel.initial(userId);
      await _repository.updateHeartState(_currentState!);
      _stateController.add(_currentState!);
    }
    
    AppLogger.info('Heart state initialized: ${_currentState?.currentHearts} hearts');
  }

  /// Use a heart (wrong answer)
  Future<bool> useHeart() async {
    if (_currentState == null || !canUseHeart) {
      return false;
    }
    
    AppLogger.info('Using heart. Current: ${_currentState!.currentHearts}');
    
    _currentState = _currentState!.loseHeart();
    _stateController.add(_currentState!);
    
    // Persist
    await _repository.updateHeartState(_currentState!);
    await _storage.write(_lastKnownHeartsKey, _currentState!.currentHearts.toString());
    await _storage.write(
      _lastLossTimeKey, 
      _currentState!.lastHeartLossAt!.millisecondsSinceEpoch.toString(),
    );
    
    _startTimers();
    
    AppLogger.info('Heart used. Remaining: ${_currentState!.currentHearts}');
    return true;
  }

  /// Refill all hearts (reward/purchase)
  Future<void> refillHearts() async {
    if (_currentState == null) return;
    
    AppLogger.info('Refilling hearts');
    
    _currentState = _currentState!.refillHearts();
    _stateController.add(_currentState!);
    
    await _repository.updateHeartState(_currentState!);
    await _storage.write(_lastKnownHeartsKey, _currentState!.currentHearts.toString());
    
    _stopTimers();
    
    AppLogger.info('Hearts refilled: ${_currentState!.currentHearts}');
  }

  /// Add bonus hearts (from watching ad, daily reward, etc)
  Future<void> addBonusHearts(int count) async {
    if (_currentState == null) return;
    
    final newHearts = (_currentState!.currentHearts + count)
        .clamp(0, HeartStateModel.maxHearts);
    
    _currentState = _currentState!.copyWith(
      currentHearts: newHearts,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    _stateController.add(_currentState!);
    await _repository.updateHeartState(_currentState!);
    
    if (_currentState!.isFull) {
      _stopTimers();
    }
    
    AppLogger.info('Added $count bonus hearts. Total: ${_currentState!.currentHearts}');
  }

  /// Check if user can use a heart
  bool get canUseHeart => _currentState?.currentHearts != null && 
                          _currentState!.currentHearts > 0;

  /// Check if hearts are full
  bool get isFull => _currentState?.isFull ?? true;

  /// Get current heart count
  int get currentHearts => _currentState?.currentHearts ?? 0;

  /// Get time until next heart regenerates
  Duration get timeUntilNextHeart => _currentState?.timeUntilNextHeart ?? Duration.zero;

  /// Get time until all hearts are full
  Duration get timeUntilFullHearts => _currentState?.timeUntilFullHearts ?? Duration.zero;

  void _startTimers() {
    _stopTimers();
    
    if (_currentState == null || _currentState!.isFull) return;
    
    // Countdown timer - updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentState == null) return;
      
      final timeRemaining = _calculateTimeUntilNextHeart();
      _timerController.add(timeRemaining);
      
      // Check if it's time to regenerate
      if (timeRemaining <= Duration.zero) {
        _regenerateHeart();
      }
    });
    
    AppLogger.info('Heart timers started');
  }

  void _stopTimers() {
    _regenerationTimer?.cancel();
    _countdownTimer?.cancel();
    _regenerationTimer = null;
    _countdownTimer = null;
  }

  Duration _calculateTimeUntilNextHeart() {
    if (_currentState == null || _currentState!.isFull) {
      return Duration.zero;
    }
    
    final referenceTime = _currentState!.lastRegenerationAt ?? 
                         _currentState!.lastHeartLossAt ?? 
                         DateTime.now();
    final now = DateTime.now();
    final elapsed = now.difference(referenceTime);
    final elapsedInCurrentCycle = elapsed.inSeconds % 
        (HeartStateModel.regenerationMinutes * 60);
    final secondsUntilNext = (HeartStateModel.regenerationMinutes * 60) - 
        elapsedInCurrentCycle;
    
    return Duration(seconds: secondsUntilNext);
  }

  void _regenerateHeart() async {
    if (_currentState == null || _currentState!.isFull) return;
    
    final regenerated = _currentState!.regenerate();
    
    if (regenerated.currentHearts > _currentState!.currentHearts) {
      _currentState = regenerated;
      _stateController.add(_currentState!);
      
      await _repository.updateHeartState(_currentState!);
      await _storage.write(
        _lastKnownHeartsKey, 
        _currentState!.currentHearts.toString(),
      );
      
      AppLogger.info('Heart regenerated. Current: ${_currentState!.currentHearts}');
      
      if (_currentState!.isFull) {
        _stopTimers();
      }
    }
  }

  /// Format time as MM:SS string
  String formatTime(Duration duration) {
    if (duration <= Duration.zero) return '00:00';
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format time as human readable string
  String formatTimeReadable(Duration duration) {
    if (duration <= Duration.zero) return 'Дууссан';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours цаг $minutes мин';
    }
    return '$minutes минут';
  }

  void dispose() {
    _stopTimers();
    _stateController.close();
    _timerController.close();
  }
}
