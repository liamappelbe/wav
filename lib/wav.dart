// Copyright 2022 The wav authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';
import 'dart:typed_data';

enum WavFormat {
  PCM_8bit,
  PCM_16bit,
  PCM_24bit,
  PCM_32bit,
}

class Wav {
  final List<Float64List> channels;
  final int samplesPerSecond;
  final WavFormat format;
  Wav(this.channels, this.samplesPerSecond, [this.format = WavFormat.PCM_16bit]);

  static Future<Wav> readFile(String filename) async {
    return read(await File(filename).readAsBytes());
  }

  static const _kFormatSize = 16;
  static const _kFileSizeWithoutData = 36;
  static const _kPCM = 1;
  static const _kStrRiff = 'RIFF';
  static const _kStrWave = 'WAVE';
  static const _kStrFmt = 'fmt ';
  static const _kStrData = 'data';

  static _getFormat(int formatCode, int bitsPerSample) {
    if (formatCode == _kPCM) {
      if (bitsPerSample == 8) return WavFormat.PCM_8bit;
      if (bitsPerSample == 16) return WavFormat.PCM_16bit;
      if (bitsPerSample == 24) return WavFormat.PCM_24bit;
      if (bitsPerSample == 32) return WavFormat.PCM_32bit;
    }
    throw FormatException('WUnsupported format: $formatCode, $bitsPerSample');
  }

  static Wav read(Uint8List bytes) {
    // Utils for reading.
    int p = 0;
    ByteData read(int n) {
      final q = p + n;
      if (q > bytes.length) {
        throw FormatException('WAV is corrupted, or not a WAV file.');
      }
      final b = ByteData.sublistView(bytes, p, q);
      p = q;
      return b;
    }

    int readU8() => (read(1)).getUint8(0);
    int readU16() => (read(2)).getUint16(0, Endian.little);
    int readU24() => readU8() + 0x100 * readU16();
    int readU32() => (read(4)).getUint32(0, Endian.little);
    int readS16() => (readU16() + (1 << 15)) % (1 << 16);
    int readS24() => (readU24() + (1 << 23)) % (1 << 24);
    int readS32() => (readU32() + (1 << 31)) % (1 << 32);
    void checkString(String str) {
      final s = String.fromCharCodes(Uint8List.sublistView(read(str.length)));
      if (s != str) {
        throw FormatException('WAV is corrupted, or not a WAV file.');
      }
    }

    // Read metadata.
    checkString(_kStrRiff);
    readU32(); // File size.
    checkString(_kStrWave);
    checkString(_kStrFmt);
    readU32(); // Format block size.
    final formatCode = readU16();
    final numChannels = readU16();
    final samplesPerSecond = readU32();
    readU32(); // Bytes per second.
    final bytesPerSampleAllChannels = readU16();
    final bitsPerSample = readU16();
    checkString(_kStrData);
    final dataSize = readU32();
    final numSamples = dataSize ~/ bytesPerSampleAllChannels;
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(numSamples));
    }
    final format = _getFormat(formatCode, bitsPerSample);

    // Read samples.
    final bytesPerSample = bitsPerSample ~/ 8;
    final readSample = [readU8, readS16, readS24, readS32][format.index];
    final scale = (1 << (bitsPerSample - 1)) - 0.5;
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        channels[j][i] = readSample() / scale - 1;
      }
    }
    if (p != bytes.length) {
      throw FormatException('WAV has leftover bytes');
    }
    return Wav(channels, samplesPerSecond, format);
  }

  Float64List toMono() {
    if (channels.length == 0) return Float64List(0);
    final mono = Float64List(channels[0].length);
    for (int i = 0; i < mono.length; ++i) {
      for (int j = 0; j < channels.length; ++j) {
        mono[i] += channels[j][i];
      }
      mono[i] /= channels.length;
    }
    return mono;
  }

  static const kDefaultBitsPerSample = 16;

  Future<void> writeFile(String filename) async {
    await File(filename).writeAsBytes(write());
  }

  Uint8List write() {
    // Calculate sizes etc.
    final bitsPerSample = [8, 16, 24, 32][format.index];
    final bytesPerSample = bitsPerSample ~/ 8;
    final numChannels = channels.length;
    int numSamples = 0;
    for (final channel in channels) {
      if (channel.length > numSamples) numSamples = channel.length;
    }
    final bytesPerSampleAllChannels = bytesPerSample * numChannels;
    final dataSize = numSamples * bytesPerSampleAllChannels;
    final bytesPerSecond = bytesPerSampleAllChannels * samplesPerSecond;
    final fileSize = _kFileSizeWithoutData + dataSize;

    // Utils for writing. (The write methods rely on ByteBuilder's truncation.
    final bytes = BytesBuilder();
    writeU8(int x) => bytes..addByte(x);
    writeU16(int x) => writeU8(x)..addByte(x >> 8);
    writeU24(int x) => writeU16(x)..addByte(x >> 16);
    writeU32(int x) => writeU24(x)..addByte(x >> 24);
    writeString(String str) {
      for (int c in str.codeUnits) bytes.addByte(c);
    }

    // Write metadata.
    writeString(_kStrRiff);
    writeU32(fileSize);
    writeString(_kStrWave);
    writeString(_kStrFmt);
    writeU32(_kFormatSize);
    writeU16(_kPCM);
    writeU16(numChannels);
    writeU32(samplesPerSecond);
    writeU32(bytesPerSecond);
    writeU16(bytesPerSampleAllChannels);
    writeU16(bitsPerSample);
    writeString(_kStrData);
    writeU32(dataSize);

    // Write samples.
    final writeSample =
        [writeU8, writeU16, writeU24, writeU32][format.index];
    final scale = (1 << (bitsPerSample - 1)) - 1;
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        writeSample(((channels[j][i] + 1) * scale).toInt());
      }
    }
    return bytes.takeBytes();
  }
}
