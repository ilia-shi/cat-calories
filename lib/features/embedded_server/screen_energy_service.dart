import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls screen brightness and wakelock during web server operation.
///
/// Manages three states:
/// - **Active**: screen on at normal brightness
/// - **Dimmed**: screen on at minimum brightness (after dim timeout)
/// - **Off**: wakelock released, device sleeps normally (after sleep timeout)
class ScreenEnergyService {
  static const _wakelockChannel = MethodChannel('com.sywer.cat_calories/wakelock');
  static const String screenTimeoutKey = 'web_server_screen_timeout_minutes';
  static const int defaultTimeoutMinutes = 5;
  static const String dimTimeoutKey = 'web_server_dim_timeout_minutes';
  static const int defaultDimMinutes = -1; // -1 = use device default

  /// Available sleep timeout options in minutes. 0 means never.
  static const List<int> timeoutOptions = [0, 1, 2, 5, 10, 15, 30];

  /// Available dim timeout options. -1 = device default, 0 = never.
  static const List<int> dimTimeoutOptions = [-1, 0, 1, 2, 5, 10, 15, 30];

  static const _clientTimeout = Duration(seconds: 10);

  Timer? _dimTimer;
  Timer? _sleepTimer;
  Timer? _clientCheckTimer;
  bool _wakelockEnabled = false;
  bool _isDimmed = false;
  bool _active = false;
  bool _hasClients = false;
  DateTime? _lastPollTime;

  bool get isActive => _active;
  bool get isDimmed => _isDimmed;
  bool get hasClients => _hasClients;

  /// Start energy management (call when web server starts).
  Future<void> start() async {
    _active = true;
    _hasClients = false;
    _lastPollTime = null;
    _startClientCheck();
    // Don't enable wakelock yet — wait for a browser client to connect.
  }

  /// Stop energy management (call when web server stops).
  Future<void> stop() async {
    _active = false;
    _hasClients = false;
    _lastPollTime = null;
    _dimTimer?.cancel();
    _dimTimer = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _clientCheckTimer?.cancel();
    _clientCheckTimer = null;
    await _disableWakelock();
  }

  /// Call when a polling request is received from a browser client.
  void onClientPoll() {
    if (!_active) return;
    _lastPollTime = DateTime.now();
    if (!_hasClients) {
      _hasClients = true;
      _enableWakelock();
      _resetTimers();
    }
  }

  /// Call on user interaction (touch) to restore brightness and reset timers.
  void onUserActivity() {
    if (!_active) return;
    _enableWakelock();
    _resetTimers();
  }

  /// Restore brightness without resetting timers (e.g. on device unlock).
  void restoreBrightness() {
    if (_isDimmed) {
      _enableWakelock();
    }
  }

  // -- Settings --

  Future<int> getTimeoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(screenTimeoutKey) ?? defaultTimeoutMinutes;
  }

  Future<void> setTimeoutMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(screenTimeoutKey, minutes);
    if (_active) _resetTimers();
  }

  Future<int> getDimTimeoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dimTimeoutKey) ?? defaultDimMinutes;
  }

  Future<void> setDimTimeoutMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(dimTimeoutKey, minutes);
    if (_active) _resetTimers();
  }

  // -- Private --

  void _startClientCheck() {
    _clientCheckTimer?.cancel();
    _clientCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_hasClients) return;
      final lastPoll = _lastPollTime;
      if (lastPoll != null &&
          DateTime.now().difference(lastPoll) > _clientTimeout) {
        // No polls received — browser tab is closed
        _hasClients = false;
        _lastPollTime = null;
        _dimTimer?.cancel();
        _sleepTimer?.cancel();
        _disableWakelock();
      }
    });
  }

  void _resetTimers() async {
    _dimTimer?.cancel();
    _sleepTimer?.cancel();

    if (_isDimmed) {
      await _enableWakelock();
    }

    // 1) Dim after configured timeout
    final dimMinutes = await getDimTimeoutMinutes();
    if (dimMinutes != 0) {
      final dimTimeout = dimMinutes == -1
          ? await _getSystemScreenTimeout()
          : Duration(minutes: dimMinutes);
      if (dimTimeout > Duration.zero) {
        _dimTimer = Timer(dimTimeout, () async {
          await _dimScreen();
        });
      }
    }

    // 2) Sleep after configured timeout (only if no browser clients connected)
    final sleepMinutes = await getTimeoutMinutes();
    if (sleepMinutes > 0) {
      _sleepTimer = Timer(Duration(minutes: sleepMinutes), () async {
        if (!_hasClients) {
          await _disableWakelock();
        }
      });
    }
  }

  Future<Duration> _getSystemScreenTimeout() async {
    try {
      final ms = await _wakelockChannel.invokeMethod<int>('getScreenTimeout');
      return Duration(milliseconds: ms ?? 60000);
    } catch (_) {
      return const Duration(seconds: 60);
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await _wakelockChannel.invokeMethod('enable');
      _wakelockEnabled = true;
      _isDimmed = false;
    } catch (_) {}
  }

  Future<void> _disableWakelock() async {
    if (!_wakelockEnabled && !_isDimmed) return;
    try {
      await _wakelockChannel.invokeMethod('disable');
      _wakelockEnabled = false;
      _isDimmed = false;
    } catch (_) {}
  }

  Future<void> _dimScreen() async {
    try {
      await _wakelockChannel.invokeMethod('dim');
      _isDimmed = true;
      _wakelockEnabled = false;
    } catch (_) {}
  }
}
