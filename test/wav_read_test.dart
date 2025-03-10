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

import 'test_util.dart';

void readTest(
  String name,
  WavFormat format,
  int numChannels,
  int bitsOfAccuracy,
) {
  test('Read $format file', () async {
    final filename = 'test/data/golden-$name.wav';
    final wav = await Wav.readFile(filename);
    final epsilon = math.pow(0.5, bitsOfAccuracy - 1);
    expect(wav.samplesPerSecond, 8000);
    expect(wav.format, format);
    expect(wav.channels.length, numChannels);
    expect(wav.duration, 0.012625);
    final rand = Rand();
    for (int i = 0; i < numChannels; ++i) {
      expect(wav.channels[i].length, 101);
      for (int j = 0; j < 101; ++j) {
        expect(wav.channels[i][j], closeTo(rand.next(), epsilon));
      }
    }
  });
}

void waveExtensibleReadTest(
  String name,
  WavFormat subFormat,
  int bitsOfAccuracy,
) {
  test('Read $subFormat file', () async {
    final filename = 'test/data/sine-$name-3channels.wav';
    final wav = await Wav.readFile(filename);
    expect(wav.samplesPerSecond, 8000);
    expect(wav.format, subFormat);
    expect(wav.channels.length, 3);
    expect(wav.duration, 0.25);

    final epsilon = math.pow(0.5, bitsOfAccuracy - 1);

    for (int i = 0; i < 3; ++i) {
      expect(wav.channels[i].length, 2000);

      for (int j = 0; j < wav.channels[i].length; j++) {
        expect(
          wav.channels[i][j],
          closeTo(
            math.sin(
              2 *
                  math.pi *
                  440.0 *
                  (i + 1) *
                  (j.toDouble() / wav.samplesPerSecond.toDouble()),
            ),
            epsilon,
          ),
          reason: 'Channel $i, sample $j',
        );
      }
    }
  });
}

void main() async {
  readTest('8bit-mono', WavFormat.pcm8bit, 1, 8);
  readTest('8bit-stereo', WavFormat.pcm8bit, 2, 8);
  readTest('16bit-mono', WavFormat.pcm16bit, 1, 16);
  readTest('16bit-stereo', WavFormat.pcm16bit, 2, 16);
  readTest('24bit-mono', WavFormat.pcm24bit, 1, 24);
  readTest('24bit-stereo', WavFormat.pcm24bit, 2, 24);
  readTest('32bit-mono', WavFormat.pcm32bit, 1, 32);
  readTest('32bit-stereo', WavFormat.pcm32bit, 2, 32);
  readTest('float32-mono', WavFormat.float32, 1, 26);
  readTest('float32-stereo', WavFormat.float32, 2, 26);
  readTest('float64-mono', WavFormat.float64, 1, 52);
  readTest('float64-stereo', WavFormat.float64, 2, 52);

  waveExtensibleReadTest('8bit', WavFormat.pcm8bit, 8);
  waveExtensibleReadTest('16bit', WavFormat.pcm16bit, 16);
  waveExtensibleReadTest('24bit', WavFormat.pcm24bit, 24);
  waveExtensibleReadTest('32bit', WavFormat.pcm32bit, 32);
  waveExtensibleReadTest('float32', WavFormat.float32, 26);
  waveExtensibleReadTest('float64', WavFormat.float64, 52);

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

  test('Read iOS unprocessed wav file', () async {
    final filename = 'test/data/ios-unprocessed-float32-mono.wav';
    final wav = await Wav.readFile(filename);

    expect(wav.samplesPerSecond, 48000);
    expect(wav.format, WavFormat.float32);
    expect(wav.channels.length, 1);

    expect(wav.duration, 0.7);
  });
}
