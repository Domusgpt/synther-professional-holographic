/// Professional Granular Synthesis Engine
/// Implements real-time granular synthesis with grain manipulation

import 'dart:math' as math;
import 'dart:typed_data';

enum GrainEnvelopeType {
  linear,
  exponential,
  gaussian,
  triangle,
  hanning,
}

class GrainEnvelope {
  final GrainEnvelopeType type;
  final double attack;  // 0.0-1.0 (percentage of grain)
  final double release; // 0.0-1.0 (percentage of grain)

  GrainEnvelope({
    this.type = GrainEnvelopeType.hanning,
    this.attack = 0.3,
    this.release = 0.3,
  });

  /// Calculate envelope value for position in grain (0.0-1.0)
  double getValue(double position) {
    switch (type) {
      case GrainEnvelopeType.hanning:
        return 0.5 * (1.0 - math.cos(2.0 * math.pi * position));

      case GrainEnvelopeType.gaussian:
        final x = (position - 0.5) * 6.0; // -3 to +3
        return math.exp(-x * x);

      case GrainEnvelopeType.triangle:
        if (position < attack) {
          return position / attack;
        } else if (position > 1.0 - release) {
          return (1.0 - position) / release;
        } else {
          return 1.0;
        }

      case GrainEnvelopeType.exponential:
        if (position < attack) {
          return (math.exp(position / attack) - 1.0) / (math.e - 1.0);
        } else if (position > 1.0 - release) {
          final releasePos = (1.0 - position) / release;
          return (math.exp(releasePos) - 1.0) / (math.e - 1.0);
        } else {
          return 1.0;
        }

      case GrainEnvelopeType.linear:
      default:
        if (position < attack) {
          return position / attack;
        } else if (position > 1.0 - release) {
          return (1.0 - position) / release;
        } else {
          return 1.0;
        }
    }
  }
}

class Grain {
  final Float32List sourceBuffer;
  final int startPosition;
  final int grainSize;
  final double pitch;
  final double pan;
  final GrainEnvelope envelope;
  int currentPosition = 0;
  bool isActive = true;

  Grain({
    required this.sourceBuffer,
    required this.startPosition,
    required this.grainSize,
    required this.pitch,
    required this.pan,
    required this.envelope,
  });

  /// Process a single sample from this grain
  /// Returns [left, right] stereo pair
  List<double> processSample() {
    if (currentPosition >= grainSize) {
      isActive = false;
      return [0.0, 0.0];
    }

    // Get envelope position (0.0-1.0)
    final envelopePos = currentPosition / grainSize;
    final envelopeValue = envelope.getValue(envelopePos);

    // Get source sample with pitch shifting (simple time-domain method)
    final sourcePos = startPosition + (currentPosition * pitch);
    final sample = _getSampleInterpolated(sourcePos);

    // Apply envelope
    final processedSample = sample * envelopeValue;

    // Apply panning (constant power)
    final panAngle = (pan * 0.5 + 0.5) * math.pi / 2.0;
    final left = processedSample * math.cos(panAngle);
    final right = processedSample * math.sin(panAngle);

    currentPosition++;

    return [left, right];
  }

  double _getSampleInterpolated(double position) {
    if (sourceBuffer.isEmpty) return 0.0;

    final index = position.floor();
    final frac = position - index;

    final i1 = index % sourceBuffer.length;
    final i2 = (index + 1) % sourceBuffer.length;

    return sourceBuffer[i1] * (1.0 - frac) + sourceBuffer[i2] * frac;
  }
}

class GranularEngine {
  static const double sampleRate = 48000.0;
  static final math.Random _random = math.Random();

  // Source audio buffer
  Float32List sourceBuffer = Float32List(0);

  // Grain parameters
  double grainSize = 50.0;        // milliseconds
  double grainDensity = 20.0;     // grains per second
  double playheadPosition = 0.5;  // 0.0-1.0 in buffer
  double playheadSpread = 0.1;    // random variation
  double pitchVariation = 0.0;    // 0.0-2.0
  double panSpread = 0.5;         // stereo spread
  GrainEnvelope grainEnvelope = GrainEnvelope();

  // Advanced parameters
  bool sprayMode = false;         // Random grain positions
  double grainSizeVariation = 0.1; // Randomize grain size
  double densityVariation = 0.1;   // Randomize density
  double reverse = 0.0;           // 0.0-1.0 chance of reverse

  // Active grains
  final List<Grain> activeGrains = [];
  double timeSinceLastGrain = 0.0;

  GranularEngine() {
    // Initialize with a default sine wave buffer
    _generateDefaultBuffer();
  }

  void _generateDefaultBuffer() {
    const bufferSize = 48000; // 1 second at 48kHz
    sourceBuffer = Float32List(bufferSize);
    for (int i = 0; i < bufferSize; i++) {
      sourceBuffer[i] = math.sin(2.0 * math.pi * 440.0 * i / sampleRate);
    }
  }

  /// Load audio buffer for granular processing
  void loadBuffer(Float32List buffer) {
    if (buffer.isEmpty) {
      _generateDefaultBuffer();
      return;
    }
    sourceBuffer = buffer;
  }

  /// Process a single stereo sample
  List<double> processSample() {
    // Check if we should spawn a new grain
    final timePerGrain = 1.0 / grainDensity;
    final timePerSample = 1.0 / sampleRate;

    timeSinceLastGrain += timePerSample;

    if (timeSinceLastGrain >= timePerGrain) {
      _spawnGrain();
      timeSinceLastGrain -= timePerGrain;

      // Add some randomization to density
      if (densityVariation > 0.0) {
        timeSinceLastGrain += (_random.nextDouble() - 0.5) *
            densityVariation * timePerGrain;
      }
    }

    // Process all active grains
    double leftOutput = 0.0;
    double rightOutput = 0.0;

    activeGrains.removeWhere((grain) => !grain.isActive);

    for (var grain in activeGrains) {
      final sample = grain.processSample();
      leftOutput += sample[0];
      rightOutput += sample[1];
    }

    // Normalize by number of grains to prevent clipping
    final grainCount = activeGrains.length.clamp(1, 100);
    leftOutput /= math.sqrt(grainCount);
    rightOutput /= math.sqrt(grainCount);

    return [
      leftOutput.clamp(-1.0, 1.0),
      rightOutput.clamp(-1.0, 1.0),
    ];
  }

  void _spawnGrain() {
    if (sourceBuffer.isEmpty) return;

    // Calculate grain size in samples
    final grainSizeVaried = grainSize * (1.0 +
        (_random.nextDouble() - 0.5) * grainSizeVariation);
    final grainSizeSamples = (grainSizeVaried * sampleRate / 1000.0).round();

    if (grainSizeSamples <= 0) return;

    // Calculate start position
    int startPosition;
    if (sprayMode) {
      // Random position across entire buffer
      startPosition = _random.nextInt(sourceBuffer.length);
    } else {
      // Position around playhead with spread
      final spread = playheadSpread * sourceBuffer.length;
      final centerPos = playheadPosition * sourceBuffer.length;
      final randomOffset = (_random.nextDouble() - 0.5) * spread;
      startPosition = (centerPos + randomOffset).round() % sourceBuffer.length;
    }

    // Calculate pitch
    final pitchRange = pitchVariation;
    final pitch = 1.0 + (_random.nextDouble() - 0.5) * pitchRange;

    // Check for reverse
    final shouldReverse = _random.nextDouble() < reverse;
    final finalPitch = shouldReverse ? -pitch : pitch;

    // Calculate pan
    final pan = (_random.nextDouble() - 0.5) * panSpread * 2.0;

    // Create and add grain
    final grain = Grain(
      sourceBuffer: sourceBuffer,
      startPosition: startPosition,
      grainSize: grainSizeSamples,
      pitch: finalPitch,
      pan: pan.clamp(-1.0, 1.0),
      envelope: grainEnvelope,
    );

    activeGrains.add(grain);

    // Limit number of active grains for performance
    const maxGrains = 128;
    if (activeGrains.length > maxGrains) {
      activeGrains.removeAt(0);
    }
  }

  /// Set grain size in milliseconds
  void setGrainSize(double sizeMs) {
    grainSize = sizeMs.clamp(1.0, 500.0);
  }

  /// Set grain density (grains per second)
  void setGrainDensity(double density) {
    grainDensity = density.clamp(1.0, 100.0);
  }

  /// Set playhead position (0.0-1.0)
  void setPlayheadPosition(double position) {
    playheadPosition = position.clamp(0.0, 1.0);
  }

  /// Set playhead spread (0.0-1.0)
  void setPlayheadSpread(double spread) {
    playheadSpread = spread.clamp(0.0, 1.0);
  }

  /// Set pitch variation (0.0-2.0)
  void setPitchVariation(double variation) {
    pitchVariation = variation.clamp(0.0, 2.0);
  }

  /// Set pan spread (0.0-1.0)
  void setPanSpread(double spread) {
    panSpread = spread.clamp(0.0, 1.0);
  }

  /// Set spray mode (random positions)
  void setSprayMode(bool enabled) {
    sprayMode = enabled;
  }

  /// Set grain size variation (0.0-1.0)
  void setGrainSizeVariation(double variation) {
    grainSizeVariation = variation.clamp(0.0, 1.0);
  }

  /// Set density variation (0.0-1.0)
  void setDensityVariation(double variation) {
    densityVariation = variation.clamp(0.0, 1.0);
  }

  /// Set reverse probability (0.0-1.0)
  void setReverseProbability(double probability) {
    reverse = probability.clamp(0.0, 1.0);
  }

  /// Set grain envelope
  void setGrainEnvelope(GrainEnvelope envelope) {
    grainEnvelope = envelope;
  }

  /// Reset engine state
  void reset() {
    activeGrains.clear();
    timeSinceLastGrain = 0.0;
  }

  /// Get current grain count (for visualization)
  int getActiveGrainCount() {
    return activeGrains.length;
  }

  /// Get visualizer data
  Map<String, dynamic> getVisualizerData() {
    return {
      'grainCount': activeGrains.length,
      'grainSize': grainSize,
      'density': grainDensity,
      'playheadPosition': playheadPosition,
      'sprayMode': sprayMode,
    };
  }
}
