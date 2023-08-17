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
import 'package:test/test.dart';
import 'package:wav/wav.dart';

import 'test_util.dart';

void bijectiveTest(String name, WavFormat format, int numChannels) {
  test('Reading and writing $format file is bijective', () async {
    final tempFilename = 'test/bijective-$name.wav.temp';
    final rand = Rand();
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(12345));
      for (int j = 0; j < 12345; ++j) {
        channels[i][j] = rand.next();
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
  bijectiveTest('8bit-mono', WavFormat.pcm8bit, 1);
  bijectiveTest('8bit-stereo', WavFormat.pcm8bit, 2);
  bijectiveTest('16bit-mono', WavFormat.pcm16bit, 1);
  bijectiveTest('16bit-stereo', WavFormat.pcm16bit, 2);
  bijectiveTest('24bit-mono', WavFormat.pcm24bit, 1);
  bijectiveTest('24bit-stereo', WavFormat.pcm24bit, 2);
  bijectiveTest('32bit-mono', WavFormat.pcm32bit, 1);
  bijectiveTest('32bit-stereo', WavFormat.pcm32bit, 2);
  bijectiveTest('float32-mono', WavFormat.float32, 1);
  bijectiveTest('float32-stereo', WavFormat.float32, 2);
  bijectiveTest('float64-mono', WavFormat.float64, 1);
  bijectiveTest('float64-stereo', WavFormat.float64, 2);
}
