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

void writeTest(String name, WavFormat format, int numChannels) {
  test('Write $format file', () async {
    final filename = 'test/data/golden-$name.wav';
    final tempFilename = '$filename.temp';
    final rand = Rand();
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(101));
      for (int j = 0; j < 101; ++j) {
        channels[i][j] = rand.next();
      }
    }
    final wav = Wav(channels, 8000, format);
    await wav.writeFile(tempFilename);

    var expected = await File(filename).readAsBytes();
    final actual = await File(tempFilename).readAsBytes();
    expect(actual, expected);

    await File(tempFilename).delete();
  });
}

void main() async {
  writeTest('8bit-mono', WavFormat.pcm8bit, 1);
  writeTest('8bit-stereo', WavFormat.pcm8bit, 2);
  writeTest('16bit-mono', WavFormat.pcm16bit, 1);
  writeTest('16bit-stereo', WavFormat.pcm16bit, 2);
  writeTest('24bit-mono', WavFormat.pcm24bit, 1);
  writeTest('24bit-stereo', WavFormat.pcm24bit, 2);
  writeTest('32bit-mono', WavFormat.pcm32bit, 1);
  writeTest('32bit-stereo', WavFormat.pcm32bit, 2);
  writeTest('float32-mono', WavFormat.float32, 1);
  writeTest('float32-stereo', WavFormat.float32, 2);
  writeTest('float64-mono', WavFormat.float64, 1);
  writeTest('float64-stereo', WavFormat.float64, 2);

  test('Writing includes padding byte', () {
    final wav = Wav(
      [
        Float64List.fromList([1, -1, 1, -1, 1, -1, 1, -1, 1])
      ],
      100,
      WavFormat.pcm8bit,
    );
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([9, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255, 0])) // Padded to 10.
        .takeBytes();
    expect(wav.write(), buf);
  });

  test('If channels are different lengths, pad them with zeros', () {
    final wav = Wav(
      [
        Float64List.fromList([1, 1, 1, 1, 1, 1]),
        Float64List.fromList([-1, -1, -1, -1]),
      ],
      100,
      WavFormat.pcm8bit,
    );
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([48, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([2, 0])
          ..add([100, 0, 0, 0])
          ..add([200, 0, 0, 0])
          ..add([2, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([12, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255, 128, 255, 128]))
        .takeBytes();
    expect(wav.write(), buf);
  });

  test('If samples exceed [-1, 1], clamp them', () {
    final wav = Wav(
      [
        Float64List.fromList([-100, -1.1, 1.1, 100])
      ],
      100,
      WavFormat.pcm8bit,
    );
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([40, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([4, 0, 0, 0])
          ..add([0, 0, 255, 255]))
        .takeBytes();
    expect(wav.write(), buf);
  });

  test('Float formats do not clamp samples', () {
    final wav = Wav(
      [
        Float64List.fromList([-100, 100])
      ],
      100,
      WavFormat.float32,
    );
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([56, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([3, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([144, 1, 0, 0])
          ..add([4, 0])
          ..add([32, 0])
          ..add('fact'.codeUnits)
          ..add([4, 0, 0, 0])
          ..add([2, 0, 0, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([0, 0, 200, 194, 0, 0, 200, 66]))
        .takeBytes();
    expect(wav.write(), buf);
  });
}
