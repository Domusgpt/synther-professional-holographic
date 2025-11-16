/// Unified Application State Management
/// Coordinates synth engine, visualization, and UI state

import 'package:flutter/foundation.dart';
import '../core/enhanced_synth_engine.dart';
import '../visualization/vib34d_sdk_wrapper.dart';
import '../visualization/quaternion_sensor_bridge.dart';
import '../audio/smart_audio_visual_mapper.dart';

/// Main application state
class SynthAppState extends ChangeNotifier {
  // Core components
  late EnhancedSynthEngine synthEngine;
  late Vib34dSDKWrapper visualizer;
  late QuaternionSensorBridge sensorBridge;

  // State flags
  bool _isInitialized = false;
  bool _isVisualizerReady = false;
  bool _isSensorsActive = false;

  // UI state
  bool showModulationMatrix = false;
  bool showVisualizer = true;
  bool showAudioAnalysis = false;  // Phase 2: Show audio features
  VisualizationEngine currentVisualizerEngine = VisualizationEngine.polychora;
  String currentPreset = 'Init';

  // Phase 2: Audio-visual mapping state
  bool useIntelligentMapping = true;  // Use intelligent audio-reactive mapping
  MappingMode currentMappingMode = MappingMode.adaptive;

  // Performance monitoring
  double audioLatency = 0.0;
  double visualizerFps = 60.0;
  int activeVoiceCount = 0;

  SynthAppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🚀 Initializing SynthAppState...');

    // Initialize synth engine
    synthEngine = EnhancedSynthEngine();

    // Set up parameter update callback
    synthEngine.onParameterUpdate = _onParameterUpdate;
    synthEngine.onAudioAnalysis = _onAudioAnalysis;

    // Initialize visualizer
    visualizer = Vib34dSDKWrapper();
    visualizer.onInitialized = _onVisualizerInitialized;
    visualizer.onError = _onVisualizerError;

    // Initialize sensor bridge
    sensorBridge = QuaternionSensorBridge();
    sensorBridge.onOrientationUpdate = _onOrientationUpdate;

    _isInitialized = true;
    debugPrint('✅ SynthAppState initialized');
    notifyListeners();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize visualizer (call after UI is ready)
  Future<void> initializeVisualizer() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Cannot initialize visualizer: app state not ready');
      return;
    }

    try {
      await visualizer.initialize();
      debugPrint('✅ Visualizer initialized');
    } catch (e) {
      debugPrint('❌ Visualizer initialization failed: $e');
    }
  }

  /// Start device sensors for quaternion tracking
  Future<void> startSensors() async {
    if (_isSensorsActive) return;

    try {
      await sensorBridge.start();
      _isSensorsActive = true;
      debugPrint('✅ Sensors started');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to start sensors: $e');
    }
  }

  /// Stop device sensors
  void stopSensors() {
    if (!_isSensorsActive) return;

    sensorBridge.stop();
    _isSensorsActive = false;
    debugPrint('🛑 Sensors stopped');
    notifyListeners();
  }

  // ============================================================
  // CALLBACKS
  // ============================================================

  void _onParameterUpdate(Map<String, double> params) {
    // Phase 2: Forward intelligent or manual parameters to visualizer
    if (_isVisualizerReady) {
      final visualParams = useIntelligentMapping
          ? synthEngine.getIntelligentVisualParameters()
          : synthEngine.getVisualizerParameters();
      visualizer.updateAudioParameters(visualParams);
    }
  }

  void _onAudioAnalysis(AudioAnalysis analysis) {
    // Update UI with audio analysis data
    activeVoiceCount = synthEngine.getActiveVoiceCount();
    // Could update visualizer with FFT data here
  }

  void _onVisualizerInitialized() {
    _isVisualizerReady = true;
    debugPrint('✅ Visualizer ready');
    notifyListeners();
  }

  void _onVisualizerError(String error) {
    debugPrint('❌ Visualizer error: $error');
  }

  void _onOrientationUpdate(quaternion) {
    // Forward quaternion to visualizer
    if (_isVisualizerReady) {
      visualizer.updateQuaternion(quaternion);
    }
  }

  // ============================================================
  // NOTE CONTROL
  // ============================================================

  /// Play a note
  void noteOn(int midiNote, {double velocity = 0.8}) {
    synthEngine.noteOn(midiNote, velocity);
    notifyListeners();
  }

  /// Stop a note
  void noteOff(int midiNote) {
    synthEngine.noteOff(midiNote);
    notifyListeners();
  }

  /// Stop all notes
  void allNotesOff() {
    synthEngine.allNotesOff();
    notifyListeners();
  }

  // ============================================================
  // PARAMETER CONTROL
  // ============================================================

  /// Set master volume
  void setMasterVolume(double value) {
    synthEngine.setMasterVolume(value);
    notifyListeners();
  }

  /// Set filter cutoff
  void setFilterCutoff(double value) {
    synthEngine.setFilterCutoff(value);
    notifyListeners();
  }

  /// Set filter resonance
  void setFilterResonance(double value) {
    synthEngine.setFilterResonance(value);
    notifyListeners();
  }

  /// Set reverb mix
  void setReverbMix(double value) {
    synthEngine.setReverbMix(value);
    notifyListeners();
  }

  /// Set wavetable mix
  void setWavetableMix(double value) {
    synthEngine.setWavetableMix(value);
    notifyListeners();
  }

  /// Set granular mix
  void setGranularMix(double value) {
    synthEngine.setGranularMix(value);
    notifyListeners();
  }

  /// Set XY pad position
  void setXYPad(double x, double y) {
    synthEngine.setXYPad(x, y);
    notifyListeners();
  }

  // ============================================================
  // VISUALIZATION CONTROL
  // ============================================================

  /// Switch visualization engine
  Future<void> switchVisualizationEngine(VisualizationEngine engine) async {
    currentVisualizerEngine = engine;
    if (_isVisualizerReady) {
      await visualizer.switchEngine(engine);
    }
    notifyListeners();
  }

  /// Apply visualizer preset
  Future<void> applyVisualizerPreset(String presetName) async {
    final preset = VisualizerPresets.getPreset(presetName);
    if (preset != null && _isVisualizerReady) {
      await visualizer.applyPreset(presetName, preset);

      // Switch engine if preset specifies one
      if (preset.containsKey('engine')) {
        await switchVisualizationEngine(preset['engine'] as VisualizationEngine);
      }
    }
    notifyListeners();
  }

  /// Toggle visualizer visibility
  void toggleVisualizer() {
    showVisualizer = !showVisualizer;
    notifyListeners();
  }

  /// Toggle modulation matrix visibility
  void toggleModulationMatrix() {
    showModulationMatrix = !showModulationMatrix;
    notifyListeners();
  }

  /// Phase 2: Toggle audio analysis display
  void toggleAudioAnalysis() {
    showAudioAnalysis = !showAudioAnalysis;
    notifyListeners();
  }

  /// Phase 2: Toggle intelligent mapping
  void toggleIntelligentMapping() {
    useIntelligentMapping = !useIntelligentMapping;
    debugPrint('🎨 Intelligent mapping: ${useIntelligentMapping ? "ON" : "OFF"}');
    notifyListeners();
  }

  /// Phase 2: Set mapping mode
  void setMappingMode(MappingMode mode) {
    currentMappingMode = mode;
    synthEngine.setMappingMode(mode);
    notifyListeners();
  }

  /// Phase 2: Control effects
  void setDistortionAmount(double value) {
    synthEngine.setDistortionAmount(value);
    notifyListeners();
  }

  void setDelayTime(double value) {
    synthEngine.setDelayTime(value);
    notifyListeners();
  }

  void setDelayFeedback(double value) {
    synthEngine.setDelayFeedback(value);
    notifyListeners();
  }

  void toggleEffect(String effectName, bool enabled) {
    synthEngine.toggleEffect(effectName, enabled);
    notifyListeners();
  }

  // ============================================================
  // PRESET MANAGEMENT
  // ============================================================

  /// Load synth preset
  void loadPreset(String name, Map<String, dynamic> preset) {
    synthEngine.loadPreset(preset);
    currentPreset = name;
    debugPrint('✅ Loaded preset: $name');
    notifyListeners();
  }

  /// Save current state as preset
  Map<String, dynamic> saveCurrentPreset() {
    return synthEngine.getCurrentPreset();
  }

  // ============================================================
  // DEMO PRESETS
  // ============================================================

  static const Map<String, Map<String, dynamic>> demoPresets = {
    'Init': {
      'masterVolume': 0.7,
      'filterCutoff': 1000.0,
      'filterResonance': 0.5,
      'reverbMix': 0.2,
      'wavetableMix': 1.0,
      'granularMix': 0.0,
      'wavetableIndex': 0,
    },
    'Warm Pad': {
      'masterVolume': 0.6,
      'filterCutoff': 800.0,
      'filterResonance': 0.3,
      'reverbMix': 0.5,
      'wavetableMix': 1.0,
      'granularMix': 0.0,
      'wavetableIndex': 4, // Harmonic Morph
    },
    'Granular Texture': {
      'masterVolume': 0.7,
      'filterCutoff': 2000.0,
      'filterResonance': 0.4,
      'reverbMix': 0.6,
      'wavetableMix': 0.2,
      'granularMix': 0.8,
      'wavetableIndex': 5, // Additive
    },
    'Bright Lead': {
      'masterVolume': 0.8,
      'filterCutoff': 5000.0,
      'filterResonance': 0.7,
      'reverbMix': 0.3,
      'wavetableMix': 1.0,
      'granularMix': 0.0,
      'wavetableIndex': 1, // Saw
    },
    'Vocal Formant': {
      'masterVolume': 0.7,
      'filterCutoff': 1500.0,
      'filterResonance': 0.6,
      'reverbMix': 0.4,
      'wavetableMix': 1.0,
      'granularMix': 0.0,
      'wavetableIndex': 7, // Vocal Formant
    },
  };

  /// Load a demo preset
  void loadDemoPreset(String name) {
    final preset = demoPresets[name];
    if (preset != null) {
      loadPreset(name, preset);
    }
  }

  /// Get list of demo preset names
  List<String> getDemoPresetNames() {
    return demoPresets.keys.toList();
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get isInitialized => _isInitialized;
  bool get isVisualizerReady => _isVisualizerReady;
  bool get isSensorsActive => _isSensorsActive;

  /// Get status summary for debugging
  Map<String, dynamic> getStatusSummary() {
    return {
      'initialized': _isInitialized,
      'visualizerReady': _isVisualizerReady,
      'sensorsActive': _isSensorsActive,
      'activeVoices': activeVoiceCount,
      'currentPreset': currentPreset,
      'visualizerEngine': currentVisualizerEngine.name,
    };
  }

  @override
  void dispose() {
    stopSensors();
    synthEngine.dispose();
    sensorBridge.dispose();
    visualizer.dispose();
    super.dispose();
  }
}
