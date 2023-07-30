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
import 'package:wav/raw_file.dart';
import 'package:wav/wav_types.dart';

void bijectiveTest(String name, WavFormat format) {
  test('Reading and writing $format file is bijective', () async {
    final rand = math.Random(1557892);
    final tempFilename = 'test/bijective-$name.raw.temp';
    final numChannels = 2;
    final before = [Float64List(1392), Float64List(1392)];
    for (int i = 0; i < 1392; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        before[j][i] = 2 * rand.nextDouble() - 1;
      }
    }

    await writeRawAudioFile(tempFilename, before, format);
    final after = await readRawAudioFile(tempFilename, numChannels, format);

    final expected = writeRawAudio(before, format);
    final actual = writeRawAudio(after, format);
    expect(actual, expected);

    await File(tempFilename).delete();
  });
}

void main() async {
  bijectiveTest('8bit-stereo', WavFormat.pcm8bit);
  bijectiveTest('16bit-stereo', WavFormat.pcm16bit);
  bijectiveTest('24bit-stereo', WavFormat.pcm24bit);
  bijectiveTest('32bit-stereo', WavFormat.pcm32bit);
  bijectiveTest('float32-stereo', WavFormat.float32);
  bijectiveTest('float64-stereo', WavFormat.float64);
}