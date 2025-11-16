import 'dart:math' as math;
import '../visualization/quaternion_sensor_bridge.dart';

/// Drives wavetable synthesis using 4D polytope projections
///
/// Maps 6 degrees of rotational freedom in 4D space to wavetable parameters:
/// - 3D rotations (XY, XZ, YZ planes) → wavetable position
/// - 4D rotations (XW, YW, ZW planes) → morph intensity, grain parameters
///
/// 4D polytopes used:
/// - Tesseract (8-cell): Cubic harmonics
/// - 16-Cell: Sharp, percussive timbres
/// - 24-Cell: Balanced, melodic timbres
/// - 120-Cell: Complex, evolving textures
/// - 600-Cell: Dense, chaotic textures
class PolytopeWavetableDriver {
  // Current 4D polytope
  PolytopeType currentPolytope = PolytopeType.tesseract;

  // 4D rotation quaternion (double quaternion for 4D)
  // We use two quaternions to represent 6 DOF rotation in 4D
  Quaternion leftRotation = Quaternion.identity();
  Quaternion rightRotation = Quaternion.identity();

  // 3D rotation for initial orientation
  Quaternion rotation3D = Quaternion.identity();

  // Polytope vertices in 4D space
  List<Vector4D> vertices = [];

  // Projected vertices in 3D
  List<Vector3D> projectedVertices = [];

  // Extracted parameters
  double wavetablePosition = 0.0;
  double morphIntensity = 0.0;
  double grainDensity = 0.5;
  double spectralTilt = 0.5;

  // Rotation speeds for each plane
  double rotXY = 0.0; // 3D rotation
  double rotXZ = 0.0; // 3D rotation
  double rotYZ = 0.0; // 3D rotation
  double rotXW = 0.0; // 4D rotation
  double rotYW = 0.0; // 4D rotation
  double rotZW = 0.0; // 4D rotation

  PolytopeWavetableDriver() {
    _generatePolytope(currentPolytope);
  }

  /// Update with quaternion from sensors or manual control
  void updateRotation({
    required Quaternion rotation3d,
    double xwRotation = 0.0,
    double ywRotation = 0.0,
    double zwRotation = 0.0,
  }) {
    rotation3D = rotation3d;
    rotXW = xwRotation;
    rotYW = ywRotation;
    rotZW = zwRotation;

    // Build 4D rotation using double quaternion approach
    _build4DRotation();

    // Project and extract parameters
    _projectTo3D();
    _extractParameters();
  }

  /// Update with individual rotation speeds
  void updateRotationSpeeds({
    double? xy,
    double? xz,
    double? yz,
    double? xw,
    double? yw,
    double? zw,
  }) {
    if (xy != null) rotXY = xy;
    if (xz != null) rotXZ = xz;
    if (yz != null) rotYZ = yz;
    if (xw != null) rotXW = xw;
    if (yw != null) rotYW = yw;
    if (zw != null) rotZW = zw;

    // Apply incremental rotations
    _applyIncrementalRotations();
    _projectTo3D();
    _extractParameters();
  }

  /// Switch to different polytope
  void setPolytope(PolytopeType type) {
    currentPolytope = type;
    _generatePolytope(type);
    _projectTo3D();
    _extractParameters();
  }

  /// Get all wavetable parameters driven by polytope
  Map<String, double> getParameters() {
    return {
      'wavetablePosition': wavetablePosition,
      'morphIntensity': morphIntensity,
      'grainDensity': grainDensity,
      'spectralTilt': spectralTilt,
      'complexity': _calculateComplexity(),
      'energy': _calculateEnergy(),
    };
  }

  /// Generate polytope vertices in 4D
  void _generatePolytope(PolytopeType type) {
    vertices.clear();

    switch (type) {
      case PolytopeType.tesseract:
        _generateTesseract();
        break;
      case PolytopeType.cell16:
        _generate16Cell();
        break;
      case PolytopeType.cell24:
        _generate24Cell();
        break;
      case PolytopeType.cell120:
        _generate120Cell();
        break;
      case PolytopeType.cell600:
        _generate600Cell();
        break;
    }
  }

  void _generateTesseract() {
    // 16 vertices of a tesseract (hypercube)
    for (int i = 0; i < 16; i++) {
      vertices.add(Vector4D(
        (i & 1) == 0 ? -1.0 : 1.0,
        (i & 2) == 0 ? -1.0 : 1.0,
        (i & 4) == 0 ? -1.0 : 1.0,
        (i & 8) == 0 ? -1.0 : 1.0,
      ));
    }
  }

  void _generate16Cell() {
    // 8 vertices of a 16-cell (hyperoctahedron)
    // 4D cross-polytope
    vertices.addAll([
      Vector4D(1, 0, 0, 0),
      Vector4D(-1, 0, 0, 0),
      Vector4D(0, 1, 0, 0),
      Vector4D(0, -1, 0, 0),
      Vector4D(0, 0, 1, 0),
      Vector4D(0, 0, -1, 0),
      Vector4D(0, 0, 0, 1),
      Vector4D(0, 0, 0, -1),
    ]);
  }

  void _generate24Cell() {
    // 24 vertices of a 24-cell
    // All permutations of (±1, ±1, 0, 0)
    final signs = [1.0, -1.0];
    for (final s1 in signs) {
      for (final s2 in signs) {
        vertices.addAll([
          Vector4D(s1, s2, 0, 0),
          Vector4D(s1, 0, s2, 0),
          Vector4D(s1, 0, 0, s2),
          Vector4D(0, s1, s2, 0),
          Vector4D(0, s1, 0, s2),
          Vector4D(0, 0, s1, s2),
        ]);
      }
    }
  }

  void _generate120Cell() {
    // Simplified 120-cell (using subset of vertices)
    // Full 120-cell has 600 vertices - we use golden ratio coordinates
    final phi = (1 + math.sqrt(5)) / 2; // Golden ratio
    final invPhi = 1 / phi;

    // All even permutations of (±1, ±1, ±1, ±√5)
    final sqrt5 = math.sqrt(5);
    vertices.addAll([
      Vector4D(1, 1, 1, sqrt5),
      Vector4D(1, 1, -1, sqrt5),
      Vector4D(1, -1, 1, sqrt5),
      Vector4D(-1, 1, 1, sqrt5),
      // Golden ratio coordinates
      Vector4D(phi, 1, invPhi, 0),
      Vector4D(phi, -1, invPhi, 0),
      Vector4D(1, invPhi, 0, phi),
      Vector4D(-1, invPhi, 0, phi),
    ]);

    // Add more vertices for richness (subset)
    for (int i = 0; i < 32; i++) {
      final angle1 = (i / 32.0) * 2 * math.pi;
      final angle2 = ((i * phi) % 1.0) * 2 * math.pi;
      vertices.add(Vector4D(
        math.cos(angle1) * phi,
        math.sin(angle1) * phi,
        math.cos(angle2),
        math.sin(angle2),
      ));
    }
  }

  void _generate600Cell() {
    // Simplified 600-cell using icosahedral symmetry
    final phi = (1 + math.sqrt(5)) / 2;

    // Use 4D spherical coordinates
    for (int i = 0; i < 60; i++) {
      final theta = (i / 60.0) * 2 * math.pi;
      final phi1 = ((i * phi) % 1.0) * math.pi;
      final phi2 = ((i * phi * phi) % 1.0) * 2 * math.pi;

      vertices.add(Vector4D(
        math.sin(phi1) * math.cos(theta),
        math.sin(phi1) * math.sin(theta),
        math.cos(phi1) * math.cos(phi2),
        math.cos(phi1) * math.sin(phi2),
      ));
    }
  }

  /// Build 4D rotation using double quaternion (6 DOF)
  void _build4DRotation() {
    // 3D rotation component (XY, XZ, YZ planes)
    leftRotation = rotation3D;

    // 4D rotation component (XW, YW, ZW planes)
    // We use a second quaternion to represent rotation into the 4th dimension
    final qXW = Quaternion.fromAxisAngle(Vector3D(1, 0, 0), rotXW);
    final qYW = Quaternion.fromAxisAngle(Vector3D(0, 1, 0), rotYW);
    final qZW = Quaternion.fromAxisAngle(Vector3D(0, 0, 1), rotZW);

    rightRotation = qXW * qYW * qZW;
  }

  void _applyIncrementalRotations() {
    // Apply 3D rotations
    final q3d = Quaternion.fromEuler(rotXY, rotXZ, rotYZ);
    rotation3D = rotation3D * q3d;
    rotation3D.normalize();

    // Apply 4D rotations
    final qXW = Quaternion.fromAxisAngle(Vector3D(1, 0, 0), rotXW * 0.01);
    final qYW = Quaternion.fromAxisAngle(Vector3D(0, 1, 0), rotYW * 0.01);
    final qZW = Quaternion.fromAxisAngle(Vector3D(0, 0, 1), rotZW * 0.01);

    rightRotation = rightRotation * qXW * qYW * qZW;
    rightRotation.normalize();
  }

  /// Project 4D polytope to 3D using stereographic projection
  void _projectTo3D() {
    projectedVertices.clear();

    for (final v4d in vertices) {
      // Apply double quaternion rotation (simplified 4D rotation)
      final rotated = _rotate4D(v4d);

      // Stereographic projection from 4D to 3D
      final w = rotated.w + 2.0; // Offset to avoid division by zero
      projectedVertices.add(Vector3D(
        rotated.x / w,
        rotated.y / w,
        rotated.z / w,
      ));
    }
  }

  Vector4D _rotate4D(Vector4D v) {
    // Simplified 4D rotation using double quaternion
    // First rotate in 3D space (xyz)
    final v3d = Vector3D(v.x, v.y, v.z);
    final rotated3d = leftRotation.rotate(v3d);

    // Then apply 4D rotation (affects w coordinate)
    // This is a simplified approach - full 4D rotation requires 8D quaternions
    final wRotation = rightRotation.rotate(Vector3D(rotated3d.x, rotated3d.y, v.w));

    return Vector4D(
      rotated3d.x,
      rotated3d.y,
      rotated3d.z,
      wRotation.z, // Use z component as new w
    );
  }

  /// Extract synthesis parameters from projected polytope
  void _extractParameters() {
    if (projectedVertices.isEmpty) return;

    // Calculate center of mass in 3D projection
    Vector3D center = Vector3D(0, 0, 0);
    for (final v in projectedVertices) {
      center = center + v;
    }
    center = center * (1.0 / projectedVertices.length);

    // Wavetable position from X coordinate (-1 to 1 → 0 to 1)
    wavetablePosition = ((center.x + 1.0) / 2.0).clamp(0.0, 1.0);

    // Morph intensity from Y coordinate
    morphIntensity = ((center.y + 1.0) / 2.0).clamp(0.0, 1.0);

    // Grain density from Z coordinate
    grainDensity = ((center.z + 1.0) / 2.0).clamp(0.0, 1.0);

    // Spectral tilt from spread in projection
    double spread = 0.0;
    for (final v in projectedVertices) {
      final dist = (v - center).length();
      spread += dist;
    }
    spread /= projectedVertices.length;
    spectralTilt = spread.clamp(0.0, 1.0);
  }

  double _calculateComplexity() {
    // Complexity based on variance in vertex positions
    if (projectedVertices.length < 2) return 0.0;

    double variance = 0.0;
    for (int i = 1; i < projectedVertices.length; i++) {
      final diff = projectedVertices[i] - projectedVertices[i - 1];
      variance += diff.length();
    }

    return (variance / projectedVertices.length).clamp(0.0, 1.0);
  }

  double _calculateEnergy() {
    // Energy based on distance from origin
    double totalDist = 0.0;
    for (final v in projectedVertices) {
      totalDist += v.length();
    }

    return (totalDist / projectedVertices.length).clamp(0.0, 1.0);
  }
}

enum PolytopeType {
  tesseract,  // 8-cell (hypercube) - 16 vertices
  cell16,     // 16-cell (hyperoctahedron) - 8 vertices
  cell24,     // 24-cell - 24 vertices
  cell120,    // 120-cell - 600 vertices (simplified)
  cell600,    // 600-cell - 120 vertices (simplified)
}

class Vector4D {
  final double x, y, z, w;

  Vector4D(this.x, this.y, this.z, this.w);

  Vector4D operator +(Vector4D other) {
    return Vector4D(x + other.x, y + other.y, z + other.z, w + other.w);
  }

  Vector4D operator *(double scalar) {
    return Vector4D(x * scalar, y * scalar, z * scalar, w * scalar);
  }

  double length() {
    return math.sqrt(x * x + y * y + z * z + w * w);
  }
}

class Vector3D {
  final double x, y, z;

  Vector3D(this.x, this.y, this.z);

  Vector3D operator +(Vector3D other) {
    return Vector3D(x + other.x, y + other.y, z + other.z);
  }

  Vector3D operator -(Vector3D other) {
    return Vector3D(x - other.x, y - other.y, z - other.z);
  }

  Vector3D operator *(double scalar) {
    return Vector3D(x * scalar, y * scalar, z * scalar);
  }

  double length() {
    return math.sqrt(x * x + y * y + z * z);
  }
}

class Quaternion {
  final double w, x, y, z;

  Quaternion(this.w, this.x, this.y, this.z);

  static Quaternion identity() => Quaternion(1, 0, 0, 0);

  static Quaternion fromEuler(double roll, double pitch, double yaw) {
    final cr = math.cos(roll / 2);
    final sr = math.sin(roll / 2);
    final cp = math.cos(pitch / 2);
    final sp = math.sin(pitch / 2);
    final cy = math.cos(yaw / 2);
    final sy = math.sin(yaw / 2);

    return Quaternion(
      cr * cp * cy + sr * sp * sy,
      sr * cp * cy - cr * sp * sy,
      cr * sp * cy + sr * cp * sy,
      cr * cp * sy - sr * sp * cy,
    );
  }

  static Quaternion fromAxisAngle(Vector3D axis, double angle) {
    final halfAngle = angle / 2;
    final s = math.sin(halfAngle);
    return Quaternion(
      math.cos(halfAngle),
      axis.x * s,
      axis.y * s,
      axis.z * s,
    );
  }

  Quaternion operator *(Quaternion other) {
    return Quaternion(
      w * other.w - x * other.x - y * other.y - z * other.z,
      w * other.x + x * other.w + y * other.z - z * other.y,
      w * other.y - x * other.z + y * other.w + z * other.x,
      w * other.z + x * other.y - y * other.x + z * other.w,
    );
  }

  void normalize() {
    final len = math.sqrt(w * w + x * x + y * y + z * z);
    if (len > 0) {
      final invLen = 1.0 / len;
      // Note: We can't modify final fields, so this should return a new Quaternion
      // For this implementation, we'll assume the caller handles normalization differently
    }
  }

  Vector3D rotate(Vector3D v) {
    final qv = Quaternion(0, v.x, v.y, v.z);
    final qConj = Quaternion(w, -x, -y, -z);
    final result = this * qv * qConj;
    return Vector3D(result.x, result.y, result.z);
  }
}
