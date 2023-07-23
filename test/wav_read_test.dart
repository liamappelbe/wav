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
import 'package:wav/wav.dart';

void readTest(String name, WavFormat format, int bitsOfAccuracy) {
  test('Read $format file', () async {
    final filename = 'test/400Hz-$name.wav';
    final wav = await Wav.readFile(filename);
    final epsilon = math.pow(0.5, bitsOfAccuracy - 1);
    expect(wav.samplesPerSecond, 8000);
    expect(wav.format, format);
    expect(wav.channels.length, 2);
    expect(wav.channels[0].length, 101);
    expect(wav.channels[1].length, 101);
    expect(wav.duration, 0.012625);
    print('${wav.channels[0].sublist(0, 10)}');
    for (int i = 0; i < wav.channels[0].length; ++i) {
      final t = i * 2 * math.pi * 400 / 8000;
      expect(wav.channels[0][i], closeTo(math.sin(t), epsilon));
      expect(wav.channels[1][i], closeTo(math.cos(t), epsilon));
    }
  });
}

void main() async {
  readTest('8bit', WavFormat.pcm8bit, 8);
  readTest('16bit', WavFormat.pcm16bit, 16);
  readTest('24bit', WavFormat.pcm24bit, 24);
  readTest('32bit', WavFormat.pcm32bit, 32);
  readTest('float32', WavFormat.float32, 26);
  readTest('float64', WavFormat.float64, 52);

  test('Reading skips unknown chunks', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([0, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('junk'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([0, 0, 0, 0, 0, 0, 0, 0])
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('spam'.codeUnits)
          ..add([13, 0, 0, 0])
          ..add([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
          ..add('data'.codeUnits)
          ..add([9, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255, 0])
          ..add('test'.codeUnits)
          ..add([0, 0, 0, 0]))
        .takeBytes();
    final wav = Wav.read(buf);
    expect(wav.format, WavFormat.pcm8bit);
    expect(wav.samplesPerSecond, 100);
    expect(wav.channels.length, 1);
    expect(wav.channels[0], [1, -1, 1, -1, 1, -1, 1, -1, 1]);
  });

  test('Reading skips extras in the format chunk', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([0, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([20, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add([0, 0, 0, 0])
          ..add('data'.codeUnits)
          ..add([9, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    final wav = Wav.read(buf);
    expect(wav.format, WavFormat.pcm8bit);
    expect(wav.samplesPerSecond, 100);
    expect(wav.channels.length, 1);
    expect(wav.channels[0], [1, -1, 1, -1, 1, -1, 1, -1, 1]);
  });

  test('Reading skips extras in the format chunk, rounded up to 2 bytes', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([0, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([21, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add([0, 0, 0, 0, 0, 0])
          ..add('data'.codeUnits)
          ..add([9, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    final wav = Wav.read(buf);
    expect(wav.format, WavFormat.pcm8bit);
    expect(wav.samplesPerSecond, 100);
    expect(wav.channels.length, 1);
    expect(wav.channels[0], [1, -1, 1, -1, 1, -1, 1, -1, 1]);
  });

  test('Reading float works even if fact chunk is missing', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([0, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([3, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([144, 1, 0, 0])
          ..add([4, 0])
          ..add([32, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([0, 0, 128, 63, 0, 0, 128, 191]))
        .takeBytes();
    final wav = Wav.read(buf);
    expect(wav.format, WavFormat.float32);
    expect(wav.samplesPerSecond, 100);
    expect(wav.channels.length, 1);
    expect(wav.channels[0], [1, -1]);
  });
}
