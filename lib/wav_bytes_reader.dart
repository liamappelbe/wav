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

import 'wav_types.dart';
import 'wav_utils.dart';

/// Utility class to incrementally read through a series of bytes, interpreting
/// byte combinations as little endian (used for Wav files)
class WavBytesReader {
  final Uint8List bytes;
  int p;

  WavBytesReader(
    this.bytes, {
    this.p = 0,
  });

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

  int readUint8() => read(1).getUint8(0);
  int readUint16() => read(2).getUint16(0, Endian.little);
  int readUint32() => read(4).getUint32(0, Endian.little);
  double readFloat32() => read(4).getFloat32(0, Endian.little);
  double readFloat64() => read(8).getFloat64(0, Endian.little);

  int readU8() => readUint8();
  int readU16() => readUint16();
  int readU24() => readU8() + 0x100 * readU16();
  int readU32() => readUint32();
  double u2f(int x, int b) => (x / WavUtils.rScale(b)) - 1;

  double readS8() => u2f(readU8(), 8);
  double readS16() => u2f(WavUtils.fold(readU16(), 16), 16);
  double readS24() => u2f(WavUtils.fold(readU24(), 24), 24);
  double readS32() => u2f(WavUtils.fold(readU32(), 32), 32);
  double readF32() => readFloat32();
  double readF64() => readFloat64();

  bool checkString(String s) {
    return s ==
        String.fromCharCodes(
          Uint8List.sublistView(read(s.length)),
        );
  }

  void assertString(String s) {
    if (!checkString(s)) {
      throw FormatException('WAV is corrupted, or not a WAV file.');
    }
  }

  void findChunk(String s) {
    while (!checkString(s)) {
      final size = readU32();
      skip(WavUtils.roundUp(size));
    }
  }

  SampleReader getSampleReader(WavFormat format) {
    return [
      readS8,
      readS16,
      readS24,
      readS32,
      readF32,
      readF64,
    ][format.index];
  }
}

typedef SampleReader = double Function();
