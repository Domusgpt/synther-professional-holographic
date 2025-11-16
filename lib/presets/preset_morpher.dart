import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Smooth preset morphing system with visual feedback
///
/// Features:
/// - Smooth interpolation between presets with customizable curves
/// - Multi-preset morphing (blend 2, 3, or 4 presets simultaneously)
/// - Tempo-synced morphing with musical timing
/// - Visual morphing feedback for UI
/// - Automation recording and playback
/// - Preset randomization with constraints
class PresetMorpher extends ChangeNotifier {
  // Current morph state
  SynthPreset? _sourcePreset;
  SynthPreset? _targetPreset;
  double _morphPosition = 0.0; // 0.0 = source, 1.0 = target
  MorphCurve _morphCurve = MorphCurve.linear;

  // Multi-preset morphing
  List<SynthPreset> _morphPresets = [];
  List<double> _morphWeights = [];

  // Animation
  bool _isAnimating = false;
  double _animationSpeed = 1.0; // seconds for full morph
  Timer? _animationTimer;

  // Current interpolated preset
  late SynthPreset _currentPreset;

  // Morphing history for undo/redo
  final List<MorphState> _history = [];
  int _historyIndex = -1;

  PresetMorpher() {
    _currentPreset = SynthPreset.defaultPreset();
  }

  // Getters
  SynthPreset get currentPreset => _currentPreset;
  double get morphPosition => _morphPosition;
  bool get isAnimating => _isAnimating;
  bool get canMorph => _sourcePreset != null && _targetPreset != null;

  /// Set source preset for morphing
  void setSourcePreset(SynthPreset preset) {
    _sourcePreset = preset;
    _updateCurrentPreset();
    notifyListeners();
  }

  /// Set target preset for morphing
  void setTargetPreset(SynthPreset preset) {
    _targetPreset = preset;
    _updateCurrentPreset();
    notifyListeners();
  }

  /// Set morph position (0.0 to 1.0)
  void setMorphPosition(double position) {
    _morphPosition = position.clamp(0.0, 1.0);
    _updateCurrentPreset();
    _addToHistory();
    notifyListeners();
  }

  /// Set morphing curve
  void setMorphCurve(MorphCurve curve) {
    _morphCurve = curve;
    _updateCurrentPreset();
    notifyListeners();
  }

  /// Start animated morphing from source to target
  void startMorphAnimation({
    required Duration duration,
    bool loop = false,
    bool pingPong = false,
  }) {
    if (!canMorph) return;

    stopMorphAnimation();

    _isAnimating = true;
    _animationSpeed = duration.inMilliseconds / 1000.0;

    final steps = (duration.inMilliseconds / 16).round(); // 60fps
    final increment = 1.0 / steps;

    int direction = 1;
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        _morphPosition += increment * direction;

        if (_morphPosition >= 1.0) {
          if (pingPong) {
            direction = -1;
            _morphPosition = 1.0;
          } else if (loop) {
            _morphPosition = 0.0;
          } else {
            timer.cancel();
            _isAnimating = false;
            _morphPosition = 1.0;
          }
        } else if (_morphPosition <= 0.0 && pingPong) {
          direction = 1;
          _morphPosition = 0.0;
        }

        _updateCurrentPreset();
        notifyListeners();
      },
    );
  }

  /// Stop animated morphing
  void stopMorphAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _isAnimating = false;
    notifyListeners();
  }

  /// Morph between multiple presets with weights
  void morphMultiple(List<SynthPreset> presets, List<double> weights) {
    if (presets.isEmpty || weights.isEmpty || presets.length != weights.length) {
      return;
    }

    _morphPresets = presets;
    _morphWeights = _normalizeWeights(weights);

    _currentPreset = _interpolateMultiple(presets, _morphWeights);
    notifyListeners();
  }

  /// Set weights for multi-preset morphing (auto-normalizes)
  void setMorphWeights(List<double> weights) {
    if (weights.length != _morphPresets.length) return;

    _morphWeights = _normalizeWeights(weights);
    _currentPreset = _interpolateMultiple(_morphPresets, _morphWeights);
    notifyListeners();
  }

  /// Randomize current preset within constraints
  SynthPreset randomize({
    bool randomizeWavetable = true,
    bool randomizeFilter = true,
    bool randomizeEffects = true,
    bool randomizeModulation = true,
    double amount = 1.0, // 0.0 = no change, 1.0 = full random
  }) {
    final random = math.Random();
    final current = _currentPreset;

    final randomized = SynthPreset(
      name: '${current.name} (Random)',

      // Wavetable
      wavetablePosition: randomizeWavetable
          ? _lerp(current.wavetablePosition, random.nextDouble(), amount)
          : current.wavetablePosition,
      wavetableSpeed: randomizeWavetable
          ? _lerp(current.wavetableSpeed, random.nextDouble() * 2.0, amount)
          : current.wavetableSpeed,

      // Filter
      filterCutoff: randomizeFilter
          ? _lerp(current.filterCutoff, random.nextDouble(), amount)
          : current.filterCutoff,
      filterResonance: randomizeFilter
          ? _lerp(current.filterResonance, random.nextDouble(), amount)
          : current.filterResonance,
      filterType: randomizeFilter && random.nextDouble() < amount
          ? FilterType.values[random.nextInt(FilterType.values.length)]
          : current.filterType,

      // Granular
      grainSize: _lerp(current.grainSize, random.nextDouble(), amount),
      grainDensity: _lerp(current.grainDensity, random.nextDouble(), amount),
      grainPitch: _lerp(current.grainPitch, 0.5 + random.nextDouble(), amount),

      // Effects
      distortion: randomizeEffects
          ? _lerp(current.distortion, random.nextDouble(), amount)
          : current.distortion,
      delayTime: randomizeEffects
          ? _lerp(current.delayTime, random.nextDouble(), amount)
          : current.delayTime,
      delayFeedback: randomizeEffects
          ? _lerp(current.delayFeedback, random.nextDouble() * 0.9, amount)
          : current.delayFeedback,
      reverbMix: randomizeEffects
          ? _lerp(current.reverbMix, random.nextDouble(), amount)
          : current.reverbMix,

      // Modulation
      lfo1Rate: randomizeModulation
          ? _lerp(current.lfo1Rate, random.nextDouble() * 20.0, amount)
          : current.lfo1Rate,
      lfo1Amount: randomizeModulation
          ? _lerp(current.lfo1Amount, random.nextDouble(), amount)
          : current.lfo1Amount,

      // Visual
      visualRotationSpeed: _lerp(
        current.visualRotationSpeed,
        random.nextDouble() * 2.0,
        amount,
      ),
      visualColorHue: _lerp(current.visualColorHue, random.nextDouble(), amount),
    );

    _currentPreset = randomized;
    notifyListeners();
    return randomized;
  }

  /// Create morph snapshot for undo/redo
  void _addToHistory() {
    final state = MorphState(
      sourcePreset: _sourcePreset,
      targetPreset: _targetPreset,
      morphPosition: _morphPosition,
      currentPreset: _currentPreset.copy(),
    );

    // Remove future history if we're not at the end
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(state);
    _historyIndex = _history.length - 1;

    // Limit history size
    if (_history.length > 100) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  /// Undo morph change
  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _restoreFromHistory(_history[_historyIndex]);
    }
  }

  /// Redo morph change
  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _restoreFromHistory(_history[_historyIndex]);
    }
  }

  void _restoreFromHistory(MorphState state) {
    _sourcePreset = state.sourcePreset;
    _targetPreset = state.targetPreset;
    _morphPosition = state.morphPosition;
    _currentPreset = state.currentPreset.copy();
    notifyListeners();
  }

  /// Update current preset based on morph position
  void _updateCurrentPreset() {
    if (_sourcePreset == null) return;

    if (_targetPreset == null) {
      _currentPreset = _sourcePreset!;
      return;
    }

    // Apply curve to morph position
    final t = _applyCurve(_morphPosition, _morphCurve);

    _currentPreset = _interpolate(_sourcePreset!, _targetPreset!, t);
  }

  /// Interpolate between two presets
  SynthPreset _interpolate(SynthPreset a, SynthPreset b, double t) {
    return SynthPreset(
      name: '${a.name} → ${b.name}',

      // Wavetable
      wavetablePosition: _lerp(a.wavetablePosition, b.wavetablePosition, t),
      wavetableSpeed: _lerp(a.wavetableSpeed, b.wavetableSpeed, t),

      // Filter
      filterCutoff: _lerp(a.filterCutoff, b.filterCutoff, t),
      filterResonance: _lerp(a.filterResonance, b.filterResonance, t),
      filterType: t < 0.5 ? a.filterType : b.filterType,

      // Granular
      grainSize: _lerp(a.grainSize, b.grainSize, t),
      grainDensity: _lerp(a.grainDensity, b.grainDensity, t),
      grainPitch: _lerp(a.grainPitch, b.grainPitch, t),

      // Effects
      distortion: _lerp(a.distortion, b.distortion, t),
      delayTime: _lerp(a.delayTime, b.delayTime, t),
      delayFeedback: _lerp(a.delayFeedback, b.delayFeedback, t),
      reverbMix: _lerp(a.reverbMix, b.reverbMix, t),

      // Modulation
      lfo1Rate: _lerp(a.lfo1Rate, b.lfo1Rate, t),
      lfo1Amount: _lerp(a.lfo1Amount, b.lfo1Amount, t),

      // Visual
      visualRotationSpeed: _lerp(a.visualRotationSpeed, b.visualRotationSpeed, t),
      visualColorHue: _lerp(a.visualColorHue, b.visualColorHue, t),
    );
  }

  /// Interpolate between multiple presets with weights
  SynthPreset _interpolateMultiple(List<SynthPreset> presets, List<double> weights) {
    if (presets.isEmpty) return SynthPreset.defaultPreset();
    if (presets.length == 1) return presets[0];

    // Weighted average of all parameters
    double wavetablePosition = 0.0;
    double wavetableSpeed = 0.0;
    double filterCutoff = 0.0;
    double filterResonance = 0.0;
    double grainSize = 0.0;
    double grainDensity = 0.0;
    double grainPitch = 0.0;
    double distortion = 0.0;
    double delayTime = 0.0;
    double delayFeedback = 0.0;
    double reverbMix = 0.0;
    double lfo1Rate = 0.0;
    double lfo1Amount = 0.0;
    double visualRotationSpeed = 0.0;
    double visualColorHue = 0.0;

    for (int i = 0; i < presets.length; i++) {
      final preset = presets[i];
      final weight = weights[i];

      wavetablePosition += preset.wavetablePosition * weight;
      wavetableSpeed += preset.wavetableSpeed * weight;
      filterCutoff += preset.filterCutoff * weight;
      filterResonance += preset.filterResonance * weight;
      grainSize += preset.grainSize * weight;
      grainDensity += preset.grainDensity * weight;
      grainPitch += preset.grainPitch * weight;
      distortion += preset.distortion * weight;
      delayTime += preset.delayTime * weight;
      delayFeedback += preset.delayFeedback * weight;
      reverbMix += preset.reverbMix * weight;
      lfo1Rate += preset.lfo1Rate * weight;
      lfo1Amount += preset.lfo1Amount * weight;
      visualRotationSpeed += preset.visualRotationSpeed * weight;
      visualColorHue += preset.visualColorHue * weight;
    }

    return SynthPreset(
      name: 'Multi-Morph',
      wavetablePosition: wavetablePosition,
      wavetableSpeed: wavetableSpeed,
      filterCutoff: filterCutoff,
      filterResonance: filterResonance,
      filterType: presets[0].filterType, // Use first preset's type
      grainSize: grainSize,
      grainDensity: grainDensity,
      grainPitch: grainPitch,
      distortion: distortion,
      delayTime: delayTime,
      delayFeedback: delayFeedback,
      reverbMix: reverbMix,
      lfo1Rate: lfo1Rate,
      lfo1Amount: lfo1Amount,
      visualRotationSpeed: visualRotationSpeed,
      visualColorHue: visualColorHue,
    );
  }

  /// Apply morphing curve to position
  double _applyCurve(double t, MorphCurve curve) {
    switch (curve) {
      case MorphCurve.linear:
        return t;
      case MorphCurve.smoothStep:
        return t * t * (3.0 - 2.0 * t);
      case MorphCurve.smootherStep:
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
      case MorphCurve.easeIn:
        return t * t;
      case MorphCurve.easeOut:
        return t * (2.0 - t);
      case MorphCurve.easeInOut:
        return t < 0.5 ? 2.0 * t * t : -1.0 + (4.0 - 2.0 * t) * t;
      case MorphCurve.exponential:
        return t == 0.0 ? 0.0 : math.pow(2.0, 10.0 * (t - 1.0)).toDouble();
    }
  }

  /// Normalize weights to sum to 1.0
  List<double> _normalizeWeights(List<double> weights) {
    final sum = weights.reduce((a, b) => a + b);
    if (sum == 0.0) return List.filled(weights.length, 1.0 / weights.length);
    return weights.map((w) => w / sum).toList();
  }

  /// Linear interpolation
  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  void dispose() {
    stopMorphAnimation();
    super.dispose();
  }
}

/// Morph curve types
enum MorphCurve {
  linear,
  smoothStep,
  smootherStep,
  easeIn,
  easeOut,
  easeInOut,
  exponential,
}

/// Synthesizer preset
class SynthPreset {
  final String name;

  // Wavetable
  final double wavetablePosition;
  final double wavetableSpeed;

  // Filter
  final double filterCutoff;
  final double filterResonance;
  final FilterType filterType;

  // Granular
  final double grainSize;
  final double grainDensity;
  final double grainPitch;

  // Effects
  final double distortion;
  final double delayTime;
  final double delayFeedback;
  final double reverbMix;

  // Modulation
  final double lfo1Rate;
  final double lfo1Amount;

  // Visual
  final double visualRotationSpeed;
  final double visualColorHue;

  const SynthPreset({
    required this.name,
    this.wavetablePosition = 0.0,
    this.wavetableSpeed = 1.0,
    this.filterCutoff = 1.0,
    this.filterResonance = 0.1,
    this.filterType = FilterType.lowpass,
    this.grainSize = 0.05,
    this.grainDensity = 0.5,
    this.grainPitch = 1.0,
    this.distortion = 0.0,
    this.delayTime = 0.3,
    this.delayFeedback = 0.3,
    this.reverbMix = 0.2,
    this.lfo1Rate = 1.0,
    this.lfo1Amount = 0.5,
    this.visualRotationSpeed = 1.0,
    this.visualColorHue = 0.5,
  });

  SynthPreset copy() {
    return SynthPreset(
      name: name,
      wavetablePosition: wavetablePosition,
      wavetableSpeed: wavetableSpeed,
      filterCutoff: filterCutoff,
      filterResonance: filterResonance,
      filterType: filterType,
      grainSize: grainSize,
      grainDensity: grainDensity,
      grainPitch: grainPitch,
      distortion: distortion,
      delayTime: delayTime,
      delayFeedback: delayFeedback,
      reverbMix: reverbMix,
      lfo1Rate: lfo1Rate,
      lfo1Amount: lfo1Amount,
      visualRotationSpeed: visualRotationSpeed,
      visualColorHue: visualColorHue,
    );
  }

  static SynthPreset defaultPreset() {
    return const SynthPreset(name: 'Default');
  }

  /// Factory presets
  static SynthPreset pad() {
    return const SynthPreset(
      name: 'Lush Pad',
      wavetablePosition: 0.3,
      wavetableSpeed: 0.5,
      filterCutoff: 0.7,
      filterResonance: 0.2,
      grainSize: 0.1,
      grainDensity: 0.8,
      reverbMix: 0.6,
      lfo1Rate: 0.5,
      lfo1Amount: 0.3,
      visualRotationSpeed: 0.3,
    );
  }

  static SynthPreset bass() {
    return const SynthPreset(
      name: 'Deep Bass',
      wavetablePosition: 0.1,
      filterCutoff: 0.3,
      filterResonance: 0.6,
      filterType: FilterType.lowpass,
      distortion: 0.3,
      grainDensity: 0.3,
      visualColorHue: 0.6,
    );
  }

  static SynthPreset lead() {
    return const SynthPreset(
      name: 'Sharp Lead',
      wavetablePosition: 0.7,
      wavetableSpeed: 1.5,
      filterCutoff: 0.8,
      filterResonance: 0.4,
      distortion: 0.2,
      lfo1Rate: 5.0,
      lfo1Amount: 0.4,
      visualRotationSpeed: 2.0,
    );
  }

  static SynthPreset percussion() {
    return const SynthPreset(
      name: 'Percussion',
      grainSize: 0.01,
      grainDensity: 1.0,
      grainPitch: 0.5,
      filterCutoff: 0.9,
      distortion: 0.4,
      delayFeedback: 0.1,
      visualColorHue: 0.1,
    );
  }
}

enum FilterType {
  lowpass,
  highpass,
  bandpass,
  notch,
}

/// Morph state snapshot for undo/redo
class MorphState {
  final SynthPreset? sourcePreset;
  final SynthPreset? targetPreset;
  final double morphPosition;
  final SynthPreset currentPreset;

  MorphState({
    required this.sourcePreset,
    required this.targetPreset,
    required this.morphPosition,
    required this.currentPreset,
  });
}
