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

import 'test_util.dart';

void writeTest(String name, WavFormat format, int numChannels) {
  test('Write $format file', () async {
    final filename = 'test/data/golden-$name.raw';
    final tempFilename = '$filename.temp';
    final rand = Rand();
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(101));
      for (int j = 0; j < 101; ++j) {
        channels[i][j] = rand.next();
      }
    }
    await writeRawAudioFile(tempFilename, channels, format);

    final expected = await File(filename).readAsBytes();
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

  test('Writing does not include padding byte', () {
    final channels = [
      Float64List.fromList([1, -1, 1, -1, 1, -1, 1, -1, 1])
    ];
    final buf = (BytesBuilder()
          ..add([255, 0, 255, 0, 255, 0, 255, 0, 255])) // Not padded to 10.
        .takeBytes();
    expect(writeRawAudio(channels, WavFormat.pcm8bit), buf);
  });
}
