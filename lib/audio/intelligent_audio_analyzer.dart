/// Intelligent Audio Analyzer
/// Performs sophisticated audio analysis for smart visualization reactivity

import 'dart:math' as math;
import 'dart:typed_data';

/// Audio features extracted from analysis
class AudioFeatures {
  // Spectral features
  double spectralCentroid = 0.0;    // Brightness (0-1)
  double spectralFlux = 0.0;         // Change in spectrum
  double spectralRolloff = 0.0;      // High frequency content
  double spectralFlatness = 0.0;     // Noisiness vs tonality

  // Temporal features
  double rms = 0.0;                  // Overall energy
  double peakAmplitude = 0.0;        // Peak level
  double zcr = 0.0;                  // Zero crossing rate

  // Musical features
  double onsetStrength = 0.0;        // Note attack detection
  double rhythmicEnergy = 0.0;       // Rhythmic content
  double harmonicity = 0.0;          // Harmonic vs inharmonic

  // Frequency bands (8 bands logarithmically spaced)
  List<double> bandEnergies = List.filled(8, 0.0);

  // Low/Mid/High analysis
  double lowEnergy = 0.0;            // 20-250 Hz
  double midEnergy = 0.0;            // 250-4000 Hz
  double highEnergy = 0.0;           // 4000-20000 Hz

  // Temporal dynamics
  double attackTime = 0.0;           // How fast energy increases
  double releaseTime = 0.0;          // How fast energy decreases
  double sustainLevel = 0.0;         // Sustained energy level

  AudioFeatures();

  Map<String, dynamic> toMap() {
    return {
      'spectralCentroid': spectralCentroid,
      'spectralFlux': spectralFlux,
      'spectralRolloff': spectralRolloff,
      'spectralFlatness': spectralFlatness,
      'rms': rms,
      'peakAmplitude': peakAmplitude,
      'zcr': zcr,
      'onsetStrength': onsetStrength,
      'rhythmicEnergy': rhythmicEnergy,
      'harmonicity': harmonicity,
      'bandEnergies': bandEnergies,
      'lowEnergy': lowEnergy,
      'midEnergy': midEnergy,
      'highEnergy': highEnergy,
      'attackTime': attackTime,
      'releaseTime': releaseTime,
      'sustainLevel': sustainLevel,
    };
  }
}

/// Intelligent audio analyzer with FFT and spectral analysis
class IntelligentAudioAnalyzer {
  static const int fftSize = 2048;
  static const double sampleRate = 48000.0;

  // Analysis buffers
  final List<double> _audioBuffer = List.filled(fftSize, 0.0);
  final List<double> _fftMagnitudes = List.filled(fftSize ~/ 2, 0.0);
  final List<double> _previousFftMagnitudes = List.filled(fftSize ~/ 2, 0.0);

  // Windowing function (Hann window)
  late List<double> _window;

  // Features
  final AudioFeatures features = AudioFeatures();

  // History for temporal analysis
  final List<double> _rmsHistory = [];
  final List<double> _onsetHistory = [];
  static const int historySize = 10;

  // Band frequency ranges (logarithmic)
  late List<double> _bandFrequencies;

  IntelligentAudioAnalyzer() {
    _initializeWindow();
    _initializeBandFrequencies();
  }

  void _initializeWindow() {
    _window = List.generate(fftSize, (i) {
      // Hann window for smooth spectral analysis
      return 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (fftSize - 1)));
    });
  }

  void _initializeBandFrequencies() {
    // 8 bands: 20-80, 80-160, 160-320, 320-640, 640-1280, 1280-2560, 2560-5120, 5120-10240 Hz
    _bandFrequencies = [20, 80, 160, 320, 640, 1280, 2560, 5120, 10240];
  }

  /// Analyze an audio buffer and extract features
  void analyze(List<double> samples) {
    if (samples.isEmpty) return;

    // Update buffer with new samples
    _updateBuffer(samples);

    // Perform FFT
    _performFFT();

    // Extract spectral features
    _extractSpectralFeatures();

    // Extract temporal features
    _extractTemporalFeatures(samples);

    // Extract musical features
    _extractMusicalFeatures();

    // Update band energies
    _extractBandEnergies();

    // Store history
    _updateHistory();
  }

  void _updateBuffer(List<double> samples) {
    // Shift existing samples and add new ones
    for (int i = 0; i < fftSize - samples.length; i++) {
      _audioBuffer[i] = _audioBuffer[i + samples.length];
    }
    for (int i = 0; i < samples.length; i++) {
      _audioBuffer[fftSize - samples.length + i] = samples[i];
    }
  }

  void _performFFT() {
    // Simplified FFT using DFT (for production, use a proper FFT library)
    // This is computationally expensive but works for demonstration

    // Apply window
    final windowed = List.generate(fftSize, (i) => _audioBuffer[i] * _window[i]);

    // Store previous magnitudes for flux calculation
    for (int i = 0; i < _fftMagnitudes.length; i++) {
      _previousFftMagnitudes[i] = _fftMagnitudes[i];
    }

    // Compute magnitude spectrum (half spectrum due to symmetry)
    for (int k = 0; k < fftSize ~/ 2; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int n = 0; n < fftSize; n++) {
        final angle = -2.0 * math.pi * k * n / fftSize;
        real += windowed[n] * math.cos(angle);
        imag += windowed[n] * math.sin(angle);
      }

      _fftMagnitudes[k] = math.sqrt(real * real + imag * imag) / fftSize;
    }
  }

  void _extractSpectralFeatures() {
    // Spectral centroid (brightness)
    double weightedSum = 0.0;
    double magnitudeSum = 0.0;

    for (int i = 0; i < _fftMagnitudes.length; i++) {
      final frequency = i * sampleRate / fftSize;
      weightedSum += frequency * _fftMagnitudes[i];
      magnitudeSum += _fftMagnitudes[i];
    }

    features.spectralCentroid = magnitudeSum > 0.0
        ? (weightedSum / magnitudeSum) / (sampleRate / 2.0)
        : 0.0;

    // Spectral flux (change in spectrum)
    double flux = 0.0;
    for (int i = 0; i < _fftMagnitudes.length; i++) {
      final diff = _fftMagnitudes[i] - _previousFftMagnitudes[i];
      flux += diff * diff;
    }
    features.spectralFlux = math.sqrt(flux) / _fftMagnitudes.length;

    // Spectral rolloff (high frequency content)
    final threshold = magnitudeSum * 0.85;
    double cumulativeSum = 0.0;
    int rolloffBin = 0;

    for (int i = 0; i < _fftMagnitudes.length; i++) {
      cumulativeSum += _fftMagnitudes[i];
      if (cumulativeSum >= threshold) {
        rolloffBin = i;
        break;
      }
    }

    features.spectralRolloff = rolloffBin / _fftMagnitudes.length.toDouble();

    // Spectral flatness (noisiness)
    double geometricMean = 0.0;
    double arithmeticMean = 0.0;
    int count = 0;

    for (int i = 0; i < _fftMagnitudes.length; i++) {
      if (_fftMagnitudes[i] > 0.0) {
        geometricMean += math.log(_fftMagnitudes[i]);
        arithmeticMean += _fftMagnitudes[i];
        count++;
      }
    }

    if (count > 0) {
      geometricMean = math.exp(geometricMean / count);
      arithmeticMean /= count;
      features.spectralFlatness = arithmeticMean > 0.0
          ? geometricMean / arithmeticMean
          : 0.0;
    }
  }

  void _extractTemporalFeatures(List<double> samples) {
    // RMS (energy)
    double sumSquares = 0.0;
    for (var sample in samples) {
      sumSquares += sample * sample;
    }
    features.rms = math.sqrt(sumSquares / samples.length);

    // Peak amplitude
    features.peakAmplitude = samples.map((s) => s.abs()).reduce(math.max);

    // Zero crossing rate
    int zeroCrossings = 0;
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i - 1] >= 0 && samples[i] < 0) ||
          (samples[i - 1] < 0 && samples[i] >= 0)) {
        zeroCrossings++;
      }
    }
    features.zcr = zeroCrossings / samples.length.toDouble();
  }

  void _extractMusicalFeatures() {
    // Onset strength (note attack detection)
    features.onsetStrength = features.spectralFlux * features.rms;

    // Rhythmic energy (based on temporal variations)
    if (_rmsHistory.isNotEmpty) {
      double variance = 0.0;
      final mean = _rmsHistory.reduce((a, b) => a + b) / _rmsHistory.length;
      for (var rms in _rmsHistory) {
        variance += (rms - mean) * (rms - mean);
      }
      features.rhythmicEnergy = math.sqrt(variance / _rmsHistory.length);
    }

    // Harmonicity (inverse of spectral flatness)
    features.harmonicity = 1.0 - features.spectralFlatness;

    // Attack/Release/Sustain analysis
    if (_rmsHistory.length >= 2) {
      final current = features.rms;
      final previous = _rmsHistory.last;

      if (current > previous) {
        // Attack phase
        features.attackTime = (current - previous).clamp(0.0, 1.0);
        features.releaseTime *= 0.9; // Decay release
      } else {
        // Release phase
        features.releaseTime = (previous - current).clamp(0.0, 1.0);
        features.attackTime *= 0.9; // Decay attack
      }

      features.sustainLevel = features.sustainLevel * 0.95 + current * 0.05;
    }
  }

  void _extractBandEnergies() {
    // Calculate energy in each frequency band
    for (int band = 0; band < 8; band++) {
      final lowFreq = _bandFrequencies[band];
      final highFreq = _bandFrequencies[band + 1];

      final lowBin = (lowFreq * fftSize / sampleRate).round();
      final highBin = (highFreq * fftSize / sampleRate).round();

      double energy = 0.0;
      for (int i = lowBin; i < highBin && i < _fftMagnitudes.length; i++) {
        energy += _fftMagnitudes[i] * _fftMagnitudes[i];
      }

      features.bandEnergies[band] = math.sqrt(energy / (highBin - lowBin));
    }

    // Low/Mid/High energy
    features.lowEnergy = features.bandEnergies.sublist(0, 2).reduce((a, b) => a + b) / 2.0;
    features.midEnergy = features.bandEnergies.sublist(2, 6).reduce((a, b) => a + b) / 4.0;
    features.highEnergy = features.bandEnergies.sublist(6, 8).reduce((a, b) => a + b) / 2.0;
  }

  void _updateHistory() {
    // Update RMS history
    _rmsHistory.add(features.rms);
    if (_rmsHistory.length > historySize) {
      _rmsHistory.removeAt(0);
    }

    // Update onset history
    _onsetHistory.add(features.onsetStrength);
    if (_onsetHistory.length > historySize) {
      _onsetHistory.removeAt(0);
    }
  }

  /// Get current features
  AudioFeatures getFeatures() => features;

  /// Reset analyzer state
  void reset() {
    _audioBuffer.fillRange(0, fftSize, 0.0);
    _fftMagnitudes.fillRange(0, fftSize ~/ 2, 0.0);
    _previousFftMagnitudes.fillRange(0, fftSize ~/ 2, 0.0);
    _rmsHistory.clear();
    _onsetHistory.clear();
  }
}
