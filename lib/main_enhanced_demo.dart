/// Enhanced Synther Demo Application
/// Demonstrates all Phase 1 features

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'state/synth_app_state.dart';
import 'visualization/vib34d_sdk_wrapper.dart';

void main() {
  runApp(const EnhancedSyntherDemo());
}

class EnhancedSyntherDemo extends StatelessWidget {
  const EnhancedSyntherDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SynthAppState(),
      child: MaterialApp(
        title: 'Synther Professional Holographic - Enhanced',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF000010),
          primaryColor: const Color(0xFF00FFFF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00FFFF),
            secondary: Color(0xFFFF00FF),
          ),
        ),
        home: const SynthMainScreen(),
      ),
    );
  }
}

class SynthMainScreen extends StatefulWidget {
  const SynthMainScreen({super.key});

  @override
  State<SynthMainScreen> createState() => _SynthMainScreenState();
}

class _SynthMainScreenState extends State<SynthMainScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize visualizer after first frame
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
              // Visualizer background
              if (appState.showVisualizer && appState.isVisualizerReady)
                Positioned.fill(
                  child: WebViewWidget(
                    controller: appState.visualizer.webController,
                  ),
                ),

              // Main UI
              Positioned.fill(
                child: Column(
                  children: [
                    // Top bar
                    _buildTopBar(context, appState),

                    // Main content
                    Expanded(
                      child: Row(
                        children: [
                          // Left panel - Controls
                          Expanded(
                            flex: 1,
                            child: _buildControlPanel(context, appState),
                          ),

                          // Right panel - Keyboard
                          Expanded(
                            flex: 1,
                            child: _buildKeyboard(context, appState),
                          ),
                        ],
                      ),
                    ),

                    // Bottom panel - XY Pad
                    _buildXYPad(context, appState),
                  ],
                ),
              ),

              // Status overlay
              Positioned(
                top: 60,
                left: 10,
                child: _buildStatusOverlay(appState),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, SynthAppState appState) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).primaryColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          const Icon(Icons.graphic_eq, color: Color(0xFF00FFFF)),
          const SizedBox(width: 10),
          const Text(
            'SYNTHER PROFESSIONAL HOLOGRAPHIC',
            style: TextStyle(
              color: Color(0xFF00FFFF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Preset selector
          _buildPresetSelector(appState),
          const SizedBox(width: 10),
          // Sensor toggle
          IconButton(
            icon: Icon(
              appState.isSensorsActive ? Icons.sensors : Icons.sensors_off,
              color: appState.isSensorsActive
                  ? const Color(0xFF00FF00)
                  : Colors.grey,
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

  Widget _buildStatusOverlay(SynthAppState appState) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusText('Voices: ${appState.activeVoiceCount}'),
          _statusText('Visualizer: ${appState.isVisualizerReady ? "READY" : "LOADING"}'),
          _statusText('Sensors: ${appState.isSensorsActive ? "ACTIVE" : "OFF"}'),
          _statusText('Engine: ${appState.currentVisualizerEngine.name.toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _statusText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF00FFFF),
        fontSize: 10,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, SynthAppState appState) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
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

            const SizedBox(height: 20),
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

            const SizedBox(height: 20),
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

            const SizedBox(height: 20),
            _buildSectionTitle('EFFECTS'),
            _buildSlider(
              'Reverb',
              appState.synthEngine.reverbMix,
              (v) => appState.setReverbMix(v),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('VISUALIZER'),
            _buildVisualizerEngineSelector(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFF00FF),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF00FFFF), fontSize: 12),
              ),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 5),
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
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                fontSize: 11,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyboard(BuildContext context, SynthAppState appState) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
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
    // Simple 2-octave keyboard (C4 to C6)
    final baseNote = 60; // C4
    final octaves = 2;
    final totalKeys = octaves * 12;

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
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSectionTitle('XY CONTROL PAD'),
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
                      const Color(0xFF00FFFF).withOpacity(0.2),
                      const Color(0xFFFF00FF).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(color: const Color(0xFF00FFFF), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Crosshair
                    Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white.withOpacity(0.3),
                        size: 50,
                      ),
                    ),
                    // Current position indicator
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
