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

import 'util.dart';
import 'wav_format.dart';

/// Utility class to construct a byte buffer by writing little endian ints and
/// floats etc. Every write operation appends to the end of the buffer.
class BytesWriter {
  final _bytes = BytesBuilder();

  /// Writes a Uint8 to the buffer.
  void writeUint8(int x) => _bytes.addByte(x);

  /// Writes a Uint16 to the buffer.
  void writeUint16(int x) {
    writeUint8(x);
    writeUint8(x >> 8);
  }

  /// Writes a Uint24 to the buffer.
  void writeUint24(int x) {
    writeUint16(x);
    writeUint8(x >> 16);
  }

  /// Writes a Uint32 to the buffer.
  void writeUint32(int x) {
    writeUint24(x);
    writeUint8(x >> 24);
  }

  void _writeSample8Bit(double x) => writeUint8(sampleToInt(x, 8));
  void _writeSample16Bit(double x) => writeUint16(fold(sampleToInt(x, 16), 16));
  void _writeSample24Bit(double x) => writeUint24(fold(sampleToInt(x, 24), 24));
  void _writeSample32Bit(double x) => writeUint32(fold(sampleToInt(x, 32), 32));

  void _writeBytes(ByteData b, int n) => _bytes.add(b.buffer.asUint8List(0, n));

  static final _fbuf = ByteData(8);
  void _writeSampleFloat32(double x) =>
      _writeBytes(_fbuf..setFloat32(0, x, Endian.little), 4);
  void _writeSampleFloat64(double x) =>
      _writeBytes(_fbuf..setFloat64(0, x, Endian.little), 8);

  /// Writes string [s] to the buffer. [s] must be ASCII only.
  void writeString(String s) {
    for (int c in s.codeUnits) {
      _bytes.addByte(c);
    }
  }

  /// Returns a closure that reads samples of the given [format] from this
  /// buffer. Calling these closures advances the read head of this buffer.
  SampleWriter getSampleWriter(WavFormat format) => [
        _writeSample8Bit,
        _writeSample16Bit,
        _writeSample24Bit,
        _writeSample32Bit,
        _writeSampleFloat32,
        _writeSampleFloat64,
      ][format.index];

  /// Takes the byte buffer from [this] and clears [this].
  Uint8List takeBytes() => _bytes.takeBytes();
}

/// Writes a sample, usually clamping it to the range [-1, 1].
typedef SampleWriter = void Function(double);
