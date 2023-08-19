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

/// Utility class to incrementally read through a series of bytes, interpreting
/// byte combinations as little endian ints and floats etc. Every read operation
/// moves the read head forward by the corresponding number of bytes.
class BytesReader {
  final Uint8List _bytes;
  int _p = 0;

  /// Constructs a [BytesReader].
  BytesReader(this._bytes);

  /// Skip forward [n] bytes.
  void skip(int n) {
    _p += n;
    if (_p > _bytes.length) {
      throw FormatException('WAV is corrupted, or not a WAV file.');
    }
  }

  ByteData _read(int n) {
    final p0 = _p;
    skip(n);
    return ByteData.sublistView(_bytes, p0, _p);
  }

  /// Reads a Uint8 from the buffer.
  int readUint8() => _read(1).getUint8(0);

  /// Reads a Uint16 from the buffer.
  int readUint16() => _read(2).getUint16(0, Endian.little);

  /// Reads a Uint24 from the buffer.
  int readUint24() => readUint8() + 0x100 * readUint16();

  /// Reads a Uint32 from the buffer.
  int readUint32() => _read(4).getUint32(0, Endian.little);

  bool _checkString(String s) =>
      s ==
      String.fromCharCodes(
        Uint8List.sublistView(_read(s.length)),
      );

  /// Reads a string of the same length as [s], then checks that the read string
  /// matches [s]. Throws a [FormatException] if they don't match. [s] must be
  /// ASCII only.
  void assertString(String s) {
    if (!_checkString(s)) {
      throw FormatException('WAV is corrupted, or not a WAV file.');
    }
  }

  /// Reads RIFF chunks until one is found that has the given [identifier]. When
  /// this function returns, the read head will either be just after the
  /// [identifier] (about to read the size), or at the end of the buffer.
  void findChunk(String identifier) {
    while (!_checkString(identifier)) {
      final size = readUint32();
      skip(roundUpToEven(size));
    }
  }

  double _readSample8bit() => intToSample(readUint8(), 8);
  double _readSample16Bit() => intToSample(fold(readUint16(), 16), 16);
  double _readSample24Bit() => intToSample(fold(readUint24(), 24), 24);
  double _readSample32Bit() => intToSample(fold(readUint32(), 32), 32);
  double _readSampleFloat32() => _read(4).getFloat32(0, Endian.little);
  double _readSampleFloat64() => _read(8).getFloat64(0, Endian.little);

  /// Returns a closure that reads samples of the given [format] from this
  /// buffer. Calling these closures advances the read head of this buffer.
  SampleReader getSampleReader(WavFormat format) {
    return [
      _readSample8bit,
      _readSample16Bit,
      _readSample24Bit,
      _readSample32Bit,
      _readSampleFloat32,
      _readSampleFloat64,
    ][format.index];
  }
}

/// Reads a sample and returns it as a double, usually in the range [-1, 1].
typedef SampleReader = double Function();
