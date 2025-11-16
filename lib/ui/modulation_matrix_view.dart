import 'package:flutter/material.dart';
import '../synthesis/modulation/modulation_matrix.dart';

/// Visual modulation matrix interface with drag-and-drop routing
///
/// Features:
/// - Visual representation of all 32 modulation slots
/// - Drag-and-drop source/destination assignment
/// - Real-time modulation activity visualization
/// - Amount adjustment with sliders
/// - Curve selection for each slot
/// - Clear/reset individual slots
class ModulationMatrixView extends StatefulWidget {
  final ModulationMatrix matrix;
  final Function(ModulationSlot slot)? onSlotChanged;

  const ModulationMatrixView({
    Key? key,
    required this.matrix,
    this.onSlotChanged,
  }) : super(key: key);

  @override
  State<ModulationMatrixView> createState() => _ModulationMatrixViewState();
}

class _ModulationMatrixViewState extends State<ModulationMatrixView> {
  int? _selectedSlotIndex;
  bool _showActivity = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[900]!,
            Colors.grey[850]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                // Source column
                Expanded(
                  flex: 2,
                  child: _buildSourceColumn(),
                ),
                // Modulation slots grid
                Expanded(
                  flex: 5,
                  child: _buildModulationGrid(),
                ),
                // Destination column
                Expanded(
                  flex: 2,
                  child: _buildDestinationColumn(),
                ),
              ],
            ),
          ),
          if (_selectedSlotIndex != null) _buildSlotEditor(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub, color: Colors.cyan, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Modulation Matrix',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildHeaderButton(
            icon: _showActivity ? Icons.visibility : Icons.visibility_off,
            label: 'Activity',
            onPressed: () => setState(() => _showActivity = !_showActivity),
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.clear_all,
            label: 'Clear All',
            onPressed: _clearAllSlots,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.cyan,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildSourceColumn() {
    final sources = ModSource.values;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(right: BorderSide(color: Colors.cyan.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.cyan.withOpacity(0.1),
            child: const Text(
              'SOURCES',
              style: TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                return _buildSourceTile(source);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTile(ModSource source) {
    final isActive = widget.matrix.slots.any((s) => s.isActive && s.source == source);
    return Draggable<ModSource>(
      data: source,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _getSourceName(source),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? Colors.cyan.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getSourceIcon(source),
              size: 16,
              color: isActive ? Colors.cyan : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getSourceName(source),
                style: TextStyle(
                  color: isActive ? Colors.cyan : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationColumn() {
    final destinations = ModDestination.values;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(left: BorderSide(color: Colors.purple.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.purple.withOpacity(0.1),
            child: const Text(
              'DESTINATIONS',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return _buildDestinationTile(destination);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationTile(ModDestination destination) {
    final isActive = widget.matrix.slots.any((s) => s.isActive && s.destination == destination);
    return DragTarget<ModSource>(
      onWillAccept: (source) => source != null,
      onAccept: (source) => _createModulation(source, destination),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHovering
                ? Colors.purple.withOpacity(0.3)
                : isActive
                    ? Colors.purple.withOpacity(0.2)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHovering
                  ? Colors.purple
                  : isActive
                      ? Colors.purple.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.3),
              width: isHovering || isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getDestinationName(destination),
                  style: TextStyle(
                    color: isActive ? Colors.purple : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _getDestinationIcon(destination),
                size: 16,
                color: isActive ? Colors.purple : Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModulationGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: 32,
      itemBuilder: (context, index) {
        final slot = widget.matrix.slots[index];
        return _buildSlotTile(slot, index);
      },
    );
  }

  Widget _buildSlotTile(ModulationSlot slot, int index) {
    final isSelected = _selectedSlotIndex == index;
    final activityLevel = _showActivity && slot.isActive
        ? (widget.matrix.getModulation(slot.destination).abs() * slot.amount.abs())
        : 0.0;

    return GestureDetector(
      onTap: slot.isActive ? () => setState(() => _selectedSlotIndex = index) : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: slot.isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.cyan.withOpacity(0.3 + activityLevel * 0.4),
                    Colors.purple.withOpacity(0.3 + activityLevel * 0.4),
                  ],
                )
              : null,
          color: slot.isActive ? null : Colors.grey[900],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : slot.isActive
                    ? Colors.cyan.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (slot.isActive) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    Text(
                      '${(slot.amount * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Activity indicator
              if (_showActivity && activityLevel > 0.01)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ] else
              Center(
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
            // Slot number
            Positioned(
              bottom: 2,
              left: 2,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotEditor() {
    final slot = widget.matrix.slots[_selectedSlotIndex!];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.cyan.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Slot ${_selectedSlotIndex! + 1}',
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Chip(
                label: Text(_getSourceName(slot.source)),
                backgroundColor: Colors.cyan.withOpacity(0.2),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              Chip(
                label: Text(_getDestinationName(slot.destination)),
                backgroundColor: Colors.purple.withOpacity(0.2),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _clearSlot(_selectedSlotIndex!);
                  setState(() => _selectedSlotIndex = null);
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => setState(() => _selectedSlotIndex = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: slot.amount,
                            min: -1.0,
                            max: 1.0,
                            onChanged: (value) {
                              setState(() {
                                slot.amount = value;
                                widget.onSlotChanged?.call(slot);
                              });
                            },
                            activeColor: Colors.cyan,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${(slot.amount * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.cyan),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Curve', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    DropdownButton<ModCurve>(
                      value: slot.curve,
                      isExpanded: true,
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.cyan),
                      items: ModCurve.values.map((curve) {
                        return DropdownMenuItem(
                          value: curve,
                          child: Text(_getCurveName(curve)),
                        );
                      }).toList(),
                      onChanged: (curve) {
                        if (curve != null) {
                          setState(() {
                            slot.curve = curve;
                            widget.onSlotChanged?.call(slot);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createModulation(ModSource source, ModDestination destination) {
    // Find first empty slot
    final emptyIndex = widget.matrix.slots.indexWhere((s) => !s.isActive);
    if (emptyIndex != -1) {
      setState(() {
        final slot = widget.matrix.slots[emptyIndex];
        slot.isActive = true;
        slot.source = source;
        slot.destination = destination;
        slot.amount = 0.5; // Default amount
        slot.curve = ModCurve.linear;
        _selectedSlotIndex = emptyIndex;
        widget.onSlotChanged?.call(slot);
      });
    } else {
      // Show error - no empty slots
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No empty modulation slots available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSlot(int index) {
    setState(() {
      final slot = widget.matrix.slots[index];
      slot.isActive = false;
      widget.onSlotChanged?.call(slot);
    });
  }

  void _clearAllSlots() {
    setState(() {
      for (var slot in widget.matrix.slots) {
        slot.isActive = false;
      }
      _selectedSlotIndex = null;
    });
  }

  String _getSourceName(ModSource source) {
    switch (source) {
      case ModSource.lfo1: return 'LFO 1';
      case ModSource.lfo2: return 'LFO 2';
      case ModSource.lfo3: return 'LFO 3';
      case ModSource.lfo4: return 'LFO 4';
      case ModSource.lfo5: return 'LFO 5';
      case ModSource.lfo6: return 'LFO 6';
      case ModSource.lfo7: return 'LFO 7';
      case ModSource.lfo8: return 'LFO 8';
      case ModSource.env1: return 'Env 1';
      case ModSource.env2: return 'Env 2';
      case ModSource.env3: return 'Env 3';
      case ModSource.env4: return 'Env 4';
      case ModSource.velocity: return 'Velocity';
      case ModSource.aftertouch: return 'Aftertouch';
      case ModSource.modWheel: return 'Mod Wheel';
      case ModSource.pitchBend: return 'Pitch Bend';
      case ModSource.xyPadX: return 'XY Pad X';
      case ModSource.xyPadY: return 'XY Pad Y';
    }
  }

  String _getDestinationName(ModDestination dest) {
    switch (dest) {
      case ModDestination.wavetablePosition: return 'Wavetable Pos';
      case ModDestination.wavetableSpeed: return 'Wavetable Speed';
      case ModDestination.grainSize: return 'Grain Size';
      case ModDestination.grainDensity: return 'Grain Density';
      case ModDestination.grainPitch: return 'Grain Pitch';
      case ModDestination.filterCutoff: return 'Filter Cutoff';
      case ModDestination.filterResonance: return 'Filter Res';
      case ModDestination.amplitude: return 'Amplitude';
      case ModDestination.pitch: return 'Pitch';
      case ModDestination.pan: return 'Pan';
      case ModDestination.visual4dRotXW: return '4D Rot XW';
      case ModDestination.visual4dRotYW: return '4D Rot YW';
      case ModDestination.visual4dRotZW: return '4D Rot ZW';
      case ModDestination.visualMorphIntensity: return 'Morph';
      case ModDestination.visualColorHue: return 'Color Hue';
      case ModDestination.visualBloom: return 'Bloom';
    }
  }

  IconData _getSourceIcon(ModSource source) {
    if (source.toString().contains('lfo')) {
      return Icons.waves;
    } else if (source.toString().contains('env')) {
      return Icons.show_chart;
    } else if (source == ModSource.velocity) {
      return Icons.speed;
    } else if (source == ModSource.xyPadX || source == ModSource.xyPadY) {
      return Icons.control_camera;
    } else {
      return Icons.tune;
    }
  }

  IconData _getDestinationIcon(ModDestination dest) {
    if (dest.toString().contains('visual')) {
      return Icons.visibility;
    } else if (dest.toString().contains('filter')) {
      return Icons.equalizer;
    } else if (dest.toString().contains('grain')) {
      return Icons.grain;
    } else {
      return Icons.settings;
    }
  }

  String _getCurveName(ModCurve curve) {
    switch (curve) {
      case ModCurve.linear: return 'Linear';
      case ModCurve.exponential: return 'Exponential';
      case ModCurve.logarithmic: return 'Logarithmic';
      case ModCurve.sCurve: return 'S-Curve';
    }
  }
}
