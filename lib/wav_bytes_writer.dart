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

class WavBytesWriter {
  WavBytesWriter();

  final bytes = BytesBuilder();

  BytesBuilder writeU8(int x) => bytes..addByte(x);
  BytesBuilder writeU16(int x) => writeU8(x)..addByte(x >> 8);
  BytesBuilder writeU24(int x) => writeU16(x)..addByte(x >> 16);
  BytesBuilder writeU32(int x) => writeU24(x)..addByte(x >> 24);
  int clamp(int x, int y) => x < 0
      ? 0
      : x > y
          ? y
          : x;
  int f2u(double x, int b) =>
      clamp(((x + 1) * WavUtils.writeScale(b)).floor(), (1 << b) - 1);
  BytesBuilder writeS8(double x) => writeU8(f2u(x, 8));
  BytesBuilder writeS16(double x) => writeU16(WavUtils.fold(f2u(x, 16), 16));
  BytesBuilder writeS24(double x) => writeU24(WavUtils.fold(f2u(x, 24), 24));
  BytesBuilder writeS32(double x) => writeU32(WavUtils.fold(f2u(x, 32), 32));
  final fbuf = ByteData(8);
  void writeBytes(ByteData b, int n) => bytes.add(b.buffer.asUint8List(0, n));
  void writeF32(double x) =>
      writeBytes(fbuf..setFloat32(0, x, Endian.little), 4);
  void writeF64(double x) =>
      writeBytes(fbuf..setFloat64(0, x, Endian.little), 8);
  void writeString(String str) {
    for (int c in str.codeUnits) {
      bytes.addByte(c);
    }
  }

  SampleWriter getSampleWriter(WavFormat format) =>
      [writeS8, writeS16, writeS24, writeS32, writeF32, writeF64][format.index];

  Uint8List takeBytes() => bytes.takeBytes();
}

typedef SampleWriter = void Function(double);
