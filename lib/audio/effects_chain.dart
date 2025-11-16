/// Professional Effects Chain
/// Implements high-quality audio effects with proper DSP

import 'dart:math' as math;

/// Filter types
enum FilterType {
  lowpass12,
  lowpass24,
  highpass12,
  highpass24,
  bandpass,
  notch,
}

/// Biquad filter for professional filtering
class BiquadFilter {
  FilterType type = FilterType.lowpass24;
  double cutoff = 1000.0;
  double resonance = 0.7;
  double sampleRate = 48000.0;

  // Biquad coefficients
  double b0 = 1.0, b1 = 0.0, b2 = 0.0;
  double a1 = 0.0, a2 = 0.0;

  // State variables
  double x1 = 0.0, x2 = 0.0;  // Input history
  double y1 = 0.0, y2 = 0.0;  // Output history

  // For 24dB filters (two stages)
  BiquadFilter? _secondStage;

  BiquadFilter({
    this.type = FilterType.lowpass24,
    this.cutoff = 1000.0,
    this.resonance = 0.7,
    this.sampleRate = 48000.0,
  }) {
    if (type == FilterType.lowpass24 || type == FilterType.highpass24) {
      _secondStage = BiquadFilter(
        type: type == FilterType.lowpass24 ? FilterType.lowpass12 : FilterType.highpass12,
        cutoff: cutoff,
        resonance: resonance,
        sampleRate: sampleRate,
      );
    }
    _calculateCoefficients();
  }

  void _calculateCoefficients() {
    final freq = (cutoff / sampleRate).clamp(0.0, 0.5);
    final omega = 2.0 * math.pi * freq;
    final sn = math.sin(omega);
    final cs = math.cos(omega);
    final q = resonance.clamp(0.1, 10.0);
    final alpha = sn / (2.0 * q);

    switch (type) {
      case FilterType.lowpass12:
      case FilterType.lowpass24:
        b0 = (1.0 - cs) / 2.0;
        b1 = 1.0 - cs;
        b2 = (1.0 - cs) / 2.0;
        final a0 = 1.0 + alpha;
        a1 = -2.0 * cs / a0;
        a2 = (1.0 - alpha) / a0;
        b0 /= a0;
        b1 /= a0;
        b2 /= a0;
        break;

      case FilterType.highpass12:
      case FilterType.highpass24:
        b0 = (1.0 + cs) / 2.0;
        b1 = -(1.0 + cs);
        b2 = (1.0 + cs) / 2.0;
        final a0 = 1.0 + alpha;
        a1 = -2.0 * cs / a0;
        a2 = (1.0 - alpha) / a0;
        b0 /= a0;
        b1 /= a0;
        b2 /= a0;
        break;

      case FilterType.bandpass:
        b0 = alpha;
        b1 = 0.0;
        b2 = -alpha;
        final a0 = 1.0 + alpha;
        a1 = -2.0 * cs / a0;
        a2 = (1.0 - alpha) / a0;
        b0 /= a0;
        b1 /= a0;
        b2 /= a0;
        break;

      case FilterType.notch:
        b0 = 1.0;
        b1 = -2.0 * cs;
        b2 = 1.0;
        final a0 = 1.0 + alpha;
        a1 = -2.0 * cs / a0;
        a2 = (1.0 - alpha) / a0;
        b0 /= a0;
        b1 /= a0;
        b2 /= a0;
        break;
    }

    _secondStage?._calculateCoefficients();
  }

  double process(double input) {
    // First stage
    final output = b0 * input + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;

    x2 = x1;
    x1 = input;
    y2 = y1;
    y1 = output;

    // Second stage for 24dB filters
    if (_secondStage != null) {
      return _secondStage!.process(output);
    }

    return output;
  }

  void setCutoff(double freq) {
    cutoff = freq.clamp(20.0, sampleRate / 2.0);
    _calculateCoefficients();
  }

  void setResonance(double q) {
    resonance = q.clamp(0.1, 10.0);
    _calculateCoefficients();
  }

  void reset() {
    x1 = x2 = y1 = y2 = 0.0;
    _secondStage?.reset();
  }
}

/// Distortion effect
class Distortion {
  double amount = 0.0;  // 0.0 = clean, 1.0 = heavy distortion
  DistortionType type = DistortionType.soft;

  double process(double input) {
    if (amount <= 0.0) return input;

    switch (type) {
      case DistortionType.soft:
        return _softClip(input);
      case DistortionType.hard:
        return _hardClip(input);
      case DistortionType.tube:
        return _tubeDistortion(input);
      case DistortionType.fuzz:
        return _fuzzDistortion(input);
      case DistortionType.bitcrush:
        return _bitcrush(input);
    }
  }

  double _softClip(double x) {
    final gain = 1.0 + amount * 9.0;  // 1x to 10x gain
    final driven = x * gain;
    return math.tanh(driven) / math.tanh(gain);
  }

  double _hardClip(double x) {
    final gain = 1.0 + amount * 19.0;
    return (x * gain).clamp(-1.0, 1.0);
  }

  double _tubeDistortion(double x) {
    final gain = 1.0 + amount * 4.0;
    final driven = x * gain;
    if (driven.abs() < 0.33) {
      return driven * 2.0;
    } else if (driven.abs() < 0.66) {
      return (3.0 - (2.0 - 3.0 * driven).abs()) / 3.0 * driven.sign;
    } else {
      return driven.sign;
    }
  }

  double _fuzzDistortion(double x) {
    final gain = 1.0 + amount * 49.0;
    return math.sin(x * gain);
  }

  double _bitcrush(double x) {
    final bits = (16.0 - amount * 12.0).round();  // 16-bit to 4-bit
    final steps = (1 << bits).toDouble();
    return (x * steps).round() / steps;
  }
}

enum DistortionType {
  soft,
  hard,
  tube,
  fuzz,
  bitcrush,
}

/// Delay effect with feedback
class Delay {
  double delayTime = 0.5;      // seconds
  double feedback = 0.3;       // 0.0 to 1.0
  double mix = 0.3;            // dry/wet
  double sampleRate = 48000.0;

  late List<double> _buffer;
  int _writePos = 0;

  Delay({
    this.delayTime = 0.5,
    this.feedback = 0.3,
    this.mix = 0.3,
    this.sampleRate = 48000.0,
  }) {
    final bufferSize = (sampleRate * 2.0).round();  // 2 second max
    _buffer = List.filled(bufferSize, 0.0);
  }

  double process(double input) {
    final delaySamples = (delayTime * sampleRate).round();
    final readPos = (_writePos - delaySamples) % _buffer.length;

    final delayed = _buffer[readPos];
    final output = input + delayed * feedback;

    _buffer[_writePos] = output.clamp(-1.0, 1.0);
    _writePos = (_writePos + 1) % _buffer.length;

    return input * (1.0 - mix) + delayed * mix;
  }

  void setDelayTime(double time) {
    delayTime = time.clamp(0.001, 2.0);
  }

  void setFeedback(double fb) {
    feedback = fb.clamp(0.0, 0.95);
  }

  void setMix(double m) {
    mix = m.clamp(0.0, 1.0);
  }

  void reset() {
    _buffer.fillRange(0, _buffer.length, 0.0);
    _writePos = 0;
  }
}

/// Simple reverb (all-pass based)
class Reverb {
  double roomSize = 0.5;
  double damping = 0.5;
  double mix = 0.3;
  double sampleRate = 48000.0;

  late List<AllPassFilter> _allPassFilters;
  late List<CombFilter> _combFilters;

  Reverb({
    this.roomSize = 0.5,
    this.damping = 0.5,
    this.mix = 0.3,
    this.sampleRate = 48000.0,
  }) {
    _initializeFilters();
  }

  void _initializeFilters() {
    // All-pass filters for diffusion
    _allPassFilters = [
      AllPassFilter(225, sampleRate),
      AllPassFilter(341, sampleRate),
      AllPassFilter(441, sampleRate),
      AllPassFilter(556, sampleRate),
    ];

    // Comb filters for reverb tail
    _combFilters = [
      CombFilter(1116, sampleRate),
      CombFilter(1188, sampleRate),
      CombFilter(1277, sampleRate),
      CombFilter(1356, sampleRate),
      CombFilter(1422, sampleRate),
      CombFilter(1491, sampleRate),
      CombFilter(1557, sampleRate),
      CombFilter(1617, sampleRate),
    ];

    _updateFilters();
  }

  void _updateFilters() {
    for (var filter in _combFilters) {
      filter.setFeedback(roomSize * 0.84);
      filter.setDamping(damping);
    }
  }

  double process(double input) {
    // Process through comb filters
    double combOut = 0.0;
    for (var filter in _combFilters) {
      combOut += filter.process(input);
    }
    combOut /= _combFilters.length;

    // Process through all-pass filters
    double allPassOut = combOut;
    for (var filter in _allPassFilters) {
      allPassOut = filter.process(allPassOut);
    }

    return input * (1.0 - mix) + allPassOut * mix;
  }

  void setRoomSize(double size) {
    roomSize = size.clamp(0.0, 1.0);
    _updateFilters();
  }

  void setDamping(double damp) {
    damping = damp.clamp(0.0, 1.0);
    _updateFilters();
  }

  void setMix(double m) {
    mix = m.clamp(0.0, 1.0);
  }

  void reset() {
    for (var filter in _allPassFilters) {
      filter.reset();
    }
    for (var filter in _combFilters) {
      filter.reset();
    }
  }
}

class AllPassFilter {
  final int delayLength;
  late List<double> _buffer;
  int _index = 0;

  AllPassFilter(this.delayLength, double sampleRate) {
    _buffer = List.filled(delayLength, 0.0);
  }

  double process(double input) {
    final delayed = _buffer[_index];
    final output = -input + delayed;

    _buffer[_index] = input + delayed * 0.5;
    _index = (_index + 1) % delayLength;

    return output;
  }

  void reset() {
    _buffer.fillRange(0, delayLength, 0.0);
    _index = 0;
  }
}

class CombFilter {
  final int delayLength;
  late List<double> _buffer;
  int _index = 0;

  double _feedback = 0.84;
  double _damping = 0.5;
  double _filterState = 0.0;

  CombFilter(this.delayLength, double sampleRate) {
    _buffer = List.filled(delayLength, 0.0);
  }

  double process(double input) {
    final delayed = _buffer[_index];

    // One-pole lowpass for damping
    _filterState = delayed * (1.0 - _damping) + _filterState * _damping;

    _buffer[_index] = input + _filterState * _feedback;
    _index = (_index + 1) % delayLength;

    return delayed;
  }

  void setFeedback(double fb) {
    _feedback = fb.clamp(0.0, 0.99);
  }

  void setDamping(double damp) {
    _damping = damp.clamp(0.0, 1.0);
  }

  void reset() {
    _buffer.fillRange(0, delayLength, 0.0);
    _index = 0;
    _filterState = 0.0;
  }
}

/// Complete effects chain
class EffectsChain {
  late BiquadFilter filter;
  late Distortion distortion;
  late Delay delay;
  late Reverb reverb;

  // Effect enable flags
  bool filterEnabled = true;
  bool distortionEnabled = false;
  bool delayEnabled = false;
  bool reverbEnabled = true;

  EffectsChain({double sampleRate = 48000.0}) {
    filter = BiquadFilter(
      type: FilterType.lowpass24,
      cutoff: 20000.0,
      resonance: 0.7,
      sampleRate: sampleRate,
    );

    distortion = Distortion();

    delay = Delay(
      delayTime: 0.375,
      feedback: 0.3,
      mix: 0.3,
      sampleRate: sampleRate,
    );

    reverb = Reverb(
      roomSize: 0.5,
      damping: 0.5,
      mix: 0.2,
      sampleRate: sampleRate,
    );
  }

  /// Process audio through the effects chain
  double process(double input) {
    double output = input;

    // Filter
    if (filterEnabled) {
      output = filter.process(output);
    }

    // Distortion
    if (distortionEnabled) {
      output = distortion.process(output);
    }

    // Delay
    if (delayEnabled) {
      output = delay.process(output);
    }

    // Reverb
    if (reverbEnabled) {
      output = reverb.process(output);
    }

    return output.clamp(-1.0, 1.0);
  }

  /// Reset all effects
  void reset() {
    filter.reset();
    delay.reset();
    reverb.reset();
  }
}
