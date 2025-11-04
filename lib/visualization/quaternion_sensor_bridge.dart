/// Quaternion Sensor Bridge
/// Converts Flutter device sensors to quaternion data for XR visualization

import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math.dart';

class QuaternionSensorBridge {
  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Current orientation as quaternion
  Quaternion deviceOrientation = Quaternion.identity();

  // Sensor data
  Vector3 acceleration = Vector3.zero();
  Vector3 gyroscope = Vector3.zero();

  // Complementary filter parameters
  static const double alpha = 0.98; // Weight for gyroscope
  final double sampleRate = 60.0; // Hz

  // Callbacks
  Function(Quaternion)? onOrientationUpdate;

  // State
  bool _isRunning = false;
  DateTime? _lastUpdate;

  /// Start listening to device sensors
  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    _lastUpdate = DateTime.now();

    // Subscribe to accelerometer
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      acceleration = Vector3(event.x, event.y, event.z);
      _updateOrientation();
    });

    // Subscribe to gyroscope
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      gyroscope = Vector3(event.x, event.y, event.z);
      _updateOrientation();
    });
  }

  /// Stop listening to sensors
  void stop() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
    _isRunning = false;
  }

  /// Update orientation using complementary filter
  void _updateOrientation() {
    final now = DateTime.now();
    final dt = _lastUpdate != null
        ? (now.difference(_lastUpdate!).inMicroseconds / 1000000.0)
        : (1.0 / sampleRate);
    _lastUpdate = now;

    // Get quaternion from accelerometer (gravity direction)
    final accelQuat = _quaternionFromAccelerometer(acceleration);

    // Get quaternion delta from gyroscope
    final gyroQuat = _quaternionFromGyroscope(gyroscope, dt);

    // Complementary filter: combine gyro and accel
    deviceOrientation = _slerp(
      deviceOrientation * gyroQuat,
      accelQuat,
      1.0 - alpha,
    );

    // Normalize to prevent drift
    deviceOrientation.normalize();

    // Notify callback
    onOrientationUpdate?.call(deviceOrientation);
  }

  /// Convert accelerometer data to quaternion (using gravity)
  Quaternion _quaternionFromAccelerometer(Vector3 accel) {
    // Normalize acceleration
    final norm = accel.length;
    if (norm < 0.1) return Quaternion.identity();

    final normalized = accel / norm;

    // Calculate pitch and roll from gravity
    final pitch = math.atan2(normalized.y, normalized.z);
    final roll = math.atan2(-normalized.x, math.sqrt(normalized.y * normalized.y + normalized.z * normalized.z));

    // Convert to quaternion (yaw is assumed 0)
    return _eulerToQuaternion(roll, pitch, 0.0);
  }

  /// Convert gyroscope data to quaternion delta
  Quaternion _quaternionFromGyroscope(Vector3 gyro, double dt) {
    // Gyroscope gives angular velocity in rad/s
    final angle = gyro.length * dt;

    if (angle < 0.0001) return Quaternion.identity();

    // Axis of rotation
    final axis = gyro.normalized();

    // Create quaternion from axis-angle
    return Quaternion.axisAngle(axis, angle);
  }

  /// Convert Euler angles to quaternion
  Quaternion _eulerToQuaternion(double roll, double pitch, double yaw) {
    final cy = math.cos(yaw * 0.5);
    final sy = math.sin(yaw * 0.5);
    final cp = math.cos(pitch * 0.5);
    final sp = math.sin(pitch * 0.5);
    final cr = math.cos(roll * 0.5);
    final sr = math.sin(roll * 0.5);

    return Quaternion(
      sr * cp * cy - cr * sp * sy, // x
      cr * sp * cy + sr * cp * sy, // y
      cr * cp * sy - sr * sp * cy, // z
      cr * cp * cy + sr * sp * sy, // w
    );
  }

  /// Spherical linear interpolation between quaternions
  Quaternion _slerp(Quaternion q1, Quaternion q2, double t) {
    // Normalize inputs
    q1.normalize();
    q2.normalize();

    // Calculate dot product
    double dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w;

    // If negative dot, negate one quaternion to take shorter path
    if (dot < 0.0) {
      q2 = Quaternion(-q2.x, -q2.y, -q2.z, -q2.w);
      dot = -dot;
    }

    // If quaternions are very close, use linear interpolation
    if (dot > 0.9995) {
      return Quaternion(
        q1.x + t * (q2.x - q1.x),
        q1.y + t * (q2.y - q1.y),
        q1.z + t * (q2.z - q1.z),
        q1.w + t * (q2.w - q1.w),
      )..normalize();
    }

    // Calculate angle and perform slerp
    final theta0 = math.acos(dot);
    final theta = theta0 * t;
    final sinTheta = math.sin(theta);
    final sinTheta0 = math.sin(theta0);

    final s0 = math.cos(theta) - dot * sinTheta / sinTheta0;
    final s1 = sinTheta / sinTheta0;

    return Quaternion(
      s0 * q1.x + s1 * q2.x,
      s0 * q1.y + s1 * q2.y,
      s0 * q1.z + s1 * q2.z,
      s0 * q1.w + s1 * q2.w,
    );
  }

  /// Get current orientation as Euler angles (for debugging)
  Vector3 getEulerAngles() {
    // Extract Euler angles from quaternion
    final q = deviceOrientation;

    // Roll (x-axis rotation)
    final sinr_cosp = 2.0 * (q.w * q.x + q.y * q.z);
    final cosr_cosp = 1.0 - 2.0 * (q.x * q.x + q.y * q.y);
    final roll = math.atan2(sinr_cosp, cosr_cosp);

    // Pitch (y-axis rotation)
    final sinp = 2.0 * (q.w * q.y - q.z * q.x);
    final pitch = sinp.abs() >= 1.0
        ? (math.pi / 2.0) * sinp.sign // Use 90 degrees if out of range
        : math.asin(sinp);

    // Yaw (z-axis rotation)
    final siny_cosp = 2.0 * (q.w * q.z + q.x * q.y);
    final cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z);
    final yaw = math.atan2(siny_cosp, cosy_cosp);

    return Vector3(roll, pitch, yaw);
  }

  /// Get current quaternion as map for JSON encoding
  Map<String, double> getQuaternionMap() {
    return {
      'x': deviceOrientation.x,
      'y': deviceOrientation.y,
      'z': deviceOrientation.z,
      'w': deviceOrientation.w,
    };
  }

  /// Get 4D rotation parameters for vib34d SDK
  Map<String, double> get4DRotationParameters() {
    // Map device orientation to 4D rotations
    final euler = getEulerAngles();

    return {
      'rot4dXW': euler.x * 2.0, // Roll → XW rotation
      'rot4dYW': euler.y * 2.0, // Pitch → YW rotation
      'rot4dZW': euler.z * 2.0, // Yaw → ZW rotation
    };
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}

/// Audio-Reactive Quaternion Generator
/// Generates quaternion rotations based on audio parameters
class AudioReactiveQuaternionGenerator {
  Quaternion currentRotation = Quaternion.identity();
  double rotationSpeed = 1.0;

  /// Update rotation based on audio parameters
  void update(Map<String, double> audioParams, double dt) {
    // Extract audio parameters
    final cutoff = audioParams['filterCutoff'] ?? 0.5;
    final resonance = audioParams['filterResonance'] ?? 0.5;
    final wavetablePos = audioParams['wavetablePosition'] ?? 0.5;
    final grainDensity = audioParams['grainDensity'] ?? 0.5;

    // Map to rotation axes
    final xRotation = cutoff * rotationSpeed * dt;
    final yRotation = resonance * rotationSpeed * dt;
    final zRotation = wavetablePos * rotationSpeed * dt;
    final wRotation = grainDensity * rotationSpeed * dt;

    // Create rotation quaternions for each 4D plane
    final quatXW = Quaternion.axisAngle(Vector3(1, 0, 0), xRotation);
    final quatYW = Quaternion.axisAngle(Vector3(0, 1, 0), yRotation);
    final quatZW = Quaternion.axisAngle(Vector3(0, 0, 1), zRotation);

    // Combine rotations
    currentRotation = currentRotation * quatXW * quatYW * quatZW;
    currentRotation.normalize();
  }

  /// Get 4D rotation parameters
  Map<String, double> get4DRotationParameters() {
    final euler = _quaternionToEuler(currentRotation);

    return {
      'rot4dXW': euler.x,
      'rot4dYW': euler.y,
      'rot4dZW': euler.z,
    };
  }

  Vector3 _quaternionToEuler(Quaternion q) {
    final sinr_cosp = 2.0 * (q.w * q.x + q.y * q.z);
    final cosr_cosp = 1.0 - 2.0 * (q.x * q.x + q.y * q.y);
    final roll = math.atan2(sinr_cosp, cosr_cosp);

    final sinp = 2.0 * (q.w * q.y - q.z * q.x);
    final pitch = sinp.abs() >= 1.0
        ? (math.pi / 2.0) * sinp.sign
        : math.asin(sinp);

    final siny_cosp = 2.0 * (q.w * q.z + q.x * q.y);
    final cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z);
    final yaw = math.atan2(siny_cosp, cosy_cosp);

    return Vector3(roll, pitch, yaw);
  }

  void reset() {
    currentRotation = Quaternion.identity();
  }
}
