/// Phase 2 Enhanced Synther - Deep Audio-Visual Integration
/// Showcases intelligent audio analysis and smart audio-reactive visualization

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'state/synth_app_state.dart';
import 'visualization/vib34d_sdk_wrapper.dart';
import 'audio/smart_audio_visual_mapper.dart';
import 'audio/intelligent_audio_analyzer.dart';

void main() {
  runApp(const Phase2EnhancedSynther());
}

class Phase2EnhancedSynther extends StatelessWidget {
  const Phase2EnhancedSynther({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SynthAppState(),
      child: MaterialApp(
        title: 'Synther Pro - Phase 2: Deep Audio-Visual Integration',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF000010),
          primaryColor: const Color(0xFF00FFFF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00FFFF),
            secondary: Color(0xFFFF00FF),
          ),
        ),
        home: const Phase2MainScreen(),
      ),
    );
  }
}

class Phase2MainScreen extends StatefulWidget {
  const Phase2MainScreen({super.key});

  @override
  State<Phase2MainScreen> createState() => _Phase2MainScreenState();
}

class _Phase2MainScreenState extends State<Phase2MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<SynthAppState>();
      appState.initializeVisualizer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SynthAppState>(
        builder: (context, appState, _) {
          return Stack(
            children: [
              // Visualizer background with intelligent reactivity
              if (appState.showVisualizer && appState.isVisualizerReady)
                Positioned.fill(
                  child: WebViewWidget(
                    controller: appState.visualizer.webController,
                  ),
                ),

              // Main UI overlay
              Positioned.fill(
                child: Column(
                  children: [
                    // Enhanced top bar
                    _buildEnhancedTopBar(context, appState),

                    // Main content area
                    Expanded(
                      child: Row(
                        children: [
                          // Left: Enhanced controls with effects
                          Expanded(
                            flex: 1,
                            child: _buildEnhancedControlPanel(context, appState),
                          ),

                          // Right: Keyboard and audio analysis
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                // Keyboard
                                Expanded(
                                  child: _buildKeyboard(context, appState),
                                ),

                                // Audio analysis display (Phase 2)
                                if (appState.showAudioAnalysis)
                                  _buildAudioAnalysisPanel(context, appState),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom: XY Pad
                    _buildXYPad(context, appState),
                  ],
                ),
              ),

              // Enhanced status overlay with audio features
              Positioned(
                top: 60,
                left: 10,
                child: _buildEnhancedStatusOverlay(appState),
              ),

              // Intelligent mapping indicator
              if (appState.useIntelligentMapping)
                Positioned(
                  top: 60,
                  right: 10,
                  child: _buildIntelligentMappingIndicator(appState),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedTopBar(BuildContext context, SynthAppState appState) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).primaryColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(Icons.waves, color: Color(0xFF00FFFF)),
          const SizedBox(width: 10),
          const Text(
            'PHASE 2: DEEP AUDIO-VISUAL INTEGRATION',
            style: TextStyle(
              color: Color(0xFF00FFFF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),

          // Preset selector
          _buildPresetSelector(appState),
          const SizedBox(width: 10),

          // Intelligent mapping toggle
          IconButton(
            icon: Icon(
              appState.useIntelligentMapping ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: appState.useIntelligentMapping ? const Color(0xFF00FF00) : Colors.grey,
            ),
            onPressed: appState.toggleIntelligentMapping,
            tooltip: 'Toggle intelligent audio-reactive mapping',
          ),

          // Audio analysis toggle
          IconButton(
            icon: Icon(
              appState.showAudioAnalysis ? Icons.graphic_eq : Icons.graphic_eq_outlined,
              color: appState.showAudioAnalysis ? const Color(0xFF00FF00) : Colors.grey,
            ),
            onPressed: appState.toggleAudioAnalysis,
            tooltip: 'Toggle audio analysis display',
          ),

          // Sensor toggle
          IconButton(
            icon: Icon(
              appState.isSensorsActive ? Icons.sensors : Icons.sensors_off,
              color: appState.isSensorsActive ? const Color(0xFF00FF00) : Colors.grey,
            ),
            onPressed: () {
              if (appState.isSensorsActive) {
                appState.stopSensors();
              } else {
                appState.startSensors();
              }
            },
            tooltip: 'Toggle device sensors',
          ),

          // Visualizer toggle
          IconButton(
            icon: Icon(
              appState.showVisualizer ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF00FFFF),
            ),
            onPressed: appState.toggleVisualizer,
            tooltip: 'Toggle visualizer',
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(SynthAppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00FFFF)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButton<String>(
        value: appState.currentPreset,
        dropdownColor: const Color(0xFF001020),
        underline: Container(),
        style: const TextStyle(color: Color(0xFF00FFFF), fontSize: 12),
        items: appState.getDemoPresetNames().map((name) {
          return DropdownMenuItem(value: name, child: Text(name));
        }).toList(),
        onChanged: (name) {
          if (name != null) {
            appState.loadDemoPreset(name);
          }
        },
      ),
    );
  }

  Widget _buildEnhancedStatusOverlay(SynthAppState appState) {
    final features = appState.synthEngine.getAudioFeatures();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusText('SYSTEM STATUS', color: const Color(0xFF00FFFF)),
          const SizedBox(height: 5),
          _statusText('Voices: ${appState.activeVoiceCount}'),
          _statusText('Visualizer: ${appState.isVisualizerReady ? "READY" : "LOADING"}'),
          _statusText('Sensors: ${appState.isSensorsActive ? "ACTIVE" : "OFF"}'),
          _statusText('Engine: ${appState.currentVisualizerEngine.name.toUpperCase()}'),

          const SizedBox(height: 10),
          _statusText('AUDIO ANALYSIS', color: const Color(0xFFFF00FF)),
          const SizedBox(height: 5),
          _statusText('Brightness: ${(features.spectralCentroid * 100).toStringAsFixed(0)}%'),
          _statusText('Harmonicity: ${(features.harmonicity * 100).toStringAsFixed(0)}%'),
          _statusText('Energy: ${(features.rms * 100).toStringAsFixed(0)}%'),

          const SizedBox(height: 10),
          _statusText('MAPPING MODE', color: const Color(0xFFFFFF00)),
          const SizedBox(height: 5),
          _statusText(appState.synthEngine.audioVisualMapper.getModeString()),
        ],
      ),
    );
  }

  Widget _buildIntelligentMappingIndicator(SynthAppState appState) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF00).withOpacity(0.2),
        border: Border.all(color: const Color(0xFF00FF00), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF00FF00), size: 24),
          const SizedBox(height: 5),
          const Text(
            'INTELLIGENT\nMAPPING',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusText(String text, {Color color = Colors.white70}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildEnhancedControlPanel(BuildContext context, SynthAppState appState) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('MASTER'),
            _buildSlider(
              'Volume',
              appState.synthEngine.masterVolume,
              (v) => appState.setMasterVolume(v),
            ),

            const SizedBox(height: 15),
            _buildSectionTitle('FILTER'),
            _buildSlider(
              'Cutoff',
              appState.synthEngine.filterCutoff / 20000.0,
              (v) => appState.setFilterCutoff(v * 20000.0),
            ),
            _buildSlider(
              'Resonance',
              appState.synthEngine.filterResonance,
              (v) => appState.setFilterResonance(v),
            ),

            const SizedBox(height: 15),
            _buildSectionTitle('ENGINE MIX'),
            _buildSlider(
              'Wavetable',
              appState.synthEngine.wavetableMix,
              (v) => appState.setWavetableMix(v),
            ),
            _buildSlider(
              'Granular',
              appState.synthEngine.granularMix,
              (v) => appState.setGranularMix(v),
            ),

            const SizedBox(height: 15),
            _buildSectionTitle('EFFECTS (PHASE 2)', color: const Color(0xFFFF00FF)),
            _buildSlider(
              'Distortion',
              appState.synthEngine.distortionAmount,
              (v) => appState.setDistortionAmount(v),
            ),
            _buildSlider(
              'Delay Time',
              appState.synthEngine.delayTime / 2.0,
              (v) => appState.setDelayTime(v * 2.0),
            ),
            _buildSlider(
              'Delay Feedback',
              appState.synthEngine.delayFeedback,
              (v) => appState.setDelayFeedback(v),
            ),
            _buildSlider(
              'Reverb',
              appState.synthEngine.reverbMix,
              (v) => appState.setReverbMix(v),
            ),

            const SizedBox(height: 15),
            _buildSectionTitle('VISUALIZER'),
            _buildVisualizerEngineSelector(appState),

            const SizedBox(height: 15),
            _buildSectionTitle('MAPPING MODE', color: const Color(0xFFFFFF00)),
            _buildMappingModeSelector(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = const Color(0xFFFF00FF)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF00FFFF), fontSize: 11),
              ),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF00FFFF),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFFFF00FF),
              overlayColor: const Color(0xFF00FFFF).withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerEngineSelector(SynthAppState appState) {
    return Column(
      children: VisualizationEngine.values.map((engine) {
        final isSelected = appState.currentVisualizerEngine == engine;
        return GestureDetector(
          onTap: () => appState.switchVisualizationEngine(engine),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00FFFF).withOpacity(0.2) : null,
              border: Border.all(
                color: isSelected ? const Color(0xFF00FFFF) : Colors.white24,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              engine.name.toUpperCase(),
              style: TextStyle(
                color: isSelected ? const Color(0xFF00FFFF) : Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMappingModeSelector(SynthAppState appState) {
    return Column(
      children: MappingMode.values.map((mode) {
        final isSelected = appState.currentMappingMode == mode;
        return GestureDetector(
          onTap: () => appState.setMappingMode(mode),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFFF00).withOpacity(0.2) : null,
              border: Border.all(
                color: isSelected ? const Color(0xFFFFFF00) : Colors.white24,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              mode.name.toUpperCase(),
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFFF00) : Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAudioAnalysisPanel(BuildContext context, SynthAppState appState) {
    final features = appState.synthEngine.getAudioFeatures();

    return Container(
      height: 150,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: const Color(0xFFFF00FF), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AUDIO FEATURES (REAL-TIME)',
            style: TextStyle(
              color: Color(0xFFFF00FF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                // Frequency bands
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _featureBar('LOW', features.lowEnergy, Colors.red),
                      _featureBar('MID', features.midEnergy, Colors.green),
                      _featureBar('HIGH', features.highEnergy, Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Features
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _featureBar('Bright', features.spectralCentroid, const Color(0xFF00FFFF)),
                      _featureBar('Harmony', features.harmonicity, const Color(0xFF00FF00)),
                      _featureBar('Attack', features.onsetStrength, const Color(0xFFFF0000)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard(BuildContext context, SynthAppState appState) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('KEYBOARD'),
          Expanded(
            child: _buildPianoKeys(appState),
          ),
        ],
      ),
    );
  }

  Widget _buildPianoKeys(SynthAppState appState) {
    final baseNote = 60;
    final octaves = 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = constraints.maxWidth / (octaves * 7);
        final keyHeight = constraints.maxHeight * 0.8;

        return Stack(
          children: [
            // White keys
            Row(
              children: List.generate(octaves * 7, (i) {
                final whiteKeyIndices = [0, 2, 4, 5, 7, 9, 11];
                final octave = i ~/ 7;
                final noteInOctave = whiteKeyIndices[i % 7];
                final midiNote = baseNote + octave * 12 + noteInOctave;

                return _buildKey(
                  context,
                  appState,
                  midiNote,
                  keyWidth,
                  keyHeight,
                  Colors.white,
                  Colors.black,
                );
              }),
            ),
            // Black keys
            ...List.generate(octaves * 5, (i) {
              final blackKeyPattern = [1, 3, 6, 8, 10];
              final octave = i ~/ 5;
              final noteInOctave = blackKeyPattern[i % 5];
              final midiNote = baseNote + octave * 12 + noteInOctave;

              final positionPattern = [0.7, 1.7, 3.3, 4.3, 5.3];
              final xOffset = (octave * 7 + positionPattern[i % 5]) * keyWidth;

              return Positioned(
                left: xOffset,
                top: 0,
                child: _buildKey(
                  context,
                  appState,
                  midiNote,
                  keyWidth * 0.6,
                  keyHeight * 0.6,
                  Colors.black,
                  Colors.white,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildKey(
    BuildContext context,
    SynthAppState appState,
    int midiNote,
    double width,
    double height,
    Color color,
    Color textColor,
  ) {
    return GestureDetector(
      onTapDown: (_) => appState.noteOn(midiNote),
      onTapUp: (_) => appState.noteOff(midiNote),
      onTapCancel: () => appState.noteOff(midiNote),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: const Color(0xFF00FFFF), width: 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FFFF).withOpacity(0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            midiNote.toString(),
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildXYPad(BuildContext context, SynthAppState appState) {
    return Container(
      height: 150,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('XY CONTROL PAD'),
                if (appState.useIntelligentMapping)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00).withOpacity(0.2),
                      border: Border.all(color: const Color(0xFF00FF00)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'AUTO-MAPPED',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final x = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                final y = 1.0 - (localPosition.dy / box.size.height).clamp(0.0, 1.0);
                appState.setXYPad(x, y);
              },
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    colors: [
                      const Color(0xFF00FFFF).withOpacity(0.3),
                      const Color(0xFFFF00FF).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(color: const Color(0xFF00FFFF), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white.withOpacity(0.3),
                        size: 50,
                      ),
                    ),
                    Positioned(
                      left: appState.synthEngine.modulationMatrix.xyPadX * 300 - 10,
                      top: (1.0 - appState.synthEngine.modulationMatrix.xyPadY) * 100 - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF00FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00FFFF), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF00FF).withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
