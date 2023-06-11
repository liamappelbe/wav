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

import 'dart:typed_data';

import 'common.dart';
import 'internal.dart';
import 'positional_byte_reader.dart';
import 'wav_data_reader.dart';
import 'wav_header_reader.dart';
import 'wav_no_io.dart' if (dart.library.io) 'wav_io.dart';

/// A WAV file, containing audio, and metadata.
class Wav {
  /// Audio data, as a list of channels.
  ///
  /// In the typical stereo case the channels will be `[left, right]`.
  ///
  /// The audio samples are in the range `[-1, 1]`.
  final List<Float64List> channels;

  /// The sampling frequency of the audio data, in Hz.
  final int samplesPerSecond;

  /// The format of the WAV file.
  final WavFormat format;

  /// Constructs a Wav directly from audio data.
  Wav(
    this.channels,
    this.samplesPerSecond, [
    this.format = WavFormat.pcm16bit,
  ]);

  /// Read a Wav from a file.
  ///
  /// Convenience wrapper around [read]. See that method for details.
  static Future<Wav> readFile(String filename) async {
    return read(await internalReadFile(filename));
  }

  /// Returns the duration of the Wav in seconds.
  double get duration =>
      channels.isEmpty ? 0 : channels[0].length / samplesPerSecond;

  /// Read a Wav from a byte buffer.
  ///
  /// Not all formats are supported. See [WavFormat] for a canonical list.
  /// Unrecognized metadata will be ignored.
  static Wav read(Uint8List bytes) {
    var byteReader = PositionalByteReader(bytes);
    var header = WavHeaderReader(byteReader).read();
    final channels = WavDataReader(byteReader).readData(header);
    return Wav(channels, header.samplesPerSecond, header.format);
  }

  /// Mix the audio channels down to mono.
  Float64List toMono() {
    if (channels.isEmpty) return Float64List(0);
    final mono = Float64List(channels[0].length);
    for (int i = 0; i < mono.length; ++i) {
      for (int j = 0; j < channels.length; ++j) {
        mono[i] += channels[j][i];
      }
      mono[i] /= channels.length;
    }
    return mono;
  }

  /// Write the Wav to a file.
  ///
  /// Convenience wrapper around [write]. See that method for details.
  Future<void> writeFile(String filename) async {
    await internalWriteFile(filename, write());
  }

  /// Write the Wav to a byte buffer.
  ///
  /// If your audio samples exceed `[-1, 1]`, they will be clamped (unless
  /// you're using float32 or float64 format). If your channels are different
  /// lengths, they will be padded with zeros.
  Uint8List write() {
    // Chunk is always rounded to an even number of bytes.
    int padToMakeEven(int x) => x + (x % 2);

    // Calculate sizes etc.
    final bitsPerSample = [8, 16, 24, 32, 32, 64][format.index];
    final isFloat = format == WavFormat.float32 || format == WavFormat.float64;
    final bytesPerSample = bitsPerSample ~/ 8;
    final numChannels = channels.length;
    int numSamples = 0;
    for (final channel in channels) {
      if (channel.length > numSamples) numSamples = channel.length;
    }
    final bytesPerSampleAllChannels = bytesPerSample * numChannels;
    final dataSize = numSamples * bytesPerSampleAllChannels;
    final bytesPerSecond = bytesPerSampleAllChannels * samplesPerSecond;
    var fileSize = kFileSizeWithoutData + padToMakeEven(dataSize);
    if (isFloat) {
      fileSize += kFloatFmtExtraSize;
    }

    // Utils for writing. The write methods rely on ByteBuilder's truncation.
    final bytes = BytesBuilder();
    writeU8(int x) => bytes..addByte(x);
    writeU16(int x) => writeU8(x)..addByte(x >> 8);
    writeU24(int x) => writeU16(x)..addByte(x >> 16);
    writeU32(int x) => writeU24(x)..addByte(x >> 24);
    clamp(int x, int y) => x < 0
        ? 0
        : x > y
            ? y
            : x;
    f2u(double x, int b) => clamp(((x + 1) * wScale(b)).floor(), (1 << b) - 1);
    writeS8(double x) => writeU8(f2u(x, 8));
    writeS16(double x) => writeU16(fold(f2u(x, 16), 16));
    writeS24(double x) => writeU24(fold(f2u(x, 24), 24));
    writeS32(double x) => writeU32(fold(f2u(x, 32), 32));
    final fbuf = ByteData(8);
    writeBytes(ByteData b, int n) => bytes.add(b.buffer.asUint8List(0, n));
    writeF32(double x) => writeBytes(fbuf..setFloat32(0, x, Endian.little), 4);
    writeF64(double x) => writeBytes(fbuf..setFloat64(0, x, Endian.little), 8);
    writeString(String str) {
      for (int c in str.codeUnits) {
        bytes.addByte(c);
      }
    }

    // Write metadata.
    writeString(kStrRiff);
    writeU32(fileSize);
    writeString(kStrWave);
    writeString(kStrFmt);
    writeU32(kFormatSize);
    writeU16(isFloat ? kFloat : kPCM);
    writeU16(numChannels);
    writeU32(samplesPerSecond);
    writeU32(bytesPerSecond);
    writeU16(bytesPerSampleAllChannels);
    writeU16(bitsPerSample);
    if (isFloat) {
      writeString(kStrFact);
      writeU32(kFactSize);
      writeU32(numSamples);
    }
    writeString(kStrData);
    writeU32(dataSize);

    // Write samples.
    final writeSample = [
      writeS8,
      writeS16,
      writeS24,
      writeS32,
      writeF32,
      writeF64,
    ][format.index];
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        writeSample(i < channels[j].length ? channels[j][i] : 0);
      }
    }
    if (dataSize % 2 != 0) {
      writeU8(0);
    }
    return bytes.takeBytes();
  }
}
