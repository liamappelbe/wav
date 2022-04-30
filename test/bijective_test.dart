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

void bijectiveTest(int bits, WavFormat format) {
  test('Write ${bits}bit file', () async {
    final rand = math.Random(1557892);
    final tempFilename = 'test/bijective-${bits}bit.wav.temp';
    final channels = [Float64List(1392), Float64List(1392)];
    for (int i = 0; i < 1392; ++i) {
      for (int j = 0; j < 2; ++j) {
        channels[j][i] = 2 * rand.nextDouble() - 1;
      }
    }
    final wavBefore = Wav(channels, 46310, format);
    await wavBefore.writeFile(tempFilename);
    final wavAfter = await Wav.readFile(tempFilename);

    final expected = wavBefore.write();
    final actual = wavAfter.write();
    expect(actual, expected);

    await File(tempFilename).delete();
  });
}

void main() async {
  bijectiveTest(8, WavFormat.pcm8bit);
  bijectiveTest(16, WavFormat.pcm16bit);
  bijectiveTest(24, WavFormat.pcm24bit);
  bijectiveTest(32, WavFormat.pcm32bit);
}
