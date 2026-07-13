import 'package:flutter_test/flutter_test.dart';
import 'package:Therapets/game/minigames/orchestra/music_scale.dart';

void main() {
  group('MusicScale mapping', () {
    test('height 0 sits at the window root; height 1 near the top', () {
      final s = MusicScale(rootMidi: 48, spanOctaves: 2.0, snapStrength: 1.0);
      expect(s.map(0.0).nearestScaleMidi, 48); // C3
      // Top of a 2-octave window is root + 24; nearest allowed note is <= that.
      expect(s.map(1.0).nearestScaleMidi, lessThanOrEqualTo(72));
      expect(s.map(1.0).nearestScaleMidi, greaterThan(60));
    });

    test('hard snap always lands on an allowed scale note', () {
      final s = MusicScale(scale: ScaleType.pentatonic, snapStrength: 1.0);
      final allowed = s.allowedNotes().toSet();
      for (int i = 0; i <= 100; i++) {
        final p = s.map(i / 100);
        expect(allowed.contains(p.soundedMidi.round()), isTrue,
            reason: 'sounded ${p.soundedMidi} not in scale at h=${i / 100}');
      }
    });

    test('snapStrength 0 is continuous (no quantization)', () {
      final s = MusicScale(snapStrength: 0.0);
      final p = s.map(0.37);
      expect(p.soundedMidi, closeTo(p.continuousMidi, 1e-9));
    });

    test('pentatonic excludes the half-step trap tones (4th, 7th)', () {
      final s = MusicScale(scale: ScaleType.pentatonic, rootMidi: 48);
      final pcs = s.allowedNotes().map((n) => n % 12).toSet();
      expect(pcs.contains(5), isFalse); // no 4th (F over C)
      expect(pcs.contains(11), isFalse); // no major 7th (B over C)
    });

    test('chromatic exposes all 12 pitch classes (accidentals reachable)', () {
      final s = MusicScale(scale: ScaleType.chromatic, rootMidi: 48);
      final pcs = s.allowedNotes().map((n) => n % 12).toSet();
      expect(pcs.length, 12);
    });

    test('mapping is monotonic non-decreasing in height', () {
      final s = MusicScale(snapStrength: 0.85);
      double prev = -1;
      for (int i = 0; i <= 200; i++) {
        final f = s.heightToFrequency(i / 200);
        expect(f, greaterThanOrEqualTo(prev - 1e-6));
        prev = f;
      }
    });

    test('octaveShift moves pitch by a factor of two per octave', () {
      final base = MusicScale(snapStrength: 1.0, octaveShift: 0);
      final up = MusicScale(snapStrength: 1.0, octaveShift: 1);
      expect(up.map(0.0).frequency, closeTo(base.map(0.0).frequency * 2, 1e-6));
    });

    test('spanOctaves changes the reachable range', () {
      final narrow = MusicScale(spanOctaves: 1.0, snapStrength: 1.0);
      final wide = MusicScale(spanOctaves: 3.0, snapStrength: 1.0);
      expect(wide.map(1.0).nearestScaleMidi,
          greaterThan(narrow.map(1.0).nearestScaleMidi));
    });

    test('spanOctaves <= 0 does not crash and keeps at least the root note', () {
      final s = MusicScale(rootMidi: 48, spanOctaves: 0, snapStrength: 1.0);
      expect(s.allowedNotes(), isNotEmpty);
      expect(() => s.map(0.5), returnsNormally);
      expect(s.map(0.5).nearestScaleMidi, 48);
    });

    test('A4 = 440 Hz reference', () {
      expect(MusicScale.midiToFrequency(69), closeTo(440.0, 1e-6));
      expect(MusicScale.noteName(69), 'A4');
    });
  });
}
