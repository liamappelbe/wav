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
import 'package:fftea/fftea.dart';
import 'package:wav/wav.dart';
import 'util.dart';

void main(List<String> argv) async {
  if (argv.length != 2) {
    print('Wrong number of args. Usage:');
    print('  dart run weird.dart input.wav output.wav');
    return;
  }

  final wav = await Wav.readFile(argv[0]);
  final len = wav.channels[0].length;
  final n = nextPowerOf2(len);
  final len2 = math.min(n, len + 6 * wav.samplesPerSecond);
  final start = math.min((0.1 * wav.samplesPerSecond).toInt(), len ~/ 10);
  final fft = FFT(n);
  final chan = <Float64List>[];
  final goldenRatio = (math.sqrt(5) + 1) / 2;
  for (final c in wav.channels) {
    final freq = fft.realFft(padWithZeros(c, n)).discardConjugates();
    for (int i = 0; i < freq.length; ++i) {
      final z = freq[i];
      final amp = math.pow(z.x * z.x + z.y * z.y, math.sqrt1_2);
      final phase = math.atan2(z.y, z.x) * goldenRatio;
      freq[i] = Float64x2(amp * math.cos(phase), amp * math.sin(phase));
    }
    final b = fft.realInverseFft(createConjugates(freq));
    final b2 = b.sublist(0, len2);
    applyFadeIn(b2, start);
    applyFadeOut(b2, len);
    chan.add(normalizeRmsVolume(b2, 0.3));
  }
  await Wav(chan, wav.samplesPerSecond).writeFile(argv[1]);
}
