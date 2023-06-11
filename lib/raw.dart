import 'dart:typed_data';

/// The supported WAV formats.
enum WavFormat {
  /// 8-bit PCM.
  pcm8bit,

  /// 16-bit PCM.
  pcm16bit,

  /// 24-bit PCM.
  pcm24bit,

  /// 32-bit PCM.
  pcm32bit,

  /// 32-bit float.
  float32,

  /// 64-bit float.
  float64,
}

class Raw {
  // [0, 2] => [0, 2 ^ bits - 1]
  static double _wScale(int bits) => (1 << (bits - 1)) * 1.0;
  static double _rScale(int bits) => _wScale(bits) - 0.5;
  static int _fold(int x, int bits) => (x + (1 << (bits - 1))) % (1 << bits);

  /// Read a Wav from a byte buffer.
  ///
  /// Not all formats are supported. See [WavFormat] for a canonical list.
  /// Unrecognized metadata will be ignored.
  static List<Float64List> read(
    Uint8List bytes, int numChannels, int numSamples, WavFormat format,
    { int startPosition = 0, }
    )
  {

    // Utils for reading.
    int p = startPosition;
    void skip(int n) {
      p += n;
      if (p > bytes.length) {
        throw FormatException('WAV is corrupted, or not a WAV file.');
      }
    }

    ByteData read(int n) {
      final p0 = p;
      skip(n);
      return ByteData.sublistView(bytes, p0, p);
    }

    int readU8() => read(1).getUint8(0);
    int readU16() => read(2).getUint16(0, Endian.little);
    int readU24() => readU8() + 0x100 * readU16();
    int readU32() => read(4).getUint32(0, Endian.little);
    double u2f(int x, int b) => (x / _rScale(b)) - 1;
    double readS8() => u2f(readU8(), 8);
    double readS16() => u2f(_fold(readU16(), 16), 16);
    double readS24() => u2f(_fold(readU24(), 24), 24);
    double readS32() => u2f(_fold(readU32(), 32), 32);
    double readF32() => read(4).getFloat32(0, Endian.little);
    double readF64() => read(8).getFloat64(0, Endian.little);

    // Read samples.
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(numSamples));
    }
    final readSample =
        [readS8, readS16, readS24, readS32, readF32, readF64][format.index];
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        channels[j][i] = readSample();
      }
    }

    return channels;
  }
}