import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage tutorial state and persistence
/// Follows Meta-quality standards for user onboarding
class TutorialService extends ChangeNotifier {
  bool _hasSeenTutorial = false;
  bool _isShowingTutorial = false;
  int _currentStep = 0;
  DateTime? _tutorialCompletedAt;
  
  // Getters
  bool get hasSeenTutorial => _hasSeenTutorial;
  bool get isShowingTutorial => _isShowingTutorial;
  int get currentStep => _currentStep;
  
  // SharedPreferences keys
  static const String _keyHasSeenTutorial = 'has_seen_quick_tutorial';
  static const String _keyCompletedAt = 'tutorial_completed_at';
  static const String _keySkippedAtStep = 'tutorial_skipped_at_step';
  
  /// Initialize and load saved state
  Future<void> initialize() async {
    await _loadFromPreferences();
  }
  
  /// Load tutorial state from SharedPreferences
  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenTutorial = prefs.getBool(_keyHasSeenTutorial) ?? false;
      
      final completedAtString = prefs.getString(_keyCompletedAt);
      if (completedAtString != null) {
        _tutorialCompletedAt = DateTime.parse(completedAtString);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tutorial state: $e');
    }
  }
  
  /// Check if tutorial should be shown (first-time users only)
  bool shouldShowTutorial() {
    return !_hasSeenTutorial;
  }
  
  /// Start the tutorial
  void startTutorial() {
    _isShowingTutorial = true;
    _currentStep = 0;
    notifyListeners();
  }
  
  /// Move to next step
  void nextStep() {
    _currentStep++;
    notifyListeners();
  }
  
  /// Complete the tutorial
  Future<void> completeTutorial() async {
    _hasSeenTutorial = true;
    _isShowingTutorial = false;
    _tutorialCompletedAt = DateTime.now();
    
    await _saveToPreferences();
    notifyListeners();
    
    // Log analytics
    debugPrint('✅ Tutorial completed');
  }
  
  /// Skip the tutorial
  Future<void> skipTutorial([int? atStep]) async {
    _hasSeenTutorial = true;
    _isShowingTutorial = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenTutorial, true);
    
    if (atStep != null) {
      await prefs.setInt(_keySkippedAtStep, atStep);
    }
    
    notifyListeners();
    
    // Log analytics
    debugPrint('⏭️ Tutorial skipped at step: ${atStep ?? 'start'}');
  }
  
  /// Save tutorial state to SharedPreferences
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasSeenTutorial, _hasSeenTutorial);
      
      if (_tutorialCompletedAt != null) {
        await prefs.setString(
          _keyCompletedAt,
          _tutorialCompletedAt!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error saving tutorial state: $e');
    }
  }
  
  /// Reset tutorial state (for testing)
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasSeenTutorial);
    await prefs.remove(_keyCompletedAt);
    await prefs.remove(_keySkippedAtStep);
    
    _hasSeenTutorial = false;
    _isShowingTutorial = false;
    _currentStep = 0;
    _tutorialCompletedAt = null;
    
    notifyListeners();
    
    debugPrint('🔄 Tutorial reset');
  }
}

