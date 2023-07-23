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

import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:wav/raw_file.dart';
import 'package:wav/wav_types.dart';

void readTest(String name, WavFormat format, int channels, int bitsOfAccuracy) {
  test('Read $name', () async {
    final filename = 'test/400Hz-$name.raw';
    final raw = await Raw.readFile(filename, channels, format);
    final epsilon = math.pow(0.5, bitsOfAccuracy - 1);
    expect(raw.length, 2);
    expect(raw[0].length, 101);
    expect(raw[1].length, 101);
    print('${raw[0].sublist(0, 10)}');
    for (int i = 0; i < raw[0].length; ++i) {
      final t = i * 2 * math.pi * 400 / 8000;
      expect(raw[0][i], closeTo(math.sin(t), epsilon));
      expect(raw[1][i], closeTo(math.cos(t), epsilon));
    }
  });
}

void main() async {
  readTest('8bit-stereo', WavFormat.pcm8bit, 2, 8);
  readTest('16bit-stereo', WavFormat.pcm16bit, 2, 16);
  readTest('24bit-stereo', WavFormat.pcm24bit, 2, 20);
  readTest('32bit-stereo', WavFormat.pcm32bit, 2, 32);
  readTest('float32-stereo', WavFormat.float32, 2, 26);
  readTest('float64-stereo', WavFormat.float64, 2, 52);
}
