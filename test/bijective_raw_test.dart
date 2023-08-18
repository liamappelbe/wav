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
import 'package:wav/raw_file.dart';
import 'package:wav/wav_format.dart';

import 'test_util.dart';

void bijectiveTest(String name, WavFormat format, int numChannels) {
  test('Reading and writing $format file is bijective', () async {
    final tempFilename = 'test/bijective-$name.raw.temp';
    final rand = Rand();
    final before = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      before.add(Float64List(12345));
      for (int j = 0; j < 12345; ++j) {
        before[i][j] = rand.next();
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
