/// Professional Wavetable Synthesis Engine
/// Implements modern wavetable synthesis with position modulation and morphing

import 'dart:math' as math;
import 'dart:typed_data';

enum InterpolationMode {
  linear,
  cubic,
  spectral,
}

enum WaveformType {
  sine,
  saw,
  square,
  triangle,
  noise,
  custom,
}

class Wavetable {
  final String name;
  final List<Float32List> frames; // Multiple single-cycle waveforms
  final int framesCount;

  Wavetable({
    required this.name,
    required this.frames,
  }) : framesCount = frames.length;

  /// Get a single frame from the wavetable
  Float32List getFrame(int index) {
    return frames[index.clamp(0, framesCount - 1)];
  }

  /// Get interpolated value between frames
  double getInterpolatedSample(double framePosition, int sampleIndex) {
    final frameIndex = framePosition.floor();
    final frameFraction = framePosition - frameIndex;

    final frame1 = getFrame(frameIndex);
    final frame2 = getFrame((frameIndex + 1) % framesCount);

    final sampleIndexClamped = sampleIndex % frame1.length;

    // Linear interpolation between frames
    return frame1[sampleIndexClamped] * (1.0 - frameFraction) +
        frame2[sampleIndexClamped] * frameFraction;
  }
}

class WavetableOscillator {
  int wavetableIndex = 0;
  double position = 0.0; // 0.0-1.0 scan through wavetable
  double positionModDepth = 0.0;
  double pitch = 0.0; // Semitones
  double detune = 0.0; // Cents
  int unisonVoices = 1;
  double unisonSpread = 0.2;
  InterpolationMode interpolationMode = InterpolationMode.linear;
  double phase = 0.0;
  double level = 1.0;

  // Calculate frequency from pitch
  double getFrequency(double baseFrequency) {
    final semitoneMultiplier = math.pow(2, pitch / 12.0);
    final detuneMultiplier = math.pow(2, detune / 1200.0);
    return baseFrequency * semitoneMultiplier * detuneMultiplier;
  }

  void reset() {
    phase = 0.0;
  }
}

class WavetableEngine {
  static const int tableSize = 2048;
  static const double sampleRate = 48000.0;

  final List<Wavetable> wavetables = [];
  final List<WavetableOscillator> oscillators = [];

  WavetableEngine() {
    _initializeDefaultWavetables();
    // Start with 2 oscillators
    oscillators.add(WavetableOscillator());
    oscillators.add(WavetableOscillator()..pitch = 12.0); // One octave up
  }

  /// Initialize default wavetables with classic waveforms
  void _initializeDefaultWavetables() {
    // Sine wavetable
    wavetables.add(_createSineWavetable());

    // Saw wavetable with harmonic evolution
    wavetables.add(_createSawWavetable());

    // Square wavetable with PWM evolution
    wavetables.add(_createSquareWavetable());

    // Triangle wavetable
    wavetables.add(_createTriangleWavetable());

    // Complex wavetable with harmonic morphing
    wavetables.add(_createHarmonicMorphWavetable());

    // Additive wavetable
    wavetables.add(_createAdditiveWavetable());

    // FM-style wavetable
    wavetables.add(_createFMStyleWavetable());

    // Vocal formant wavetable
    wavetables.add(_createVocalFormantWavetable());
  }

  Wavetable _createSineWavetable() {
    final frames = <Float32List>[];
    final frame = Float32List(tableSize);
    for (int i = 0; i < tableSize; i++) {
      frame[i] = math.sin(2.0 * math.pi * i / tableSize);
    }
    frames.add(frame);
    return Wavetable(name: 'Sine', frames: frames);
  }

  Wavetable _createSawWavetable() {
    final frames = <Float32List>[];
    const frameCount = 16;

    for (int f = 0; f < frameCount; f++) {
      final frame = Float32List(tableSize);
      final harmonics = 1 + (f * 3); // Increase harmonics per frame

      for (int i = 0; i < tableSize; i++) {
        double sample = 0.0;
        for (int h = 1; h <= harmonics; h++) {
          sample += math.sin(2.0 * math.pi * h * i / tableSize) / h;
        }
        frame[i] = sample / 2.0; // Normalize
      }
      frames.add(frame);
    }
    return Wavetable(name: 'Saw', frames: frames);
  }

  Wavetable _createSquareWavetable() {
    final frames = <Float32List>[];
    const frameCount = 16;

    for (int f = 0; f < frameCount; f++) {
      final frame = Float32List(tableSize);
      final pulseWidth = 0.1 + (f / frameCount) * 0.8; // PWM from 10% to 90%

      for (int i = 0; i < tableSize; i++) {
        frame[i] = (i / tableSize < pulseWidth) ? 1.0 : -1.0;
      }
      frames.add(frame);
    }
    return Wavetable(name: 'Square', frames: frames);
  }

  Wavetable _createTriangleWavetable() {
    final frames = <Float32List>[];
    final frame = Float32List(tableSize);

    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      if (phase < 0.25) {
        frame[i] = 4.0 * phase;
      } else if (phase < 0.75) {
        frame[i] = 2.0 - 4.0 * phase;
      } else {
        frame[i] = 4.0 * phase - 4.0;
      }
    }
    frames.add(frame);
    return Wavetable(name: 'Triangle', frames: frames);
  }

  Wavetable _createHarmonicMorphWavetable() {
    final frames = <Float32List>[];
    const frameCount = 32;

    for (int f = 0; f < frameCount; f++) {
      final frame = Float32List(tableSize);
      final morphPosition = f / frameCount;

      for (int i = 0; i < tableSize; i++) {
        double sample = 0.0;
        // Morph between different harmonic structures
        for (int h = 1; h <= 8; h++) {
          final amplitude = math.exp(-h * morphPosition) / h;
          sample += amplitude * math.sin(2.0 * math.pi * h * i / tableSize);
        }
        frame[i] = sample;
      }
      frames.add(frame);
    }
    return Wavetable(name: 'Harmonic Morph', frames: frames);
  }

  Wavetable _createAdditiveWavetable() {
    final frames = <Float32List>[];
    const frameCount = 16;

    for (int f = 0; f < frameCount; f++) {
      final frame = Float32List(tableSize);

      for (int i = 0; i < tableSize; i++) {
        double sample = 0.0;
        // Different harmonic ratios per frame
        sample += 1.0 * math.sin(2.0 * math.pi * 1 * i / tableSize);
        sample += 0.5 * math.sin(2.0 * math.pi * 2 * i / tableSize);
        sample += 0.3 * math.sin(2.0 * math.pi * 3 * i / tableSize);
        sample += (f / frameCount) * 0.2 * math.sin(2.0 * math.pi * 5 * i / tableSize);
        sample += (f / frameCount) * 0.15 * math.sin(2.0 * math.pi * 7 * i / tableSize);
        frame[i] = sample / 2.5;
      }
      frames.add(frame);
    }
    return Wavetable(name: 'Additive', frames: frames);
  }

  Wavetable _createFMStyleWavetable() {
    final frames = <Float32List>[];
    const frameCount = 24;

    for (int f = 0; f < frameCount; f++) {
      final frame = Float32List(tableSize);
      final modIndex = (f / frameCount) * 8.0; // FM modulation index

      for (int i = 0; i < tableSize; i++) {
        final carrier = 2.0 * math.pi * i / tableSize;
        final modulator = math.sin(2.0 * math.pi * i / tableSize);
        frame[i] = math.sin(carrier + modIndex * modulator);
      }
      frames.add(frame);
    }
    return Wavetable(name: 'FM Style', frames: frames);
  }

  Wavetable _createVocalFormantWavetable() {
    final frames = <Float32List>[];
    const frameCount = 16;

    // Formant frequencies for vowel-like sounds
    final formants = [
      [800, 1150, 2900], // "a"
      [350, 2000, 2800], // "e"
      [270, 2140, 2950], // "i"
      [450, 800, 2830],  // "o"
      [325, 700, 2700],  // "u"
    ];

    for (int f = 0; f < frameCount; f++) {
      final frame = Float32List(tableSize);
      final formantIndex = (f / frameCount * formants.length).floor() % formants.length;
      final currentFormants = formants[formantIndex];

      for (int i = 0; i < tableSize; i++) {
        double sample = 0.0;
        for (var formantFreq in currentFormants) {
          final harmonic = formantFreq / 100.0; // Approximate harmonic
          sample += math.sin(2.0 * math.pi * harmonic * i / tableSize) / 3.0;
        }
        frame[i] = sample;
      }
      frames.add(frame);
    }
    return Wavetable(name: 'Vocal Formant', frames: frames);
  }

  /// Process a single sample for all oscillators
  double process(double frequency, double positionMod) {
    double output = 0.0;

    for (var osc in oscillators) {
      if (!_isOscillatorActive(osc)) continue;

      final wavetable = wavetables[osc.wavetableIndex % wavetables.length];
      final oscFrequency = osc.getFrequency(frequency);

      // Calculate wavetable position with modulation
      final modulatedPosition = (osc.position + positionMod * osc.positionModDepth)
          .clamp(0.0, 1.0);
      final framePosition = modulatedPosition * (wavetable.framesCount - 1);

      // Unison voices
      if (osc.unisonVoices == 1) {
        output += _processSingleVoice(osc, wavetable, oscFrequency, framePosition);
      } else {
        output += _processUnisonVoices(osc, wavetable, oscFrequency, framePosition);
      }
    }

    return output.clamp(-1.0, 1.0);
  }

  bool _isOscillatorActive(WavetableOscillator osc) {
    return osc.level > 0.0;
  }

  double _processSingleVoice(
    WavetableOscillator osc,
    Wavetable wavetable,
    double frequency,
    double framePosition,
  ) {
    // Calculate phase increment
    final phaseIncrement = frequency / sampleRate;
    osc.phase += phaseIncrement;
    if (osc.phase >= 1.0) osc.phase -= 1.0;

    // Get sample index in wavetable
    final sampleIndex = (osc.phase * tableSize).floor();

    // Get interpolated sample
    final sample = wavetable.getInterpolatedSample(framePosition, sampleIndex);

    return sample * osc.level;
  }

  double _processUnisonVoices(
    WavetableOscillator osc,
    Wavetable wavetable,
    double frequency,
    double framePosition,
  ) {
    double output = 0.0;
    final voices = osc.unisonVoices;

    for (int v = 0; v < voices; v++) {
      // Detune each voice
      final detuneOffset = (v - voices / 2.0) * osc.unisonSpread;
      final voiceFrequency = frequency * math.pow(2, detuneOffset / 1200.0);

      // Phase increment for this voice
      final phaseIncrement = voiceFrequency / sampleRate;
      final voicePhase = (osc.phase + v / voices) % 1.0;

      // Get sample
      final sampleIndex = (voicePhase * tableSize).floor();
      final sample = wavetable.getInterpolatedSample(framePosition, sampleIndex);

      output += sample / voices;
    }

    osc.phase += frequency / sampleRate;
    if (osc.phase >= 1.0) osc.phase -= 1.0;

    return output * osc.level;
  }

  /// Add a new oscillator
  void addOscillator(WavetableOscillator oscillator) {
    oscillators.add(oscillator);
  }

  /// Remove an oscillator
  void removeOscillator(int index) {
    if (index >= 0 && index < oscillators.length) {
      oscillators.removeAt(index);
    }
  }

  /// Get wavetable names for UI
  List<String> getWavetableNames() {
    return wavetables.map((w) => w.name).toList();
  }

  /// Load custom wavetable from audio data
  Future<void> loadCustomWavetable(String name, Float32List audioData) async {
    // Split audio data into frames
    const framesCount = 16;
    final frameSize = audioData.length ~/ framesCount;
    final frames = <Float32List>[];

    for (int i = 0; i < framesCount; i++) {
      final start = i * frameSize;
      final end = start + frameSize;
      final frame = Float32List.fromList(
        audioData.sublist(start, end.clamp(0, audioData.length))
      );
      frames.add(frame);
    }

    wavetables.add(Wavetable(name: name, frames: frames));
  }

  /// Reset all oscillators
  void reset() {
    for (var osc in oscillators) {
      osc.reset();
    }
  }
}
