import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/enhanced_synth_engine.dart';

/// MIDI controller integration for hardware controller support
///
/// Features:
/// - MIDI note on/off → synthesizer voice triggering
/// - MIDI CC (Control Change) → parameter mapping
/// - MIDI learn mode for custom mappings
/// - MPE (MIDI Polyphonic Expression) support
/// - Pitch bend and aftertouch handling
/// - Program change for preset selection
///
/// **Note**: Requires flutter_midi or dart_midi package
class MIDIController extends ChangeNotifier {
  final EnhancedSynthEngine synthEngine;

  // MIDI state
  bool _isConnected = false;
  String? _deviceName;
  final Map<int, MIDIMapping> _ccMappings = {};

  // MIDI learn mode
  bool _learnMode = false;
  String? _learnParameter;

  // Active notes (for polyphonic support)
  final Map<int, int> _activeNotes = {}; // note number → voice id

  // MPE configuration
  bool _mpeEnabled = false;
  int _mpeMasterChannel = 0;
  int _mpeMemberChannelStart = 1;
  int _mpeMemberChannelEnd = 15;

  MIDIController({required this.synthEngine});

  // Getters
  bool get isConnected => _isConnected;
  String? get deviceName => _deviceName;
  bool get learnMode => _learnMode;
  bool get mpeEnabled => _mpeEnabled;

  /// Connect to MIDI device
  Future<bool> connect({String? deviceName}) async {
    try {
      // In production, use flutter_midi or dart_midi package
      // await MidiCommand().connectToDevice(deviceId);

      _isConnected = true;
      _deviceName = deviceName ?? 'MIDI Device';
      notifyListeners();

      debugPrint('Connected to MIDI device: $_deviceName');
      return true;
    } catch (e) {
      debugPrint('Failed to connect to MIDI device: $e');
      return false;
    }
  }

  /// Disconnect from MIDI device
  Future<void> disconnect() async {
    _isConnected = false;
    _deviceName = null;
    _activeNotes.clear();
    notifyListeners();
    debugPrint('Disconnected from MIDI device');
  }

  /// Handle incoming MIDI message
  void handleMIDIMessage(List<int> message) {
    if (message.isEmpty) return;

    final status = message[0] & 0xF0; // Get message type
    final channel = message[0] & 0x0F; // Get channel

    switch (status) {
      case 0x80: // Note off
        if (message.length >= 3) _handleNoteOff(message[1], message[2], channel);
        break;
      case 0x90: // Note on
        if (message.length >= 3) _handleNoteOn(message[1], message[2], channel);
        break;
      case 0xA0: // Polyphonic aftertouch
        if (message.length >= 3) _handlePolyAftertouch(message[1], message[2], channel);
        break;
      case 0xB0: // Control change
        if (message.length >= 3) _handleCC(message[1], message[2], channel);
        break;
      case 0xC0: // Program change
        if (message.length >= 2) _handleProgramChange(message[1], channel);
        break;
      case 0xD0: // Channel aftertouch
        if (message.length >= 2) _handleChannelAftertouch(message[1], channel);
        break;
      case 0xE0: // Pitch bend
        if (message.length >= 3) _handlePitchBend(message[1], message[2], channel);
        break;
    }
  }

  /// Handle MIDI note on
  void _handleNoteOn(int note, int velocity, int channel) {
    if (velocity == 0) {
      _handleNoteOff(note, 0, channel);
      return;
    }

    final frequency = _midiNoteToFrequency(note);
    final normalizedVelocity = velocity / 127.0;

    // Trigger synth voice
    final voiceId = synthEngine.noteOn(
      frequency: frequency,
      velocity: normalizedVelocity,
    );

    _activeNotes[note] = voiceId;
    debugPrint('MIDI Note On: $note ($frequency Hz), velocity: $velocity');
  }

  /// Handle MIDI note off
  void _handleNoteOff(int note, int velocity, int channel) {
    final voiceId = _activeNotes[note];
    if (voiceId != null) {
      synthEngine.noteOff(voiceId: voiceId);
      _activeNotes.remove(note);
      debugPrint('MIDI Note Off: $note');
    }
  }

  /// Handle MIDI control change
  void _handleCC(int cc, int value, int channel) {
    final normalizedValue = value / 127.0;

    // Standard MIDI CC mappings
    switch (cc) {
      case 1: // Modulation wheel
        synthEngine.setModWheel(normalizedValue);
        break;
      case 7: // Volume
        synthEngine.setMasterVolume(normalizedValue);
        break;
      case 10: // Pan
        synthEngine.setPan(normalizedValue * 2.0 - 1.0); // -1 to 1
        break;
      case 74: // Filter cutoff (standard)
        synthEngine.setFilterCutoff(normalizedValue);
        break;
      case 71: // Filter resonance (standard)
        synthEngine.setFilterResonance(normalizedValue);
        break;
      default:
        // Check custom mappings
        final mapping = _ccMappings[cc];
        if (mapping != null) {
          _applyMapping(mapping, normalizedValue);
        } else if (_learnMode && _learnParameter != null) {
          // MIDI learn: assign this CC to the learning parameter
          _ccMappings[cc] = MIDIMapping(
            cc: cc,
            parameter: _learnParameter!,
            min: 0.0,
            max: 1.0,
          );
          _learnMode = false;
          _learnParameter = null;
          notifyListeners();
          debugPrint('MIDI Learn: CC$cc → $_learnParameter');
        }
        break;
    }

    debugPrint('MIDI CC: $cc = $value ($normalizedValue)');
  }

  /// Handle pitch bend
  void _handlePitchBend(int lsb, int msb, int channel) {
    final value = (msb << 7) | lsb;
    final normalized = (value - 8192) / 8192.0; // -1 to 1
    synthEngine.setPitchBend(normalized);
    debugPrint('MIDI Pitch Bend: $normalized');
  }

  /// Handle channel aftertouch
  void _handleChannelAftertouch(int pressure, int channel) {
    final normalized = pressure / 127.0;
    synthEngine.setAftertouch(normalized);
    debugPrint('MIDI Aftertouch: $normalized');
  }

  /// Handle polyphonic aftertouch (MPE)
  void _handlePolyAftertouch(int note, int pressure, int channel) {
    if (!_mpeEnabled) return;

    final voiceId = _activeNotes[note];
    if (voiceId != null) {
      final normalized = pressure / 127.0;
      synthEngine.setVoiceAftertouch(voiceId: voiceId, aftertouch: normalized);
      debugPrint('MIDI Poly Aftertouch: Note $note = $normalized');
    }
  }

  /// Handle program change (preset selection)
  void _handleProgramChange(int program, int channel) {
    // Load preset by program number
    // synthEngine.loadPreset(program);
    debugPrint('MIDI Program Change: $program');
  }

  /// Apply CC mapping to synth parameter
  void _applyMapping(MIDIMapping mapping, double value) {
    final scaledValue = mapping.min + (mapping.max - mapping.min) * value;

    switch (mapping.parameter) {
      case 'filterCutoff':
        synthEngine.setFilterCutoff(scaledValue);
        break;
      case 'filterResonance':
        synthEngine.setFilterResonance(scaledValue);
        break;
      case 'wavetablePosition':
        synthEngine.setWavetablePosition(scaledValue);
        break;
      case 'grainDensity':
        synthEngine.setGrainDensity(scaledValue);
        break;
      case 'distortion':
        synthEngine.setDistortion(scaledValue);
        break;
      case 'reverbMix':
        synthEngine.setReverbMix(scaledValue);
        break;
      // Add more parameter mappings as needed
    }
  }

  /// Start MIDI learn mode for a parameter
  void startLearn(String parameter) {
    _learnMode = true;
    _learnParameter = parameter;
    notifyListeners();
    debugPrint('MIDI Learn Mode: Waiting for CC for $parameter');
  }

  /// Cancel MIDI learn mode
  void cancelLearn() {
    _learnMode = false;
    _learnParameter = null;
    notifyListeners();
  }

  /// Add or update CC mapping
  void setMapping(int cc, String parameter, {double min = 0.0, double max = 1.0}) {
    _ccMappings[cc] = MIDIMapping(
      cc: cc,
      parameter: parameter,
      min: min,
      max: max,
    );
    notifyListeners();
    debugPrint('MIDI Mapping: CC$cc → $parameter ($min to $max)');
  }

  /// Remove CC mapping
  void removeMapping(int cc) {
    _ccMappings.remove(cc);
    notifyListeners();
    debugPrint('MIDI Mapping Removed: CC$cc');
  }

  /// Get all CC mappings
  Map<int, MIDIMapping> get mappings => Map.unmodifiable(_ccMappings);

  /// Enable MPE mode
  void enableMPE({
    int masterChannel = 0,
    int memberChannelStart = 1,
    int memberChannelEnd = 15,
  }) {
    _mpeEnabled = true;
    _mpeMasterChannel = masterChannel;
    _mpeMemberChannelStart = memberChannelStart;
    _mpeMemberChannelEnd = memberChannelEnd;
    notifyListeners();
    debugPrint('MPE Enabled: Master=$masterChannel, Members=$memberChannelStart-$memberChannelEnd');
  }

  /// Disable MPE mode
  void disableMPE() {
    _mpeEnabled = false;
    notifyListeners();
    debugPrint('MPE Disabled');
  }

  /// Convert MIDI note number to frequency (Hz)
  double _midiNoteToFrequency(int note) {
    // A4 (MIDI note 69) = 440 Hz
    return 440.0 * math.pow(2.0, (note - 69) / 12.0);
  }

  /// Get MIDI input devices (requires flutter_midi package)
  Future<List<String>> getInputDevices() async {
    // In production:
    // final devices = await MidiCommand().devices;
    // return devices.map((d) => d.name).toList();

    // For now, return mock devices
    return ['MIDI Keyboard', 'USB MIDI Controller', 'Virtual MIDI'];
  }

  /// Panic: Stop all active notes
  void panic() {
    for (final voiceId in _activeNotes.values) {
      synthEngine.noteOff(voiceId: voiceId);
    }
    _activeNotes.clear();
    debugPrint('MIDI Panic: All notes off');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// MIDI CC mapping configuration
class MIDIMapping {
  final int cc;
  final String parameter;
  final double min;
  final double max;

  MIDIMapping({
    required this.cc,
    required this.parameter,
    this.min = 0.0,
    this.max = 1.0,
  });

  @override
  String toString() => 'CC$cc → $parameter ($min to $max)';
}

/// Standard MIDI CC numbers (for reference)
class MIDIConstants {
  static const int modWheel = 1;
  static const int breath = 2;
  static const int volume = 7;
  static const int pan = 10;
  static const int expression = 11;
  static const int damperPedal = 64;
  static const int portamento = 65;
  static const int sostenuto = 66;
  static const int softPedal = 67;
  static const int filterResonance = 71;
  static const int releaseTime = 72;
  static const int attackTime = 73;
  static const int filterCutoff = 74;
  static const int decayTime = 75;
  static const int vibratoRate = 76;
  static const int vibratoDepth = 77;
  static const int vibratoDelay = 78;
  static const int reverbSend = 91;
  static const int chorusSend = 93;
  static const int delaySend = 94;
}

// Import math for frequency calculation
import 'dart:math' as math;
