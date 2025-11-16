/// Smart Audio-Visual Mapper
/// Intelligently maps audio features to visual parameters with musical awareness

import 'dart:math' as math;
import 'intelligent_audio_analyzer.dart';

/// Visual parameters for vib34d visualization
class VisualParameters {
  // 4D rotation speeds (influenced by musical content)
  double rot4dXWSpeed = 0.0;
  double rot4dYWSpeed = 0.0;
  double rot4dZWSpeed = 0.0;

  // Morph intensity (harmonic content)
  double morphIntensity = 0.5;

  // Color parameters
  double hue = 0.5;           // Color hue (0-1)
  double saturation = 0.8;    // Color saturation
  double brightness = 0.7;    // Overall brightness

  // Visual effects
  double bloomIntensity = 0.5;
  double glowAmount = 0.5;
  double particleDensity = 0.5;
  double trailLength = 0.5;

  // Geometric complexity
  double geometricComplexity = 0.5;
  double layerVisibility = 1.0;

  // Energy-based
  double scaleModulation = 1.0;
  double rotationEnergy = 0.5;

  VisualParameters();

  Map<String, double> toMap() {
    return {
      'rot4dXWSpeed': rot4dXWSpeed,
      'rot4dYWSpeed': rot4dYWSpeed,
      'rot4dZWSpeed': rot4dZWSpeed,
      'morphIntensity': morphIntensity,
      'hue': hue,
      'saturation': saturation,
      'brightness': brightness,
      'bloomIntensity': bloomIntensity,
      'glowAmount': glowAmount,
      'particleDensity': particleDensity,
      'trailLength': trailLength,
      'geometricComplexity': geometricComplexity,
      'layerVisibility': layerVisibility,
      'scaleModulation': scaleModulation,
      'rotationEnergy': rotationEnergy,
    };
  }
}

/// Mapping modes for different musical contexts
enum MappingMode {
  energetic,      // Fast, rhythmic music
  ambient,        // Slow, atmospheric music
  harmonic,       // Tonal, melodic music
  percussive,     // Drums, rhythmic elements
  adaptive,       // Automatically adapts to content
}

/// Smart audio-visual mapper with musical intelligence
class SmartAudioVisualMapper {
  MappingMode mode = MappingMode.adaptive;
  final VisualParameters visualParams = VisualParameters();

  // Smoothing for visual continuity
  double _smoothingFactor = 0.15;

  // Previous values for smoothing
  final Map<String, double> _previousValues = {};

  // Auto-adaptation
  double _energyThreshold = 0.5;
  double _harmonicityThreshold = 0.6;

  /// Map audio features to visual parameters with musical intelligence
  VisualParameters map(AudioFeatures audio) {
    // Auto-detect mode if adaptive
    if (mode == MappingMode.adaptive) {
      _detectMode(audio);
    }

    // Apply mode-specific mapping
    switch (mode) {
      case MappingMode.energetic:
        _mapEnergetic(audio);
        break;
      case MappingMode.ambient:
        _mapAmbient(audio);
        break;
      case MappingMode.harmonic:
        _mapHarmonic(audio);
        break;
      case MappingMode.percussive:
        _mapPercussive(audio);
        break;
      case MappingMode.adaptive:
        _mapAdaptive(audio);
        break;
    }

    // Apply smoothing for visual continuity
    _applySmoothing();

    return visualParams;
  }

  void _detectMode(AudioFeatures audio) {
    // Analyze musical content and choose appropriate mode
    final isEnergetic = audio.rhythmicEnergy > _energyThreshold;
    final isHarmonic = audio.harmonicity > _harmonicityThreshold;
    final isPercussive = audio.onsetStrength > 0.5 && audio.spectralFlatness > 0.3;
    final isAmbient = audio.rms < 0.3 && audio.attackTime < 0.2;

    if (isPercussive) {
      mode = MappingMode.percussive;
    } else if (isEnergetic) {
      mode = MappingMode.energetic;
    } else if (isHarmonic) {
      mode = MappingMode.harmonic;
    } else if (isAmbient) {
      mode = MappingMode.ambient;
    }
  }

  void _mapEnergetic(AudioFeatures audio) {
    // Fast, rhythmic music: emphasis on movement and rhythm

    // 4D rotations driven by rhythmic energy
    visualParams.rot4dXWSpeed = _smooth('xw', audio.rhythmicEnergy * 2.0);
    visualParams.rot4dYWSpeed = _smooth('yw', audio.onsetStrength * 1.5);
    visualParams.rot4dZWSpeed = _smooth('zw', audio.bandEnergies[2] * 1.8); // Mid frequencies

    // Morph intensity follows spectral flux (changes)
    visualParams.morphIntensity = _smooth('morph', audio.spectralFlux * 0.8 + 0.2);

    // Color driven by spectral centroid (brightness of sound)
    visualParams.hue = _smooth('hue', audio.spectralCentroid);
    visualParams.saturation = 0.9; // High saturation for energetic
    visualParams.brightness = _smooth('brightness', audio.rms * 0.7 + 0.3);

    // Strong visual effects
    visualParams.bloomIntensity = _smooth('bloom', audio.peakAmplitude);
    visualParams.glowAmount = _smooth('glow', audio.rms * 0.8 + 0.2);
    visualParams.particleDensity = _smooth('particles', audio.rhythmicEnergy);
    visualParams.trailLength = 0.7; // Long trails for motion

    // High complexity
    visualParams.geometricComplexity = 0.8;
    visualParams.rotationEnergy = audio.rhythmicEnergy;
  }

  void _mapAmbient(AudioFeatures audio) {
    // Slow, atmospheric music: emphasis on smooth evolution

    // Slow, smooth 4D rotations
    visualParams.rot4dXWSpeed = _smooth('xw', audio.lowEnergy * 0.3);
    visualParams.rot4dYWSpeed = _smooth('yw', audio.spectralCentroid * 0.2);
    visualParams.rot4dZWSpeed = _smooth('zw', audio.midEnergy * 0.25);

    // Gentle morphing
    visualParams.morphIntensity = _smooth('morph', audio.harmonicity * 0.6 + 0.2);

    // Soft, evolving colors
    visualParams.hue = _smooth('hue', audio.spectralCentroid * 0.5 + 0.3);
    visualParams.saturation = 0.6; // Lower saturation for ambient
    visualParams.brightness = _smooth('brightness', audio.rms * 0.5 + 0.3);

    // Soft visual effects
    visualParams.bloomIntensity = _smooth('bloom', audio.harmonicity * 0.6);
    visualParams.glowAmount = _smooth('glow', 0.5 + audio.sustainLevel * 0.3);
    visualParams.particleDensity = _smooth('particles', audio.rms * 0.3);
    visualParams.trailLength = 0.9; // Very long trails for smooth motion

    // Moderate complexity
    visualParams.geometricComplexity = 0.5;
    visualParams.rotationEnergy = audio.rms * 0.5;
  }

  void _mapHarmonic(AudioFeatures audio) {
    // Tonal, melodic music: emphasis on harmony and structure

    // Rotations follow harmonic structure
    visualParams.rot4dXWSpeed = _smooth('xw', audio.harmonicity * 0.8);
    visualParams.rot4dYWSpeed = _smooth('yw', audio.spectralCentroid * 0.7);
    visualParams.rot4dZWSpeed = _smooth('zw', (1.0 - audio.spectralFlatness) * 0.6);

    // Morph based on harmonic richness
    visualParams.morphIntensity = _smooth('morph', audio.harmonicity * 0.7 + 0.2);

    // Color follows pitch/brightness
    visualParams.hue = _smooth('hue', audio.spectralCentroid * 0.8);
    visualParams.saturation = 0.8;
    visualParams.brightness = _smooth('brightness', audio.rms * 0.6 + 0.4);

    // Moderate, musical effects
    visualParams.bloomIntensity = _smooth('bloom', audio.harmonicity * 0.7);
    visualParams.glowAmount = _smooth('glow', audio.sustainLevel * 0.6 + 0.3);
    visualParams.particleDensity = _smooth('particles', audio.harmonicity * 0.4);
    visualParams.trailLength = 0.5;

    // High complexity for rich harmonics
    visualParams.geometricComplexity = 0.7;
    visualParams.rotationEnergy = audio.harmonicity * 0.7;
  }

  void _mapPercussive(AudioFeatures audio) {
    // Drums, rhythmic elements: emphasis on attacks and transients

    // Sharp, responsive rotations
    visualParams.rot4dXWSpeed = _smooth('xw', audio.onsetStrength * 2.5, smoothness: 0.3);
    visualParams.rot4dYWSpeed = _smooth('yw', audio.highEnergy * 2.0, smoothness: 0.3);
    visualParams.rot4dZWSpeed = _smooth('zw', audio.lowEnergy * 1.5, smoothness: 0.3);

    // Morph on hits
    visualParams.morphIntensity = _smooth('morph', audio.onsetStrength * 0.8, smoothness: 0.2);

    // Color based on frequency content
    final bassHit = audio.lowEnergy > audio.midEnergy;
    visualParams.hue = _smooth('hue', bassHit ? 0.6 : 0.1); // Bass = blue, treble = red
    visualParams.saturation = 0.95; // High saturation
    visualParams.brightness = _smooth('brightness', audio.peakAmplitude, smoothness: 0.2);

    // Explosive visual effects on attacks
    visualParams.bloomIntensity = _smooth('bloom', audio.attackTime, smoothness: 0.2);
    visualParams.glowAmount = _smooth('glow', audio.onsetStrength * 0.9, smoothness: 0.2);
    visualParams.particleDensity = _smooth('particles', audio.onsetStrength * 0.8);
    visualParams.trailLength = 0.3; // Short trails for crisp transients

    // Variable complexity based on spectral content
    visualParams.geometricComplexity = _smooth('complexity', audio.spectralFlatness);
    visualParams.rotationEnergy = audio.onsetStrength;

    // Scale pulsing on hits
    visualParams.scaleModulation = 1.0 + audio.attackTime * 0.3;
  }

  void _mapAdaptive(AudioFeatures audio) {
    // Blend multiple mapping strategies based on content

    final energyWeight = audio.rhythmicEnergy.clamp(0.0, 1.0);
    final harmonicWeight = audio.harmonicity.clamp(0.0, 1.0);
    final percussiveWeight = audio.onsetStrength.clamp(0.0, 1.0);
    final ambientWeight = (1.0 - audio.rms).clamp(0.0, 1.0);

    // Normalize weights
    final totalWeight = energyWeight + harmonicWeight + percussiveWeight + ambientWeight;
    final normEnergy = energyWeight / totalWeight;
    final normHarmonic = harmonicWeight / totalWeight;
    final normPercussive = percussiveWeight / totalWeight;
    final normAmbient = ambientWeight / totalWeight;

    // Blend rotation speeds
    visualParams.rot4dXWSpeed = _smooth('xw',
      normEnergy * audio.rhythmicEnergy * 2.0 +
      normHarmonic * audio.harmonicity * 0.8 +
      normPercussive * audio.onsetStrength * 2.5 +
      normAmbient * audio.lowEnergy * 0.3
    );

    visualParams.rot4dYWSpeed = _smooth('yw',
      normEnergy * audio.onsetStrength * 1.5 +
      normHarmonic * audio.spectralCentroid * 0.7 +
      normPercussive * audio.highEnergy * 2.0 +
      normAmbient * audio.spectralCentroid * 0.2
    );

    visualParams.rot4dZWSpeed = _smooth('zw',
      normEnergy * audio.bandEnergies[2] * 1.8 +
      normHarmonic * (1.0 - audio.spectralFlatness) * 0.6 +
      normPercussive * audio.lowEnergy * 1.5 +
      normAmbient * audio.midEnergy * 0.25
    );

    // Blend morph intensity
    visualParams.morphIntensity = _smooth('morph',
      normEnergy * (audio.spectralFlux * 0.8 + 0.2) +
      normHarmonic * (audio.harmonicity * 0.7 + 0.2) +
      normPercussive * (audio.onsetStrength * 0.8) +
      normAmbient * (audio.harmonicity * 0.6 + 0.2)
    );

    // Adaptive color
    visualParams.hue = _smooth('hue', audio.spectralCentroid * 0.7);
    visualParams.saturation = 0.7 + normEnergy * 0.2;
    visualParams.brightness = _smooth('brightness', audio.rms * 0.6 + 0.3);

    // Adaptive effects
    visualParams.bloomIntensity = _smooth('bloom', audio.peakAmplitude * 0.8);
    visualParams.glowAmount = _smooth('glow', 0.4 + audio.rms * 0.4);
    visualParams.particleDensity = _smooth('particles', audio.rhythmicEnergy * 0.6);
    visualParams.trailLength = 0.5 + normAmbient * 0.4;

    visualParams.geometricComplexity = 0.5 + normHarmonic * 0.3;
    visualParams.rotationEnergy = audio.rms * 0.8;
  }

  double _smooth(String key, double value, {double? smoothness}) {
    final alpha = smoothness ?? _smoothingFactor;
    final previous = _previousValues[key] ?? value;
    final smoothed = previous * (1.0 - alpha) + value * alpha;
    _previousValues[key] = smoothed;
    return smoothed;
  }

  void _applySmoothing() {
    // Additional smoothing for visual continuity
    // Already done in _smooth()
  }

  /// Set mapping mode
  void setMode(MappingMode newMode) {
    mode = newMode;
  }

  /// Set smoothing factor (0.0 = no smoothing, 1.0 = instant response)
  void setSmoothingFactor(double factor) {
    _smoothingFactor = factor.clamp(0.0, 1.0);
  }

  /// Reset mapper state
  void reset() {
    _previousValues.clear();
  }

  /// Get current mode as string
  String getModeString() {
    return mode.name.toUpperCase();
  }
}

/// Musical scale detection for intelligent color mapping
class MusicalScaleDetector {
  /// Detect if audio is major or minor based on spectral content
  static bool isMajor(AudioFeatures audio) {
    // Simplified: major tends to have brighter spectrum
    return audio.spectralCentroid > 0.5;
  }

  /// Get suggested color hue based on musical key (conceptual)
  static double getKeyColor(AudioFeatures audio) {
    // Map spectral centroid to color wheel
    // Low frequencies = warm colors (red/orange)
    // High frequencies = cool colors (blue/purple)
    return audio.spectralCentroid;
  }
}
