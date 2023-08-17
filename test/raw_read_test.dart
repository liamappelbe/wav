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
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:wav/raw_file.dart';
import 'package:wav/wav_types.dart';

import 'test_util.dart';

void readTest(String name, WavFormat format, int numChannels, int bitsOfAccuracy) {
  test('Read $name', () async {
    final filename = 'test/data/golden-$name.raw';
    final raw = await readRawAudioFile(filename, numChannels, format);
    final epsilon = math.pow(0.5, bitsOfAccuracy - 1);
    expect(raw.length, numChannels);
    final rand = Rand();
    for (int i = 0; i < numChannels; ++i) {
      expect(raw[i].length, 101);
      for (int j = 0; j < 101; ++j) {
        expect(raw[i][j], closeTo(rand.next(), epsilon));
      }
    }
  });

  test('readRawAudio throws on inconsistent file size', () {
    final bytes = Uint8List.fromList([0, 1, 2]);
    expect(
      () => readRawAudio(bytes, 2, WavFormat.pcm16bit),
      throwsA(isA<Exception>()),
    );
  });
}

void main() async {
  readTest('8bit-mono', WavFormat.pcm8bit, 1, 8);
  readTest('8bit-stereo', WavFormat.pcm8bit, 2, 8);
  readTest('16bit-mono', WavFormat.pcm16bit, 1, 16);
  readTest('16bit-stereo', WavFormat.pcm16bit, 2, 16);
  readTest('24bit-mono', WavFormat.pcm24bit, 1, 20);
  readTest('24bit-stereo', WavFormat.pcm24bit, 2, 20);
  readTest('32bit-mono', WavFormat.pcm32bit, 1, 32);
  readTest('32bit-stereo', WavFormat.pcm32bit, 2, 32);
  readTest('float32-mono', WavFormat.float32, 1, 26);
  readTest('float32-stereo', WavFormat.float32, 2, 26);
  readTest('float64-mono', WavFormat.float64, 1, 52);
  readTest('float64-stereo', WavFormat.float64, 2, 52);
}
