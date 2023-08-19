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
import 'package:test/test.dart';
import 'package:wav/util.dart';
import 'package:wav/wav.dart';

void main() async {
  test('toMono', () {
    expect(Wav([], 123).toMono(), []);
    expect(
      Wav(
        [
          Float64List.fromList([1, -1, 0]),
        ],
        123,
      ).toMono(),
      [1, -1, 0],
    );
    expect(
      Wav(
        [
          Float64List.fromList([1, -1, 0]),
          Float64List.fromList([-1, -1, 1]),
        ],
        123,
      ).toMono(),
      [0, -1, 0.5],
    );
  });

  test('WavFormat indices', () {
    // The read and write methods make assumptions about the index values, so
    // this test is just to make sure we don't change them accidentally.
    expect(WavFormat.pcm8bit.index, 0);
    expect(WavFormat.pcm16bit.index, 1);
    expect(WavFormat.pcm24bit.index, 2);
    expect(WavFormat.pcm32bit.index, 3);
    expect(WavFormat.float32.index, 4);
    expect(WavFormat.float64.index, 5);
  });

  test('clamp', () {
    expect(clamp(-1, 10), 0);
    expect(clamp(5, 10), 5);
    expect(clamp(15, 10), 10);
  });

  test('fold', () {
    expect(fold(-1000, 8), 152);
    expect(fold(-128, 8), 0);
    expect(fold(-127, 8), 1);
    expect(fold(-3, 8), 125);
    expect(fold(0, 8), 128);
    expect(fold(5, 8), 133);
    expect(fold(127, 8), 255);
    expect(fold(128, 8), 0);
    expect(fold(129, 8), 1);
    expect(fold(255, 8), 127);
    expect(fold(256, 8), 128);
    expect(fold(1000, 8), 104);
  });

  test('roundUpToEven', () {
    expect(roundUpToEven(0), 0);
    expect(roundUpToEven(1), 2);
    expect(roundUpToEven(2), 2);
    expect(roundUpToEven(3), 4);
    expect(roundUpToEven(4), 4);
    expect(roundUpToEven(1001), 1002);
  });

  test('sampleToInt', () {
    const eps = 1e-6;
    const step = 1.0 / 128;

    expect(sampleToInt(-1, 8), 0);
    expect(sampleToInt(-1 + step - eps, 8), 0);
    expect(sampleToInt(-1 + step + eps, 8), 1);

    expect(sampleToInt(-step - eps, 8), 126);
    expect(sampleToInt(-step + eps, 8), 127);
    expect(sampleToInt(-eps, 8), 127);

    expect(sampleToInt(eps, 8), 128);
    expect(sampleToInt(step - eps, 8), 128);
    expect(sampleToInt(step + eps, 8), 129);

    expect(sampleToInt(1 - step - eps, 8), 254);
    expect(sampleToInt(1 - step + eps, 8), 255);
    expect(sampleToInt(1, 8), 255);
  });

  test('intToSample', () {
    const eps = 1e-12;
    const step = 1.0 / 127.5;

    expect(intToSample(0, 8), closeTo(-1, eps));
    expect(intToSample(1, 8), closeTo(-1 + step, eps));
    expect(intToSample(127, 8), closeTo(-0.5 * step, eps));
    expect(intToSample(128, 8), closeTo(0.5 * step, eps));
    expect(intToSample(254, 8), closeTo(1 - step, eps));
    expect(intToSample(255, 8), closeTo(1, eps));
  });

  test('intToSample bijective with sampleToInt', () {
    for (int i = 0; i < 255; ++i) {
      expect(sampleToInt(intToSample(i, 8), 8), i);
    }
  });

  test('sampleToInt bijective with intToSample', () {
    const eps = 1e-12;
    for (int i = 0; i < 256; ++i) {
      final x = 2.0 * i / 255.0 - 1.0;
      expect(intToSample(sampleToInt(x, 8), 8), closeTo(x, eps));
    }
  });
}
