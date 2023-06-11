import 'dart:typed_data';

import 'common.dart';
import 'internal.dart';
import 'positional_byte_reader.dart';

class WavHeader {
  WavFormat format;
  int numChannels;
  int numSamples;
  int samplesPerSecond;

  WavHeader(
    this.numChannels, 
    this.numSamples, 
    this.format, 
    this.samplesPerSecond,
  );
}

class WavHeaderReader
{
  PositionalByteReader byteReader;

  WavHeaderReader(this.byteReader);

  static WavFormat _getFormat(int formatCode, int bitsPerSample) {
    if (formatCode == kPCM) {
      if (bitsPerSample == 8) return WavFormat.pcm8bit;
      if (bitsPerSample == 16) return WavFormat.pcm16bit;
      if (bitsPerSample == 24) return WavFormat.pcm24bit;
      if (bitsPerSample == 32) return WavFormat.pcm32bit;
    } else if (formatCode == kFloat) {
      if (bitsPerSample == 32) return WavFormat.float32;
      if (bitsPerSample == 64) return WavFormat.float64;
    }
    throw FormatException('Unsupported format: $formatCode, $bitsPerSample');
  }

  // Chunk is always padded to an even number of bytes.
  static int _roundUp(int x) => x + (x % 2);

  bool checkString(String s) {
    return s == String.fromCharCodes(
      Uint8List.sublistView(byteReader.read(s.length)),
    );
  }

  void assertString(String s) {
    if (!checkString(s)) {
      throw FormatException('WAV is corrupted, or not a WAV file.');
    }
  }

  int readU16() => byteReader.read(2).getUint16(0, Endian.little);
  int readU32() => byteReader.read(4).getUint32(0, Endian.little);

  void findChunk(String s) {
    while (!checkString(s)) {
      final size = readU32();
      byteReader.skip(_roundUp(size));
    }
  }

  /// Reads the Wav header information from a byte buffer and advances the 
  /// position in the buffer to the end of the header.
  WavHeader read()
  {
    // Read metadata.
    assertString(kStrRiff);
    readU32(); // File size.
    assertString(kStrWave);

    findChunk(kStrFmt);
    final fmtSize = _roundUp(readU32());
    final formatCode = readU16();
    final numChannels = readU16();
    final samplesPerSecond = readU32();
    readU32(); // Bytes per second.
    final bytesPerSampleAllChannels = readU16();
    final bitsPerSample = readU16();
    if (fmtSize > kFormatSize) byteReader.skip(fmtSize - kFormatSize);

    findChunk(kStrData);
    final dataSize = readU32();
    final numSamples = dataSize ~/ bytesPerSampleAllChannels;
    final format = _getFormat(formatCode, bitsPerSample);

    return WavHeader(numChannels, numSamples, format, samplesPerSecond);
  }}