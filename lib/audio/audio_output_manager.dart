import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/enhanced_synth_engine.dart';

/// Real-time audio output manager for streaming synthesis to device speakers
///
/// Manages audio output stream with proper buffer management and latency control.
/// Supports multiple audio backends and handles audio session lifecycle.
///
/// **Note**: This implementation uses a platform channel approach.
/// For production, integrate with coast_audio or flutter_audio_capture packages.
class AudioOutputManager extends ChangeNotifier {
  final EnhancedSynthEngine synthEngine;

  // Audio configuration
  static const int sampleRate = 44100;
  static const int channelCount = 2; // Stereo
  static const int bufferSize = 512; // Frames per buffer (11.6ms @ 44.1kHz)
  static const int bitDepth = 16;

  // State
  bool _isPlaying = false;
  bool _isInitialized = false;
  double _cpuLoad = 0.0;
  int _droppedFrames = 0;

  // Audio buffer
  Float32List? _audioBuffer;
  Timer? _audioTimer;

  // Performance metrics
  int _renderedFrames = 0;
  DateTime? _lastUpdateTime;

  AudioOutputManager({required this.synthEngine}) {
    _initialize();
  }

  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  double get cpuLoad => _cpuLoad;
  int get droppedFrames => _droppedFrames;

  Future<void> _initialize() async {
    try {
      _audioBuffer = Float32List(bufferSize * channelCount);
      _isInitialized = true;
      notifyListeners();
      debugPrint('AudioOutputManager initialized: ${sampleRate}Hz, ${channelCount}ch, ${bufferSize} frames');
    } catch (e) {
      debugPrint('Failed to initialize audio output: $e');
      _isInitialized = false;
    }
  }

  /// Start audio playback
  Future<void> start() async {
    if (!_isInitialized) {
      await _initialize();
      if (!_isInitialized) {
        throw Exception('Failed to initialize audio output');
      }
    }

    if (_isPlaying) return;

    _isPlaying = true;
    _lastUpdateTime = DateTime.now();
    _renderedFrames = 0;
    _droppedFrames = 0;

    // Start audio rendering timer
    // In production, this would be replaced by actual audio callback
    _audioTimer = Timer.periodic(
      Duration(microseconds: (bufferSize * 1000000 / sampleRate).round()),
      (_) => _renderAudioBuffer(),
    );

    notifyListeners();
    debugPrint('Audio playback started');
  }

  /// Stop audio playback
  Future<void> stop() async {
    if (!_isPlaying) return;

    _audioTimer?.cancel();
    _audioTimer = null;
    _isPlaying = false;

    notifyListeners();
    debugPrint('Audio playback stopped');
  }

  /// Render audio buffer from synthesis engine
  void _renderAudioBuffer() {
    if (!_isPlaying || _audioBuffer == null) return;

    final startTime = DateTime.now();

    try {
      // Render frames from synth engine
      for (int frame = 0; frame < bufferSize; frame++) {
        // Get mono sample from synth engine
        final sample = synthEngine.processSample();

        // Convert to stereo (duplicate to both channels for now)
        final leftIndex = frame * channelCount;
        final rightIndex = leftIndex + 1;

        _audioBuffer![leftIndex] = sample.toDouble();
        _audioBuffer![rightIndex] = sample.toDouble();
      }

      _renderedFrames += bufferSize;

      // Calculate CPU load
      final renderTime = DateTime.now().difference(startTime);
      final bufferDuration = Duration(microseconds: (bufferSize * 1000000 / sampleRate).round());
      _cpuLoad = (renderTime.inMicroseconds / bufferDuration.inMicroseconds).clamp(0.0, 1.0);

      // In production: Send _audioBuffer to platform audio output
      // For now, this is a simulation
      _simulateAudioOutput(_audioBuffer!);
    } catch (e) {
      _droppedFrames++;
      debugPrint('Audio buffer underrun: $e');
    }

    // Update metrics every second
    if (_lastUpdateTime != null) {
      final elapsed = DateTime.now().difference(_lastUpdateTime!);
      if (elapsed.inMilliseconds >= 1000) {
        notifyListeners();
        _lastUpdateTime = DateTime.now();
      }
    }
  }

  /// Simulate audio output (replace with actual platform channel in production)
  void _simulateAudioOutput(Float32List buffer) {
    // In production, this would send buffer to:
    // - iOS: AVAudioEngine
    // - Android: AudioTrack
    // - Web: Web Audio API
    // - Desktop: PortAudio, JACK, ASIO

    // For now, this is a placeholder
    // The actual implementation requires platform channels or packages like:
    // - coast_audio
    // - flutter_sound
    // - just_audio with custom source
  }

  /// Get current audio latency in milliseconds
  double get latencyMs {
    return (bufferSize / sampleRate) * 1000.0;
  }

  /// Get audio stream info
  Map<String, dynamic> get audioInfo {
    return {
      'sampleRate': sampleRate,
      'channels': channelCount,
      'bufferSize': bufferSize,
      'bitDepth': bitDepth,
      'latencyMs': latencyMs,
      'isPlaying': _isPlaying,
      'cpuLoad': _cpuLoad,
      'renderedFrames': _renderedFrames,
      'droppedFrames': _droppedFrames,
    };
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Audio output backend selection
enum AudioBackend {
  auto,           // Auto-select based on platform
  coastAudio,     // coast_audio package (recommended)
  flutterSound,   // flutter_sound package
  platformChannel, // Custom platform channel
}

/// Extended audio output manager with backend support
class AudioOutputManagerExtended extends AudioOutputManager {
  final AudioBackend backend;

  AudioOutputManagerExtended({
    required super.synthEngine,
    this.backend = AudioBackend.auto,
  });

  @override
  Future<void> _initialize() async {
    switch (backend) {
      case AudioBackend.auto:
        await _initializeAuto();
        break;
      case AudioBackend.coastAudio:
        await _initializeCoastAudio();
        break;
      case AudioBackend.flutterSound:
        await _initializeFlutterSound();
        break;
      case AudioBackend.platformChannel:
        await _initializePlatformChannel();
        break;
    }
  }

  Future<void> _initializeAuto() async {
    // Try backends in order of preference
    try {
      await _initializeCoastAudio();
    } catch (e) {
      debugPrint('coast_audio not available, trying flutter_sound: $e');
      try {
        await _initializeFlutterSound();
      } catch (e) {
        debugPrint('flutter_sound not available, using simulation: $e');
        await super._initialize();
      }
    }
  }

  Future<void> _initializeCoastAudio() async {
    // coast_audio integration (requires package)
    // This is a placeholder for actual implementation

    debugPrint('coast_audio backend selected (requires package installation)');
    debugPrint('Add to pubspec.yaml: coast_audio: ^2.0.0');
    debugPrint('Example usage:');
    debugPrint('''
import 'package:coast_audio/coast_audio.dart';

final device = AudioDevice.getDefaultOutputDevice();
final format = AudioFormat(
  sampleRate: $sampleRate,
  channelCount: $channelCount,
);

final stream = device.createOutputStream(
  format: format,
  bufferFrameSize: $bufferSize,
  callback: (buffer) {
    // Fill buffer with synth samples
    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = synthEngine.processSample();
    }
  },
);

stream.start();
''');

    // For now, fall back to simulation
    await super._initialize();
  }

  Future<void> _initializeFlutterSound() async {
    // flutter_sound integration (requires package)
    debugPrint('flutter_sound backend selected (requires package installation)');
    debugPrint('Add to pubspec.yaml: flutter_sound: ^9.0.0');

    // For now, fall back to simulation
    await super._initialize();
  }

  Future<void> _initializePlatformChannel() async {
    // Custom platform channel implementation
    debugPrint('Platform channel backend requires native implementation');

    // For now, fall back to simulation
    await super._initialize();
  }
}

/// Audio output configuration
class AudioOutputConfig {
  final int sampleRate;
  final int channelCount;
  final int bufferSize;
  final int bitDepth;
  final AudioBackend backend;

  const AudioOutputConfig({
    this.sampleRate = 44100,
    this.channelCount = 2,
    this.bufferSize = 512,
    this.bitDepth = 16,
    this.backend = AudioBackend.auto,
  });

  /// Preset configurations
  static const lowLatency = AudioOutputConfig(
    bufferSize: 256, // 5.8ms @ 44.1kHz
  );

  static const balanced = AudioOutputConfig(
    bufferSize: 512, // 11.6ms @ 44.1kHz
  );

  static const highQuality = AudioOutputConfig(
    sampleRate: 48000,
    bufferSize: 1024, // 21.3ms @ 48kHz
  );

  double get latencyMs => (bufferSize / sampleRate) * 1000.0;
}
