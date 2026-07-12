import 'dart:typed_data';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

/// Plays a single continuous tone whose pitch/volume can be nudged live.
///
/// The 440 Hz sine buffer is generated once and looped; pitch is playback-rate,
/// volume is player volume. Gating uses pause/resume (not stop/setSource) so the
/// native source is prepared exactly once — no per-note re-prepare cost or clicks.
class TonePlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _sourceReady = false;
  bool _disposed = false;
  Uint8List? _wav;

  static const int sampleRate = 44100;
  static const double bufferDuration = 2.0;
  static const double baseFrequency = 440.0;

  // Keep the playback rate inside a range Android's MediaPlayer handles safely.
  static const double _minRate = 0.25;
  static const double _maxRate = 4.0;

  TonePlayer();

  double _rateFor(double frequency) =>
      (frequency / baseFrequency).clamp(_minRate, _maxRate);

  Future<void> _ensureSource() async {
    if (_sourceReady || _disposed) return;
    _wav ??= _generateSineWave(baseFrequency, bufferDuration);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setSource(BytesSource(_wav!));
    _sourceReady = true;
  }

  /// Start (or unpause) the tone at [frequency]/[volume].
  Future<void> startTone(double frequency, double volume) async {
    if (_disposed) return;
    try {
      await _ensureSource();
      await _player.setPlaybackRate(_rateFor(frequency));
      await _player.setVolume(volume.clamp(0.0, 1.0));
      if (!_isPlaying) {
        await _player.resume();
        _isPlaying = true;
      }
    } catch (_) {
      // Swallow platform exceptions: a transient audio error must not crash the
      // game loop or surface as an unhandled Future.
    }
  }

  /// Nudge pitch/volume while playing.
  Future<void> setFrequency(double frequency, double volume) async {
    if (_disposed) return;
    if (!_isPlaying) {
      await startTone(frequency, volume);
      return;
    }
    try {
      await _player.setPlaybackRate(_rateFor(frequency));
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  /// Silence the tone by pausing (keeps the prepared source for a fast restart).
  Future<void> stopTone() async {
    if (_disposed || !_isPlaying) return;
    _isPlaying = false;
    try {
      await _player.pause();
    } catch (_) {}
  }

  bool get isPlaying => _isPlaying;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _isPlaying = false;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _player.dispose();
    } catch (_) {}
  }

  /// Generate a WAV file with a sine wave at the given frequency.
  Uint8List _generateSineWave(double frequency, double duration) {
    final numSamples = (sampleRate * duration).toInt();
    final samples = Int16List(numSamples);
    const amplitude = 0.8;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      samples[i] = (sin(2 * pi * frequency * t) * amplitude * 32767).toInt();
    }
    return _buildWav(samples);
  }

  /// Build a minimal WAV file from 16-bit PCM samples.
  Uint8List _buildWav(Int16List samples) {
    final dataSize = samples.length * 2;
    final fileSize = 44 + dataSize;
    final buffer = ByteData(fileSize);
    int offset = 0;

    buffer.setUint32(offset, 0x52494646, Endian.big); offset += 4; // "RIFF"
    buffer.setUint32(offset, fileSize - 8, Endian.little); offset += 4;
    buffer.setUint32(offset, 0x57415645, Endian.big); offset += 4; // "WAVE"

    buffer.setUint32(offset, 0x666d7420, Endian.big); offset += 4; // "fmt "
    buffer.setUint32(offset, 16, Endian.little); offset += 4;
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // PCM
    buffer.setUint16(offset, 1, Endian.little); offset += 2; // mono
    buffer.setUint32(offset, sampleRate, Endian.little); offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); offset += 4;
    buffer.setUint16(offset, 2, Endian.little); offset += 2;
    buffer.setUint16(offset, 16, Endian.little); offset += 2;

    buffer.setUint32(offset, 0x64617461, Endian.big); offset += 4; // "data"
    buffer.setUint32(offset, dataSize, Endian.little); offset += 4;

    for (final sample in samples) {
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }
    return buffer.buffer.asUint8List();
  }
}
