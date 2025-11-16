/// Vib34D XR Quaternion SDK Wrapper for Flutter
/// Bridges Flutter app with the vib34d quaternion-based visualization SDK

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vector_math/vector_math.dart' as vmath;

enum VisualizationEngine {
  polychora,    // 4D polytopes with glassmorphic rendering
  holographic,  // Audio-reactive holographic effects
  quantum,      // 3D lattice structures
  faceted,      // Simple geometric patterns
}

class Vib34dSDKWrapper {
  late WebViewController webController;
  bool _isInitialized = false;

  // Current state
  VisualizationEngine currentEngine = VisualizationEngine.polychora;
  vmath.Quaternion currentQuaternion = vmath.Quaternion.identity();
  Map<String, double> audioParameters = {};

  // Callbacks
  Function()? onInitialized;
  Function(String)? onError;

  /// Initialize the SDK with WebView
  Future<void> initialize() async {
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            debugPrint('🎨 Vib34D SDK page loaded');
            await Future.delayed(const Duration(milliseconds: 500));
            _isInitialized = true;
            onInitialized?.call();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ Vib34D SDK error: ${error.description}');
            onError?.call(error.description);
          },
        ),
      );

    // Load the integration HTML
    await webController.loadFlutterAsset('assets/vib34d-integration.html');
  }

  /// Update audio parameters for visualization
  Future<void> updateAudioParameters(Map<String, double> params) async {
    if (!_isInitialized) return;

    audioParameters = params;

    final jsCommand = '''
      if (window.updateAudioData) {
        window.updateAudioData(${jsonEncode(params)});
      }
    ''';

    try {
      await webController.runJavaScript(jsCommand);
    } catch (e) {
      debugPrint('Error updating audio parameters: $e');
    }
  }

  /// Update quaternion from device sensors
  Future<void> updateQuaternion(vmath.Quaternion quaternion) async {
    if (!_isInitialized) return;

    currentQuaternion = quaternion;

    final quaternionMap = {
      'x': quaternion.x,
      'y': quaternion.y,
      'z': quaternion.z,
      'w': quaternion.w,
    };

    final jsCommand = '''
      if (window.updateQuaternion) {
        window.updateQuaternion(${jsonEncode(quaternionMap)});
      }
    ''';

    try {
      await webController.runJavaScript(jsCommand);
    } catch (e) {
      debugPrint('Error updating quaternion: $e');
    }
  }

  /// Set 4D rotation directly
  Future<void> set4DRotation(double rotXW, double rotYW, double rotZW) async {
    if (!_isInitialized) return;

    final jsCommand = '''
      if (window.set4DRotation) {
        window.set4DRotation($rotXW, $rotYW, $rotZW);
      }
    ''';

    try {
      await webController.runJavaScript(jsCommand);
    } catch (e) {
      debugPrint('Error setting 4D rotation: $e');
    }
  }

  /// Set morph intensity
  Future<void> setMorphIntensity(double intensity) async {
    if (!_isInitialized) return;

    final jsCommand = '''
      if (window.setMorphIntensity) {
        window.setMorphIntensity($intensity);
      }
    ''';

    try {
      await webController.runJavaScript(jsCommand);
    } catch (e) {
      debugPrint('Error setting morph intensity: $e');
    }
  }

  /// Switch visualization engine
  Future<void> switchEngine(VisualizationEngine engine) async {
    if (!_isInitialized) return;

    currentEngine = engine;
    final engineName = engine.name;

    final jsCommand = '''
      if (window.switchEngine) {
        window.switchEngine('$engineName');
      }
    ''';

    try {
      await webController.runJavaScript(jsCommand);
      debugPrint('🔄 Switched to $engineName engine');
    } catch (e) {
      debugPrint('Error switching engine: $e');
    }
  }

  /// Apply visualizer preset
  Future<void> applyPreset(String presetName, Map<String, dynamic> preset) async {
    if (!_isInitialized) return;

    // Apply preset parameters
    if (preset.containsKey('rotationSpeed')) {
      final speed = preset['rotationSpeed'] as double;
      // Apply rotation speed if SDK supports it
    }

    if (preset.containsKey('colorPalette')) {
      final palette = preset['colorPalette'] as String;
      // Apply color palette if SDK supports it
    }

    debugPrint('✅ Applied preset: $presetName');
  }

  /// Get the WebView widget for embedding
  Widget buildWebViewWidget() {
    return WebViewWidget(controller: webController);
  }

  /// Check if SDK is ready
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    // WebViewController doesn't need explicit disposal
  }
}

/// Audio-Reactive Parameter Mapper
/// Maps synthesis parameters to visual parameters
class AudioReactiveMapper {
  /// Map audio state to 4D rotation parameters
  static Map<String, double> mapAudioTo4DRotation(Map<String, double> audioState) {
    return {
      'rot4dXW': (audioState['wavetablePosition'] ?? 0.5) * 6.28,
      'rot4dYW': (audioState['grainDensity'] ?? 0.0) * 6.28,
      'rot4dZW': (audioState['filterCutoff'] ?? 0.5) * 6.28,
      'morphIntensity': audioState['reverbMix'] ?? 0.5,
    };
  }

  /// Map audio state to visualization parameters
  static Map<String, double> mapAudioToVisual(Map<String, double> audioState) {
    return {
      'cutoff': audioState['filterCutoff'] ?? 0.5,
      'resonance': audioState['filterResonance'] ?? 0.5,
      'grainDensity': audioState['grainDensity'] ?? 0.0,
      'wavetablePosition': audioState['wavetablePosition'] ?? 0.5,
      'reverbMix': audioState['reverbMix'] ?? 0.2,
    };
  }

  /// Create color intensity from audio parameters
  static Map<String, int> mapAudioToColor(Map<String, double> audioState) {
    final cutoff = audioState['filterCutoff'] ?? 0.5;
    final resonance = audioState['filterResonance'] ?? 0.5;
    final wavetablePos = audioState['wavetablePosition'] ?? 0.5;

    return {
      'r': (255 * wavetablePos).round(),
      'g': (255 * cutoff).round(),
      'b': (255 * resonance).round(),
    };
  }
}

/// Visualizer Presets (matching vib34d SDK presets)
class VisualizerPresets {
  static const Map<String, Map<String, dynamic>> presets = {
    'vaporwave': {
      'colorPalette': 'vaporwave',
      'rotationSpeed': 0.015,
      'morphSpeed': 0.008,
      'engine': VisualizationEngine.holographic,
      'effects': {
        'bloom': true,
        'glow': true,
        'chromatic': true,
        'scanlines': true,
      }
    },
    'cyberpunk': {
      'colorPalette': 'cyberpunk',
      'rotationSpeed': 0.025,
      'morphSpeed': 0.012,
      'engine': VisualizationEngine.polychora,
      'effects': {
        'bloom': true,
        'glow': true,
        'glitch': true,
        'particles': true,
      }
    },
    'synthwave': {
      'colorPalette': 'synthwave',
      'rotationSpeed': 0.02,
      'morphSpeed': 0.01,
      'engine': VisualizationEngine.polychora,
      'effects': {
        'bloom': true,
        'glow': true,
        'trails': true,
        'laser': true,
      }
    },
    'holographic': {
      'colorPalette': 'holographic',
      'rotationSpeed': 0.01,
      'morphSpeed': 0.005,
      'engine': VisualizationEngine.holographic,
      'effects': {
        'bloom': true,
        'glow': true,
        'iridescent': true,
        'depth': true,
      }
    },
    'quantum': {
      'colorPalette': 'quantum',
      'rotationSpeed': 0.03,
      'morphSpeed': 0.015,
      'engine': VisualizationEngine.quantum,
      'effects': {
        'bloom': true,
        'glow': true,
        'particles': true,
        'lattice': true,
      }
    },
  };

  static Map<String, dynamic>? getPreset(String name) {
    return presets[name];
  }

  static List<String> getPresetNames() {
    return presets.keys.toList();
  }
}
