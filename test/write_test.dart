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
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:wav/wav.dart';

void writeTest(int bits, WavFormat format) {
  test('Write ${bits}bit file', () async {
    final filename = 'test/400Hz-${bits}bit.wav';
    final tempFilename = '$filename.temp';
    final channels = [Float64List(101), Float64List(101)];
    for (int i = 0; i < 101; ++i) {
      final t = i * 2 * math.pi * 400 / 8000;
      channels[0][i] = math.sin(t);
      channels[1][i] = math.cos(t);
    }
    final wav = Wav(channels, 8000, format);
    await wav.writeFile(tempFilename);

    final expected = await File(filename).readAsBytes();
    final actual = await File(tempFilename).readAsBytes();
    expect(actual, expected);

    await File(tempFilename).delete();
  });
}

void main() async {
  writeTest(8, WavFormat.pcm8bit);
  writeTest(16, WavFormat.pcm16bit);
  writeTest(24, WavFormat.pcm24bit);
  writeTest(32, WavFormat.pcm32bit);
}
