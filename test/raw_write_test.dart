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
import 'package:wav/wav.dart';

void writeTest(String name, WavFormat format) {
  test('Write $format file', () async {
    final filename = 'test/400Hz-$name.raw';
    final tempFilename = '$filename.temp';
    final channels = [Float64List(101), Float64List(101)];
    for (int i = 0; i < 101; ++i) {
      final t = i * 2 * math.pi * 400 / 8000;
      channels[0][i] = math.sin(t);
      channels[1][i] = math.cos(t);
    }
    await writeRawAudioFile(tempFilename, channels, format);

    final expected = await File(filename).readAsBytes();
    final actual = await File(tempFilename).readAsBytes();
    expect(actual, expected);

    await File(tempFilename).delete();
  });
}

void main() async {
  writeTest('8bit-stereo', WavFormat.pcm8bit);
  writeTest('16bit-stereo', WavFormat.pcm16bit);
  writeTest('24bit-stereo', WavFormat.pcm24bit);
  writeTest('32bit-stereo', WavFormat.pcm32bit);
  writeTest('float32-stereo', WavFormat.float32);
  // See https://github.com/liamappelbe/wav/issues/12
  // writeTest('float64-stereo', WavFormat.float64);

  test('If channels are different lengths, pad them with zeros', () {
    final channels = [
      Float64List.fromList([1, 1, 1, 1, 1, 1]),
      Float64List.fromList([-1, -1, -1, -1]),
    ];
    final buf = (BytesBuilder()
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255, 128, 255, 128]))
        .takeBytes();
    expect(writeRawAudio(channels, WavFormat.pcm8bit), buf);
  });

  test('Writing includes padding byte', () {
    final channels = [
      Float64List.fromList([1, -1, 1, -1, 1, -1, 1, -1, 1])
    ];
    final buf = (BytesBuilder()
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255, 0])) // Padded to 10.
        .takeBytes();
    expect(writeRawAudio(channels, WavFormat.pcm8bit), buf);
  });
}
