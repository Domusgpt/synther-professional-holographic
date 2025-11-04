/// Enhanced Synthesis Engine Orchestrator
/// Coordinates all synthesis engines, modulation, and visualization

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../synthesis/engines/wavetable_engine.dart';
import '../synthesis/engines/granular_engine.dart';
import '../synthesis/modulation/modulation_matrix.dart';

/// Voice state for polyphonic synthesis
class Voice {
  int noteNumber;
  double frequency;
  double velocity;
  bool isActive;
  DateTime startTime;

  Voice({
    required this.noteNumber,
    required this.frequency,
    required this.velocity,
    this.isActive = true,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();
}

/// Audio analysis data for visualization
class AudioAnalysis {
  double rms = 0.0;          // Root mean square (volume)
  double peak = 0.0;         // Peak amplitude
  double spectralCentroid = 0.0;  // Brightness
  List<double> fftBands = List.filled(8, 0.0);  // 8-band FFT

  AudioAnalysis();

  Map<String, dynamic> toMap() {
    return {
      'rms': rms,
      'peak': peak,
      'spectralCentroid': spectralCentroid,
      'fftBands': fftBands,
    };
  }
}

/// Main enhanced synthesis engine
class EnhancedSynthEngine extends ChangeNotifier {
  static const double sampleRate = 48000.0;
  static const int maxVoices = 32;

  // Synthesis engines
  late WavetableEngine wavetableEngine;
  late GranularEngine granularEngine;

  // Modulation system
  late ModulationMatrix modulationMatrix;

  // Voice management
  final List<Voice> activeVoices = [];

  // Master parameters
  double masterVolume = 0.7;
  double masterPan = 0.5;

  // Filter parameters
  double filterCutoff = 1000.0;
  double filterResonance = 0.5;
  FilterType filterType = FilterType.lowpass;

  // Effects parameters
  double reverbMix = 0.2;
  double delayTime = 0.3;
  double delayFeedback = 0.4;
  double distortionAmount = 0.0;

  // Engine mix
  double wavetableMix = 1.0;
  double granularMix = 0.0;

  // Audio analysis
  final AudioAnalysis audioAnalysis = AudioAnalysis();

  // State
  bool _isInitialized = false;
  bool _isProcessing = false;

  // Callbacks
  Function(Map<String, double>)? onParameterUpdate;
  Function(AudioAnalysis)? onAudioAnalysis;

  EnhancedSynthEngine() {
    _initialize();
  }

  void _initialize() {
    // Initialize engines
    wavetableEngine = WavetableEngine();
    granularEngine = GranularEngine();
    modulationMatrix = ModulationMatrix();

    // Set up default modulations
    _setupDefaultModulations();

    _isInitialized = true;
    debugPrint('✅ EnhancedSynthEngine initialized');
  }

  void _setupDefaultModulations() {
    // Envelope 1 controls wavetable level
    modulationMatrix.addModulation(
      source: ModSource.envelope1,
      destination: ModDestination.wavetableLevel,
      amount: 1.0,
    );

    // LFO 1 modulates filter cutoff
    modulationMatrix.lfos[0].rate = 2.0;
    modulationMatrix.addModulation(
      source: ModSource.lfo1,
      destination: ModDestination.filterCutoff,
      amount: 0.3,
      curve: ModCurve.exponential,
    );

    // XY Pad X controls wavetable position
    modulationMatrix.addModulation(
      source: ModSource.xyPadX,
      destination: ModDestination.wavetablePosition,
      amount: 1.0,
    );

    // XY Pad Y controls grain density
    modulationMatrix.addModulation(
      source: ModSource.xyPadY,
      destination: ModDestination.grainDensity,
      amount: 1.0,
    );

    // XY Pad X -> Visual rotation XW
    modulationMatrix.addModulation(
      source: ModSource.xyPadX,
      destination: ModDestination.visual4DRotationXW,
      amount: 1.0,
    );

    // Filter cutoff -> Visual rotation YW
    modulationMatrix.addModulation(
      source: ModSource.lfo1,
      destination: ModDestination.visual4DRotationYW,
      amount: 0.5,
    );
  }

  // ============================================================
  // NOTE CONTROL
  // ============================================================

  /// Play a note with velocity
  void noteOn(int midiNote, double velocity) {
    if (activeVoices.length >= maxVoices) {
      _stealVoice();
    }

    final frequency = _midiToFrequency(midiNote);
    final voice = Voice(
      noteNumber: midiNote,
      frequency: frequency,
      velocity: velocity,
    );

    activeVoices.add(voice);

    // Trigger envelopes
    modulationMatrix.noteOn(velocity);

    debugPrint('🎵 Note ON: $midiNote (${frequency.toStringAsFixed(2)} Hz), velocity: ${velocity.toStringAsFixed(2)}');
    notifyListeners();
  }

  /// Stop a note
  void noteOff(int midiNote) {
    final voice = activeVoices.where((v) => v.noteNumber == midiNote).firstOrNull;
    if (voice != null) {
      voice.isActive = false;
    }

    // Trigger envelope release
    modulationMatrix.noteOff();

    debugPrint('🎵 Note OFF: $midiNote');
    notifyListeners();
  }

  /// Stop all notes
  void allNotesOff() {
    activeVoices.clear();
    modulationMatrix.reset();
    debugPrint('🛑 All notes off');
    notifyListeners();
  }

  void _stealVoice() {
    // Remove oldest inactive voice, or oldest active voice
    final inactiveVoices = activeVoices.where((v) => !v.isActive).toList();
    if (inactiveVoices.isNotEmpty) {
      activeVoices.remove(inactiveVoices.first);
    } else if (activeVoices.isNotEmpty) {
      activeVoices.removeAt(0);
    }
  }

  double _midiToFrequency(int midiNote) {
    return 440.0 * (1 << ((midiNote - 69) ~/ 12)) *
           [1.0, 1.059463, 1.122462, 1.189207, 1.259921, 1.334840,
            1.414214, 1.498307, 1.587401, 1.681793, 1.781797, 1.887749][(midiNote - 69) % 12];
  }

  // ============================================================
  // AUDIO PROCESSING
  // ============================================================

  /// Process a single audio sample (mono)
  double processSample() {
    if (!_isInitialized || activeVoices.isEmpty) {
      return 0.0;
    }

    _isProcessing = true;

    // Process modulation matrix
    modulationMatrix.process();

    // Apply modulations to parameters
    _applyModulations();

    // Mix all voices
    double output = 0.0;

    for (var voice in activeVoices) {
      if (!voice.isActive && modulationMatrix.envelopes[0].currentLevel < 0.01) {
        continue;
      }

      double voiceOutput = 0.0;

      // Wavetable engine
      if (wavetableMix > 0.0) {
        final wavetablePositionMod = modulationMatrix.getModulation(
          ModDestination.wavetablePosition
        );
        voiceOutput += wavetableEngine.process(voice.frequency, wavetablePositionMod) * wavetableMix;
      }

      // Granular engine (if active)
      if (granularMix > 0.0) {
        final granularSample = granularEngine.processSample();
        voiceOutput += (granularSample[0] + granularSample[1]) * 0.5 * granularMix;
      }

      // Apply envelope
      voiceOutput *= modulationMatrix.envelopes[0].currentLevel;

      // Apply velocity
      voiceOutput *= voice.velocity;

      output += voiceOutput;
    }

    // Normalize by number of voices
    if (activeVoices.isNotEmpty) {
      output /= activeVoices.length;
    }

    // Apply filter (simplified)
    output = _applyFilter(output);

    // Apply master volume
    output *= masterVolume;

    // Update audio analysis
    _updateAudioAnalysis(output);

    // Clean up finished voices
    activeVoices.removeWhere((v) =>
      !v.isActive && modulationMatrix.envelopes[0].currentLevel < 0.01
    );

    _isProcessing = false;

    return output.clamp(-1.0, 1.0);
  }

  /// Process stereo audio sample
  List<double> processStereoSample() {
    final mono = processSample();

    // Apply panning (constant power)
    final panAngle = masterPan * 3.14159 / 2.0;
    final left = mono * (1.0 - masterPan);
    final right = mono * masterPan;

    return [left, right];
  }

  double _applyFilter(double input) {
    // Simplified filter (proper implementation would use biquad filter)
    final cutoffMod = modulationMatrix.getModulation(ModDestination.filterCutoff);
    final modulatedCutoff = (filterCutoff + cutoffMod * 10000.0).clamp(20.0, 20000.0);

    // Very basic filter simulation (placeholder)
    return input;
  }

  void _applyModulations() {
    // Apply modulations to synthesis parameters

    // Wavetable parameters
    final wavetablePosValue = modulationMatrix.getModulation(
      ModDestination.wavetablePosition
    );
    if (wavetableEngine.oscillators.isNotEmpty) {
      wavetableEngine.oscillators[0].positionModDepth = wavetablePosValue.abs();
    }

    // Granular parameters
    final grainDensityMod = modulationMatrix.getModulation(
      ModDestination.grainDensity
    );
    final newDensity = (20.0 + grainDensityMod * 40.0).clamp(1.0, 100.0);
    granularEngine.setGrainDensity(newDensity);

    final grainSizeMod = modulationMatrix.getModulation(
      ModDestination.grainSize
    );
    final newSize = (50.0 + grainSizeMod * 100.0).clamp(1.0, 500.0);
    granularEngine.setGrainSize(newSize);

    // Filter parameters
    final cutoffMod = modulationMatrix.getModulation(
      ModDestination.filterCutoff
    );
    filterCutoff = (1000.0 + cutoffMod * 10000.0).clamp(20.0, 20000.0);
  }

  void _updateAudioAnalysis(double sample) {
    // Update RMS (running average)
    audioAnalysis.rms = audioAnalysis.rms * 0.99 + sample.abs() * 0.01;

    // Update peak
    if (sample.abs() > audioAnalysis.peak) {
      audioAnalysis.peak = sample.abs();
    } else {
      audioAnalysis.peak *= 0.995; // Decay
    }

    // Notify listeners periodically
    if (DateTime.now().millisecond % 16 == 0) {
      onAudioAnalysis?.call(audioAnalysis);
    }
  }

  // ============================================================
  // PARAMETER CONTROL
  // ============================================================

  /// Set master volume (0.0 - 1.0)
  void setMasterVolume(double value) {
    masterVolume = value.clamp(0.0, 1.0);
    _notifyParameterUpdate('masterVolume', masterVolume);
    notifyListeners();
  }

  /// Set filter cutoff (20 - 20000 Hz)
  void setFilterCutoff(double value) {
    filterCutoff = value.clamp(20.0, 20000.0);
    _notifyParameterUpdate('filterCutoff', filterCutoff / 20000.0);
    notifyListeners();
  }

  /// Set filter resonance (0.0 - 1.0)
  void setFilterResonance(double value) {
    filterResonance = value.clamp(0.0, 1.0);
    _notifyParameterUpdate('filterResonance', filterResonance);
    notifyListeners();
  }

  /// Set reverb mix (0.0 - 1.0)
  void setReverbMix(double value) {
    reverbMix = value.clamp(0.0, 1.0);
    _notifyParameterUpdate('reverbMix', reverbMix);
    notifyListeners();
  }

  /// Set wavetable mix (0.0 - 1.0)
  void setWavetableMix(double value) {
    wavetableMix = value.clamp(0.0, 1.0);
    _notifyParameterUpdate('wavetableMix', wavetableMix);
    notifyListeners();
  }

  /// Set granular mix (0.0 - 1.0)
  void setGranularMix(double value) {
    granularMix = value.clamp(0.0, 1.0);
    _notifyParameterUpdate('granularMix', granularMix);
    notifyListeners();
  }

  /// Set XY pad position
  void setXYPad(double x, double y) {
    modulationMatrix.setXYPad(x, y);
    _notifyParameterUpdate('xyPadX', x);
    _notifyParameterUpdate('xyPadY', y);
    notifyListeners();
  }

  void _notifyParameterUpdate(String name, double value) {
    onParameterUpdate?.call({name: value});
  }

  // ============================================================
  // DATA EXTRACTION FOR VISUALIZER
  // ============================================================

  /// Get all parameters for visualization
  Map<String, double> getVisualizerParameters() {
    return {
      // Audio parameters
      'filterCutoff': filterCutoff / 20000.0,
      'filterResonance': filterResonance,
      'reverbMix': reverbMix,
      'masterVolume': masterVolume,

      // Engine mix
      'wavetableMix': wavetableMix,
      'granularMix': granularMix,

      // Modulation matrix values
      'xyPadX': modulationMatrix.xyPadX,
      'xyPadY': modulationMatrix.xyPadY,
      'lfo1Phase': modulationMatrix.lfos[0].phase,
      'envelope1Level': modulationMatrix.envelopes[0].currentLevel,

      // Synthesis parameters
      'wavetablePosition': wavetableEngine.oscillators.isNotEmpty
          ? wavetableEngine.oscillators[0].position
          : 0.0,
      'grainDensity': granularEngine.grainDensity / 100.0,
      'grainSize': granularEngine.grainSize / 500.0,

      // Audio analysis
      'rms': audioAnalysis.rms,
      'peak': audioAnalysis.peak,

      // Visual modulation destinations
      'visual4DRotationXW': modulationMatrix.getModulation(
        ModDestination.visual4DRotationXW
      ),
      'visual4DRotationYW': modulationMatrix.getModulation(
        ModDestination.visual4DRotationYW
      ),
      'visual4DRotationZW': modulationMatrix.getModulation(
        ModDestination.visual4DRotationZW
      ),
      'visualMorphIntensity': modulationMatrix.getModulation(
        ModDestination.visualMorphIntensity
      ),
    };
  }

  /// Get current active voice count
  int getActiveVoiceCount() {
    return activeVoices.length;
  }

  // ============================================================
  // PRESET MANAGEMENT
  // ============================================================

  /// Load preset from map
  void loadPreset(Map<String, dynamic> preset) {
    if (preset.containsKey('masterVolume')) {
      setMasterVolume(preset['masterVolume']);
    }
    if (preset.containsKey('filterCutoff')) {
      setFilterCutoff(preset['filterCutoff']);
    }
    if (preset.containsKey('filterResonance')) {
      setFilterResonance(preset['filterResonance']);
    }
    if (preset.containsKey('reverbMix')) {
      setReverbMix(preset['reverbMix']);
    }
    if (preset.containsKey('wavetableMix')) {
      setWavetableMix(preset['wavetableMix']);
    }
    if (preset.containsKey('granularMix')) {
      setGranularMix(preset['granularMix']);
    }

    // Wavetable parameters
    if (preset.containsKey('wavetableIndex') && wavetableEngine.oscillators.isNotEmpty) {
      wavetableEngine.oscillators[0].wavetableIndex = preset['wavetableIndex'];
    }

    debugPrint('✅ Preset loaded');
    notifyListeners();
  }

  /// Get current state as preset
  Map<String, dynamic> getCurrentPreset() {
    return {
      'masterVolume': masterVolume,
      'filterCutoff': filterCutoff,
      'filterResonance': filterResonance,
      'reverbMix': reverbMix,
      'wavetableMix': wavetableMix,
      'granularMix': granularMix,
      'wavetableIndex': wavetableEngine.oscillators.isNotEmpty
          ? wavetableEngine.oscillators[0].wavetableIndex
          : 0,
    };
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;

  @override
  void dispose() {
    allNotesOff();
    super.dispose();
  }
}

enum FilterType {
  lowpass,
  highpass,
  bandpass,
  notch,
}
