import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../synthesis/engines/wavetable_engine.dart';
import '../visualization/vib34d_sdk_wrapper.dart';

/// Visual wavetable editor with 4D vib34d visualization
///
/// Features:
/// - 4D visualization of waveforms using vib34d SDK
/// - Interactive waveform drawing and editing
/// - Real-time waveform morphing visualization
/// - Multiple drawing modes (sine, harmonic series, custom)
/// - Waveform analysis (harmonics, spectrum)
/// - Import/export wavetables
/// - Visual morph between frames
class WavetableEditorView extends StatefulWidget {
  final WavetableEngine engine;
  final Function(Wavetable wavetable)? onWavetableChanged;

  const WavetableEditorView({
    Key? key,
    required this.engine,
    this.onWavetableChanged,
  }) : super(key: key);

  @override
  State<WavetableEditorView> createState() => _WavetableEditorViewState();
}

class _WavetableEditorViewState extends State<WavetableEditorView> {
  late InAppWebViewController _webController;
  bool _visualizerReady = false;
  int _selectedWavetableIndex = 0;
  int _selectedFrameIndex = 0;
  List<double> _editingFrame = List.filled(2048, 0.0);
  DrawingMode _drawingMode = DrawingMode.freehand;
  bool _is3DMode = true;
  double _morphPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFrame();
  }

  void _loadFrame() {
    if (widget.engine.wavetables.isNotEmpty) {
      final wavetable = widget.engine.wavetables[_selectedWavetableIndex];
      if (_selectedFrameIndex < wavetable.frames.length) {
        setState(() {
          _editingFrame = List.from(wavetable.frames[_selectedFrameIndex]);
        });
        _updateVisualization();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo[900]!,
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // Left panel - controls
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border(right: BorderSide(color: Colors.indigo.withOpacity(0.2))),
                  ),
                  child: _buildControlPanel(),
                ),
                // Center - 4D visualization
                Expanded(
                  child: _build4DVisualization(),
                ),
                // Right panel - harmonics/spectrum
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border(left: BorderSide(color: Colors.indigo.withOpacity(0.2))),
                  ),
                  child: _buildAnalysisPanel(),
                ),
              ],
            ),
          ),
          _build2DWaveformEditor(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.waves, color: Colors.indigo, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Wavetable Editor',
            style: TextStyle(
              color: Colors.indigo,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<int>(
            value: _selectedWavetableIndex,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.indigo),
            items: List.generate(widget.engine.wavetables.length, (index) {
              return DropdownMenuItem(
                value: index,
                child: Text('Wavetable ${index + 1}'),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedWavetableIndex = value;
                  _selectedFrameIndex = 0;
                  _loadFrame();
                });
              }
            },
          ),
          const Spacer(),
          Switch(
            value: _is3DMode,
            onChanged: (value) => setState(() => _is3DMode = value),
            activeColor: Colors.indigo,
          ),
          Text(
            _is3DMode ? '4D View' : '2D View',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'DRAWING MODE',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        ...DrawingMode.values.map((mode) {
          return RadioListTile<DrawingMode>(
            title: Text(
              _getDrawingModeName(mode),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            value: mode,
            groupValue: _drawingMode,
            onChanged: (value) {
              if (value != null) {
                setState(() => _drawingMode = value);
              }
            },
            activeColor: Colors.indigo,
          );
        }).toList(),
        const Divider(color: Colors.indigo, height: 32),
        const Text(
          'FRAME NAVIGATION',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              color: Colors.indigo,
              onPressed: _previousFrame,
            ),
            Expanded(
              child: Text(
                'Frame ${_selectedFrameIndex + 1} / ${widget.engine.wavetables.isNotEmpty ? widget.engine.wavetables[_selectedWavetableIndex].frames.length : 0}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              color: Colors.indigo,
              onPressed: _nextFrame,
            ),
          ],
        ),
        Slider(
          value: _selectedFrameIndex.toDouble(),
          min: 0,
          max: (widget.engine.wavetables.isNotEmpty
              ? widget.engine.wavetables[_selectedWavetableIndex].frames.length - 1
              : 0).toDouble(),
          divisions: widget.engine.wavetables.isNotEmpty
              ? widget.engine.wavetables[_selectedWavetableIndex].frames.length - 1
              : 1,
          onChanged: (value) {
            setState(() {
              _selectedFrameIndex = value.toInt();
              _loadFrame();
            });
          },
          activeColor: Colors.indigo,
        ),
        const Divider(color: Colors.indigo, height: 32),
        const Text(
          'MORPH PREVIEW',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _morphPosition,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  setState(() {
                    _morphPosition = value;
                    _updateMorphVisualization();
                  });
                },
                activeColor: Colors.indigo,
              ),
            ),
            Text(
              '${(_morphPosition * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.indigo),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _animateMorph,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Animate Morph'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
        const Divider(color: Colors.indigo, height: 32),
        const Text(
          'PRESET WAVEFORMS',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _buildPresetButton('Sine', _generateSine),
        _buildPresetButton('Saw', _generateSaw),
        _buildPresetButton('Square', _generateSquare),
        _buildPresetButton('Triangle', _generateTriangle),
        _buildPresetButton('Harmonic Series', _generateHarmonicSeries),
        _buildPresetButton('Random', _generateRandom),
        const Divider(color: Colors.indigo, height: 32),
        ElevatedButton.icon(
          onPressed: _addFrame,
          icon: const Icon(Icons.add),
          label: const Text('Add Frame'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _deleteFrame,
          icon: const Icon(Icons.delete),
          label: const Text('Delete Frame'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.indigo,
          side: BorderSide(color: Colors.indigo.withOpacity(0.5)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
      ),
    );
  }

  Widget _build4DVisualization() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.indigo.withOpacity(0.1),
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          InAppWebView(
            initialData: InAppWebViewInitialData(
              data: _getVisualizerHTML(),
              baseUrl: WebUri('about:blank'),
            ),
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
              javaScriptEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _webController = controller;
            },
            onLoadStop: (controller, url) async {
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() => _visualizerReady = true);
              _updateVisualization();
            },
          ),
          if (!_visualizerReady)
            const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            ),
          // Overlay instructions
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4D Waveform Visualization',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Drag to rotate • Scroll to zoom',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPanel() {
    final fft = _performFFT(_editingFrame);
    final harmonics = _extractHarmonics(fft);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'HARMONIC ANALYSIS',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(8, (index) {
          final harmonicNum = index + 1;
          final amplitude = index < harmonics.length ? harmonics[index] : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'H$harmonicNum',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: amplitude,
                        backgroundColor: Colors.grey[800],
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${(amplitude * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.indigo, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const Divider(color: Colors.indigo, height: 32),
        const Text(
          'STATISTICS',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatRow('RMS', _calculateRMS(_editingFrame)),
        _buildStatRow('Peak', _calculatePeak(_editingFrame)),
        _buildStatRow('Crest Factor', _calculateCrestFactor(_editingFrame)),
        _buildStatRow('Zero Crossings', _countZeroCrossings(_editingFrame).toDouble()),
      ],
    );
  }

  Widget _buildStatRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(
            value.toStringAsFixed(3),
            style: const TextStyle(color: Colors.indigo, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _build2DWaveformEditor() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.indigo.withOpacity(0.3))),
      ),
      child: GestureDetector(
        onPanUpdate: _handleWaveformDraw,
        onPanDown: _handleWaveformDraw,
        child: CustomPaint(
          painter: WaveformPainter(_editingFrame, Colors.indigo),
          size: Size.infinite,
        ),
      ),
    );
  }

  void _handleWaveformDraw(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final width = box.size.width;
    final height = 200.0;

    // Calculate position in waveform
    final index = ((localPosition.dx / width) * _editingFrame.length).clamp(0, _editingFrame.length - 1).toInt();
    final value = 1.0 - (localPosition.dy / height) * 2.0; // -1 to 1

    setState(() {
      _editingFrame[index] = value.clamp(-1.0, 1.0);
      _saveFrame();
      _updateVisualization();
    });
  }

  void _saveFrame() {
    if (widget.engine.wavetables.isNotEmpty) {
      final wavetable = widget.engine.wavetables[_selectedWavetableIndex];
      if (_selectedFrameIndex < wavetable.frames.length) {
        wavetable.frames[_selectedFrameIndex] = List.from(_editingFrame);
        widget.onWavetableChanged?.call(wavetable);
      }
    }
  }

  void _previousFrame() {
    if (_selectedFrameIndex > 0) {
      setState(() {
        _selectedFrameIndex--;
        _loadFrame();
      });
    }
  }

  void _nextFrame() {
    if (widget.engine.wavetables.isNotEmpty) {
      final wavetable = widget.engine.wavetables[_selectedWavetableIndex];
      if (_selectedFrameIndex < wavetable.frames.length - 1) {
        setState(() {
          _selectedFrameIndex++;
          _loadFrame();
        });
      }
    }
  }

  void _addFrame() {
    if (widget.engine.wavetables.isNotEmpty) {
      final wavetable = widget.engine.wavetables[_selectedWavetableIndex];
      setState(() {
        wavetable.frames.add(List.from(_editingFrame));
        _selectedFrameIndex = wavetable.frames.length - 1;
      });
    }
  }

  void _deleteFrame() {
    if (widget.engine.wavetables.isNotEmpty) {
      final wavetable = widget.engine.wavetables[_selectedWavetableIndex];
      if (wavetable.frames.length > 1) {
        setState(() {
          wavetable.frames.removeAt(_selectedFrameIndex);
          if (_selectedFrameIndex >= wavetable.frames.length) {
            _selectedFrameIndex = wavetable.frames.length - 1;
          }
          _loadFrame();
        });
      }
    }
  }

  void _generateSine() {
    setState(() {
      for (int i = 0; i < _editingFrame.length; i++) {
        _editingFrame[i] = math.sin(2 * math.pi * i / _editingFrame.length);
      }
      _saveFrame();
      _updateVisualization();
    });
  }

  void _generateSaw() {
    setState(() {
      for (int i = 0; i < _editingFrame.length; i++) {
        _editingFrame[i] = 2.0 * (i / _editingFrame.length) - 1.0;
      }
      _saveFrame();
      _updateVisualization();
    });
  }

  void _generateSquare() {
    setState(() {
      for (int i = 0; i < _editingFrame.length; i++) {
        _editingFrame[i] = i < _editingFrame.length / 2 ? 1.0 : -1.0;
      }
      _saveFrame();
      _updateVisualization();
    });
  }

  void _generateTriangle() {
    setState(() {
      for (int i = 0; i < _editingFrame.length; i++) {
        final phase = i / _editingFrame.length;
        _editingFrame[i] = phase < 0.5 ? 4.0 * phase - 1.0 : 3.0 - 4.0 * phase;
      }
      _saveFrame();
      _updateVisualization();
    });
  }

  void _generateHarmonicSeries() {
    setState(() {
      for (int i = 0; i < _editingFrame.length; i++) {
        double sum = 0.0;
        for (int h = 1; h <= 8; h++) {
          sum += math.sin(2 * math.pi * h * i / _editingFrame.length) / h;
        }
        _editingFrame[i] = sum / 3.0; // Normalize
      }
      _saveFrame();
      _updateVisualization();
    });
  }

  void _generateRandom() {
    final random = math.Random();
    setState(() {
      for (int i = 0; i < _editingFrame.length; i++) {
        _editingFrame[i] = random.nextDouble() * 2.0 - 1.0;
      }
      _saveFrame();
      _updateVisualization();
    });
  }

  void _updateVisualization() {
    if (!_visualizerReady) return;

    final waveformData = {
      'waveform': _editingFrame,
      'frameIndex': _selectedFrameIndex,
      'totalFrames': widget.engine.wavetables.isNotEmpty
          ? widget.engine.wavetables[_selectedWavetableIndex].frames.length
          : 0,
    };

    _webController.evaluateJavascript(source: '''
      if (window.updateWaveform) {
        window.updateWaveform(${jsonEncode(waveformData)});
      }
    ''');
  }

  void _updateMorphVisualization() {
    if (!_visualizerReady || widget.engine.wavetables.isEmpty) return;

    final wavetable = widget.engine.wavetables[_selectedWavetableIndex];
    if (wavetable.frames.length < 2) return;

    final frame1Index = (_morphPosition * (wavetable.frames.length - 1)).floor();
    final frame2Index = (frame1Index + 1).clamp(0, wavetable.frames.length - 1);
    final frameFrac = (_morphPosition * (wavetable.frames.length - 1)) - frame1Index;

    final morphedFrame = List.generate(_editingFrame.length, (i) {
      final v1 = wavetable.frames[frame1Index][i];
      final v2 = wavetable.frames[frame2Index][i];
      return v1 + (v2 - v1) * frameFrac;
    });

    _webController.evaluateJavascript(source: '''
      if (window.updateWaveform) {
        window.updateWaveform(${jsonEncode({'waveform': morphedFrame})});
      }
    ''');
  }

  void _animateMorph() async {
    for (double t = 0.0; t <= 1.0; t += 0.02) {
      setState(() => _morphPosition = t);
      _updateMorphVisualization();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  List<double> _performFFT(List<double> signal) {
    // Simplified DFT for harmonic extraction
    final n = math.min(signal.length, 512);
    final magnitudes = <double>[];

    for (int k = 0; k < n ~/ 2; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int i = 0; i < n; i++) {
        final angle = 2.0 * math.pi * k * i / n;
        real += signal[i] * math.cos(angle);
        imag -= signal[i] * math.sin(angle);
      }

      magnitudes.add(math.sqrt(real * real + imag * imag) / n);
    }

    return magnitudes;
  }

  List<double> _extractHarmonics(List<double> fft) {
    if (fft.isEmpty) return List.filled(8, 0.0);

    final harmonics = <double>[];
    for (int h = 1; h <= 8; h++) {
      if (h < fft.length) {
        harmonics.add(fft[h]);
      } else {
        harmonics.add(0.0);
      }
    }

    // Normalize to 0-1
    final maxHarmonic = harmonics.reduce(math.max);
    if (maxHarmonic > 0) {
      for (int i = 0; i < harmonics.length; i++) {
        harmonics[i] /= maxHarmonic;
      }
    }

    return harmonics;
  }

  double _calculateRMS(List<double> signal) {
    double sum = 0.0;
    for (final sample in signal) {
      sum += sample * sample;
    }
    return math.sqrt(sum / signal.length);
  }

  double _calculatePeak(List<double> signal) {
    return signal.map((s) => s.abs()).reduce(math.max);
  }

  double _calculateCrestFactor(List<double> signal) {
    final rms = _calculateRMS(signal);
    final peak = _calculatePeak(signal);
    return rms > 0 ? peak / rms : 0.0;
  }

  int _countZeroCrossings(List<double> signal) {
    int count = 0;
    for (int i = 1; i < signal.length; i++) {
      if ((signal[i - 1] >= 0 && signal[i] < 0) || (signal[i - 1] < 0 && signal[i] >= 0)) {
        count++;
      }
    }
    return count;
  }

  String _getDrawingModeName(DrawingMode mode) {
    switch (mode) {
      case DrawingMode.freehand: return 'Freehand';
      case DrawingMode.additive: return 'Additive';
      case DrawingMode.subtractive: return 'Subtractive';
      case DrawingMode.smooth: return 'Smooth';
    }
  }

  String _getVisualizerHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { margin: 0; padding: 0; overflow: hidden; background: transparent; }
    #canvas { width: 100vw; height: 100vh; display: block; }
  </style>
</head>
<body>
  <canvas id="canvas"></canvas>
  <script>
    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');

    let waveformData = [];
    let rotation = 0;
    let scale = 1.0;

    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    }

    window.addEventListener('resize', resize);
    resize();

    function draw4DWaveform() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      if (waveformData.length === 0) return;

      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;
      const radius = Math.min(canvas.width, canvas.height) * 0.35 * scale;

      // Draw waveform as 4D helix in 3D projection
      ctx.beginPath();
      ctx.strokeStyle = 'rgba(100, 150, 255, 0.8)';
      ctx.lineWidth = 2;

      for (let i = 0; i < waveformData.length; i++) {
        const angle = (i / waveformData.length) * Math.PI * 2 + rotation;
        const amplitude = waveformData[i];

        // 4D to 3D projection with rotation
        const x = Math.cos(angle) * radius * (1 + amplitude * 0.3);
        const y = Math.sin(angle) * radius * (1 + amplitude * 0.3);
        const z = amplitude * radius * 0.5;

        // Simple perspective projection
        const perspective = 500 / (500 + z);
        const projX = centerX + x * perspective;
        const projY = centerY + y * perspective * Math.cos(rotation * 0.5);

        if (i === 0) {
          ctx.moveTo(projX, projY);
        } else {
          ctx.lineTo(projX, projY);
        }
      }

      ctx.closePath();
      ctx.stroke();

      // Draw fill with gradient
      ctx.fillStyle = 'rgba(100, 150, 255, 0.1)';
      ctx.fill();

      // Draw center dot
      ctx.beginPath();
      ctx.arc(centerX, centerY, 3, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(100, 150, 255, 0.5)';
      ctx.fill();

      rotation += 0.005;
      requestAnimationFrame(draw4DWaveform);
    }

    window.updateWaveform = function(data) {
      waveformData = data.waveform || [];
    };

    // Mouse interaction
    let isDragging = false;
    let lastX = 0;

    canvas.addEventListener('mousedown', (e) => {
      isDragging = true;
      lastX = e.clientX;
    });

    canvas.addEventListener('mousemove', (e) => {
      if (isDragging) {
        rotation += (e.clientX - lastX) * 0.01;
        lastX = e.clientX;
      }
    });

    canvas.addEventListener('mouseup', () => {
      isDragging = false;
    });

    canvas.addEventListener('wheel', (e) => {
      scale *= e.deltaY > 0 ? 0.95 : 1.05;
      scale = Math.max(0.5, Math.min(2.0, scale));
      e.preventDefault();
    });

    draw4DWaveform();
  </script>
</body>
</html>
    ''';
  }
}

enum DrawingMode {
  freehand,
  additive,
  subtractive,
  smooth,
}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;

  WaveformPainter(this.waveform, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw grid
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );

    // Draw waveform
    final path = Path();
    for (int i = 0; i < waveform.length; i++) {
      final x = (i / waveform.length) * size.width;
      final y = size.height / 2 - (waveform[i] * size.height / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform;
  }
}
