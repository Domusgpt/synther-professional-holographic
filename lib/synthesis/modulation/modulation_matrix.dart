/// Professional Modulation Matrix System
/// Allows routing of any modulation source to any destination with depth control

import 'dart:math' as math;

enum ModSource {
  lfo1, lfo2, lfo3, lfo4, lfo5, lfo6, lfo7, lfo8,
  envelope1, envelope2, envelope3, envelope4,
  velocity,
  aftertouch,
  modWheel,
  pitchBend,
  xyPadX,
  xyPadY,
  random,
  constant,
}

enum ModDestination {
  // Wavetable parameters
  wavetablePosition,
  wavetablePitch,
  wavetableDetune,
  wavetableLevel,

  // Granular parameters
  grainSize,
  grainDensity,
  grainPlayhead,
  grainSpread,
  grainPitch,

  // Filter parameters
  filterCutoff,
  filterResonance,

  // Effects parameters
  reverbMix,
  delayTime,
  delayFeedback,
  chorusDepth,
  distortionAmount,

  // Master parameters
  masterVolume,
  masterPan,

  // LFO parameters
  lfo1Rate,
  lfo2Rate,
  lfo3Rate,

  // Visual parameters (for vib34d integration)
  visual4DRotationXW,
  visual4DRotationYW,
  visual4DRotationZW,
  visualMorphIntensity,
}

enum ModCurve {
  linear,
  exponential,
  logarithmic,
  sCurve,
  inverseSCurve,
}

class LFO {
  double rate = 1.0; // Hz
  double phase = 0.0;
  LFOWaveform waveform = LFOWaveform.sine;
  bool bipolar = true;

  double process(double sampleRate) {
    final increment = rate / sampleRate;
    phase += increment;
    if (phase >= 1.0) phase -= 1.0;

    double value = 0.0;

    switch (waveform) {
      case LFOWaveform.sine:
        value = math.sin(2.0 * math.pi * phase);
        break;
      case LFOWaveform.triangle:
        value = phase < 0.5
            ? 4.0 * phase - 1.0
            : 3.0 - 4.0 * phase;
        break;
      case LFOWaveform.saw:
        value = 2.0 * phase - 1.0;
        break;
      case LFOWaveform.square:
        value = phase < 0.5 ? 1.0 : -1.0;
        break;
      case LFOWaveform.random:
        if (phase < increment) {
          value = (math.Random().nextDouble() * 2.0) - 1.0;
        }
        break;
    }

    return bipolar ? value : (value + 1.0) / 2.0;
  }

  void reset() {
    phase = 0.0;
  }
}

enum LFOWaveform {
  sine,
  triangle,
  saw,
  square,
  random,
}

class Envelope {
  double attack = 0.1;
  double decay = 0.3;
  double sustain = 0.7;
  double release = 0.5;

  EnvelopeState state = EnvelopeState.idle;
  double currentLevel = 0.0;
  double stateTime = 0.0;

  void noteOn() {
    state = EnvelopeState.attack;
    stateTime = 0.0;
  }

  void noteOff() {
    state = EnvelopeState.release;
    stateTime = 0.0;
  }

  double process(double sampleRate) {
    final timeIncrement = 1.0 / sampleRate;

    switch (state) {
      case EnvelopeState.idle:
        currentLevel = 0.0;
        break;

      case EnvelopeState.attack:
        if (attack > 0.0) {
          stateTime += timeIncrement;
          currentLevel = stateTime / attack;
          if (currentLevel >= 1.0) {
            currentLevel = 1.0;
            state = EnvelopeState.decay;
            stateTime = 0.0;
          }
        } else {
          currentLevel = 1.0;
          state = EnvelopeState.decay;
        }
        break;

      case EnvelopeState.decay:
        if (decay > 0.0) {
          stateTime += timeIncrement;
          final decayProgress = stateTime / decay;
          currentLevel = 1.0 - (decayProgress * (1.0 - sustain));
          if (decayProgress >= 1.0) {
            currentLevel = sustain;
            state = EnvelopeState.sustain;
          }
        } else {
          currentLevel = sustain;
          state = EnvelopeState.sustain;
        }
        break;

      case EnvelopeState.sustain:
        currentLevel = sustain;
        break;

      case EnvelopeState.release:
        if (release > 0.0) {
          stateTime += timeIncrement;
          final releaseProgress = stateTime / release;
          currentLevel = sustain * (1.0 - releaseProgress);
          if (releaseProgress >= 1.0) {
            currentLevel = 0.0;
            state = EnvelopeState.idle;
          }
        } else {
          currentLevel = 0.0;
          state = EnvelopeState.idle;
        }
        break;
    }

    return currentLevel.clamp(0.0, 1.0);
  }

  void reset() {
    state = EnvelopeState.idle;
    currentLevel = 0.0;
    stateTime = 0.0;
  }
}

enum EnvelopeState {
  idle,
  attack,
  decay,
  sustain,
  release,
}

class ModulationSlot {
  ModSource source;
  ModDestination destination;
  double amount; // -1.0 to 1.0
  ModCurve curve;
  bool enabled;

  ModulationSlot({
    required this.source,
    required this.destination,
    this.amount = 0.0,
    this.curve = ModCurve.linear,
    this.enabled = true,
  });

  double applyCurve(double value) {
    switch (curve) {
      case ModCurve.linear:
        return value;

      case ModCurve.exponential:
        return value >= 0
            ? math.pow(value.abs(), 2.0) as double
            : -math.pow(value.abs(), 2.0) as double;

      case ModCurve.logarithmic:
        return value >= 0
            ? math.sqrt(value.abs())
            : -math.sqrt(value.abs());

      case ModCurve.sCurve:
        // Smooth S-curve using tanh approximation
        return math.tanh(value * 2.0) / math.tanh(2.0);

      case ModCurve.inverseSCurve:
        final sCurved = math.tanh(value * 2.0) / math.tanh(2.0);
        return -sCurved;
    }
  }
}

class ModulationMatrix {
  static const double sampleRate = 48000.0;

  // Modulation sources
  final List<LFO> lfos = List.generate(8, (_) => LFO());
  final List<Envelope> envelopes = List.generate(4, (_) => Envelope());

  // Control values
  double velocity = 0.0;
  double aftertouch = 0.0;
  double modWheel = 0.0;
  double pitchBend = 0.0;
  double xyPadX = 0.5;
  double xyPadY = 0.5;

  // Modulation slots
  final List<ModulationSlot> slots = [];

  // Current modulation values per destination
  final Map<ModDestination, double> currentModulation = {};

  ModulationMatrix() {
    _initializeDefaultSlots();
  }

  void _initializeDefaultSlots() {
    // Add some default modulations
    addModulation(
      source: ModSource.lfo1,
      destination: ModDestination.filterCutoff,
      amount: 0.5,
    );

    addModulation(
      source: ModSource.envelope1,
      destination: ModDestination.wavetableLevel,
      amount: 1.0,
    );

    addModulation(
      source: ModSource.xyPadX,
      destination: ModDestination.visual4DRotationXW,
      amount: 1.0,
    );

    addModulation(
      source: ModSource.xyPadY,
      destination: ModDestination.visual4DRotationYW,
      amount: 1.0,
    );
  }

  void addModulation({
    required ModSource source,
    required ModDestination destination,
    required double amount,
    ModCurve curve = ModCurve.linear,
  }) {
    slots.add(ModulationSlot(
      source: source,
      destination: destination,
      amount: amount,
      curve: curve,
    ));
  }

  void removeModulation(int index) {
    if (index >= 0 && index < slots.length) {
      slots.removeAt(index);
    }
  }

  /// Process all modulation sources and calculate destination values
  void process() {
    // Clear previous modulation values
    currentModulation.clear();

    // Process all LFOs
    for (int i = 0; i < lfos.length; i++) {
      lfos[i].process(sampleRate);
    }

    // Process all envelopes
    for (int i = 0; i < envelopes.length; i++) {
      envelopes[i].process(sampleRate);
    }

    // Process all modulation slots
    for (var slot in slots) {
      if (!slot.enabled) continue;

      final sourceValue = _getSourceValue(slot.source);
      final curvedValue = slot.applyCurve(sourceValue);
      final modulatedValue = curvedValue * slot.amount;

      // Accumulate modulation for this destination
      currentModulation[slot.destination] =
          (currentModulation[slot.destination] ?? 0.0) + modulatedValue;
    }

    // Clamp all modulation values
    currentModulation.updateAll((key, value) => value.clamp(-1.0, 1.0));
  }

  double _getSourceValue(ModSource source) {
    switch (source) {
      // LFOs
      case ModSource.lfo1:
        return lfos[0].phase;
      case ModSource.lfo2:
        return lfos[1].phase;
      case ModSource.lfo3:
        return lfos[2].phase;
      case ModSource.lfo4:
        return lfos[3].phase;
      case ModSource.lfo5:
        return lfos[4].phase;
      case ModSource.lfo6:
        return lfos[5].phase;
      case ModSource.lfo7:
        return lfos[6].phase;
      case ModSource.lfo8:
        return lfos[7].phase;

      // Envelopes
      case ModSource.envelope1:
        return envelopes[0].currentLevel;
      case ModSource.envelope2:
        return envelopes[1].currentLevel;
      case ModSource.envelope3:
        return envelopes[2].currentLevel;
      case ModSource.envelope4:
        return envelopes[3].currentLevel;

      // Control sources
      case ModSource.velocity:
        return velocity;
      case ModSource.aftertouch:
        return aftertouch;
      case ModSource.modWheel:
        return modWheel;
      case ModSource.pitchBend:
        return pitchBend;
      case ModSource.xyPadX:
        return xyPadX;
      case ModSource.xyPadY:
        return xyPadY;

      // Special sources
      case ModSource.random:
        return (math.Random().nextDouble() * 2.0) - 1.0;
      case ModSource.constant:
        return 1.0;
    }
  }

  /// Get modulation value for a specific destination
  double getModulation(ModDestination destination) {
    return currentModulation[destination] ?? 0.0;
  }

  /// Trigger note on for all envelopes
  void noteOn(double noteVelocity) {
    velocity = noteVelocity;
    for (var envelope in envelopes) {
      envelope.noteOn();
    }
  }

  /// Trigger note off for all envelopes
  void noteOff() {
    for (var envelope in envelopes) {
      envelope.noteOff();
    }
  }

  /// Reset all modulation sources
  void reset() {
    for (var lfo in lfos) {
      lfo.reset();
    }
    for (var envelope in envelopes) {
      envelope.reset();
    }
    currentModulation.clear();
  }

  /// Set XY pad position
  void setXYPad(double x, double y) {
    xyPadX = x.clamp(0.0, 1.0);
    xyPadY = y.clamp(0.0, 1.0);
  }

  /// Set mod wheel value
  void setModWheel(double value) {
    modWheel = value.clamp(0.0, 1.0);
  }

  /// Set aftertouch value
  void setAftertouch(double value) {
    aftertouch = value.clamp(0.0, 1.0);
  }

  /// Set pitch bend value
  void setPitchBend(double value) {
    pitchBend = value.clamp(-1.0, 1.0);
  }

  /// Get visualizer data for UI
  Map<String, dynamic> getVisualizerData() {
    return {
      'lfoPhases': lfos.map((lfo) => lfo.phase).toList(),
      'envelopeLevels': envelopes.map((env) => env.currentLevel).toList(),
      'activeSlots': slots.where((s) => s.enabled).length,
      'xyPad': {'x': xyPadX, 'y': xyPadY},
    };
  }
}
