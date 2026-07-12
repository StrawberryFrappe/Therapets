/// Pure, testable pitch mapping for the Orchestra instrument.
///
/// Maps a normalized arm height `h` in [0, 1] to a musical frequency, snapping
/// toward the notes of a selectable scale so a slightly-off height still sounds
/// in tune. Data-driven: a scale is just a set of allowed semitone offsets, so
/// swapping pentatonic/diatonic/chromatic (or adding sharps/flats) is a config
/// change, never a rewrite.
///
/// Nothing here touches Flame, the device, or audio — it is a deterministic
/// function of its config and `h`, so the whole thing is unit-testable.
library;

import 'dart:math' as math;

/// Selectable scales. Offsets are semitones from the scale root within one
/// octave. Chromatic includes every pitch (all 12), so `#`/`b` accidentals are
/// reachable; pentatonic is the diatonic set minus its two half-step "trap"
/// tones (the 4th and 7th), so any notes played together stay consonant.
enum ScaleType { pentatonic, diatonic, chromatic }

const Map<ScaleType, List<int>> kScaleOffsets = {
  ScaleType.pentatonic: [0, 2, 4, 7, 9],
  ScaleType.diatonic: [0, 2, 4, 5, 7, 9, 11],
  ScaleType.chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
};

const List<String> _kPitchClassSharp = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

/// Result of mapping a height to a pitch. Carries both the continuous and the
/// snapped values so the UI/cube can show where the raw height sits relative to
/// the note it resolved to.
class ScalePoint {
  /// Unquantized MIDI note the raw height maps to (fractional).
  final double continuousMidi;

  /// Nearest allowed scale note (integer MIDI).
  final int nearestScaleMidi;

  /// The MIDI value actually sounded: continuous soft-pulled toward
  /// [nearestScaleMidi] by the mapper's snap strength.
  final double soundedMidi;

  /// Frequency in Hz for [soundedMidi].
  final double frequency;

  /// Human-readable name of [nearestScaleMidi], e.g. "A#4".
  final String noteName;

  const ScalePoint({
    required this.continuousMidi,
    required this.nearestScaleMidi,
    required this.soundedMidi,
    required this.frequency,
    required this.noteName,
  });
}

/// Maps normalized height -> pitch for a given scale, octave window and snap.
///
/// [rootMidi] is the note at height 0 (48 = C3). [spanOctaves] is how many
/// octaves the full height range covers (the in-game "range size"), and may be
/// fractional. [octaveShift] slides the whole window up/down in whole octaves
/// (the in-game octave selector). [snapStrength] in [0, 1]: 0 = continuous
/// (theremin), 1 = hard snap to the scale; in between soft-pulls the pitch
/// toward the real note so small height wobble/drift resolves in tune.
class MusicScale {
  ScaleType scale;
  int rootMidi;
  double spanOctaves;
  int octaveShift;
  double snapStrength;

  MusicScale({
    this.scale = ScaleType.pentatonic,
    this.rootMidi = 48,
    this.spanOctaves = 2.0,
    this.octaveShift = 0,
    this.snapStrength = 0.85,
  });

  int get _effectiveRoot => rootMidi + 12 * octaveShift;

  static double midiToFrequency(double midi) =>
      440.0 * math.pow(2.0, (midi - 69.0) / 12.0).toDouble();

  static String noteName(int midi) {
    final pc = _kPitchClassSharp[midi % 12];
    final octave = (midi ~/ 12) - 1; // MIDI 60 = C4
    return '$pc$octave';
  }

  /// All allowed scale notes inside the current window, ascending.
  List<int> allowedNotes() {
    final offsets = kScaleOffsets[scale]!;
    final root = _effectiveRoot;
    // floor, not ceil: the reachable range is [root, root + spanOctaves*12].
    // ceil would admit a note above the top that no height in [0,1] reaches.
    final top = root + (spanOctaves * 12).floor();
    final notes = <int>[];
    for (int base = root; base <= top; base += 12) {
      for (final off in offsets) {
        final n = base + off;
        if (n >= root && n <= top) notes.add(n);
      }
    }
    notes.sort();
    return notes;
  }

  /// Map height [h] in [0, 1] to a sounded pitch.
  ScalePoint map(double h) {
    final clamped = h.clamp(0.0, 1.0);
    final continuousMidi = _effectiveRoot + clamped * (spanOctaves * 12.0);

    final notes = allowedNotes();
    int nearest = notes.first;
    double bestDist = (continuousMidi - nearest).abs();
    for (final n in notes) {
      final d = (continuousMidi - n).abs();
      if (d < bestDist) {
        bestDist = d;
        nearest = n;
      }
    }

    final s = snapStrength.clamp(0.0, 1.0);
    final sounded = continuousMidi * (1.0 - s) + nearest * s;

    return ScalePoint(
      continuousMidi: continuousMidi,
      nearestScaleMidi: nearest,
      soundedMidi: sounded,
      frequency: midiToFrequency(sounded),
      noteName: noteName(nearest),
    );
  }

  /// Convenience: just the frequency for [h].
  double heightToFrequency(double h) => map(h).frequency;
}
