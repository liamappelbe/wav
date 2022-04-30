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

Float64List makeReverb(int l, int n) {
  final r = Float64List(n);
  final rand = math.Random();
  r[0] = 50;
  const decay = -3;
  final sub = math.exp(decay);
  final div = 1 - sub;
  for (int i = 1; i < l; ++i) {
    final noise = rand.nextDouble() * 2 - 1;
    r[i] = noise * (math.exp(decay * i / l) - sub) / div;
  }
  return r;
}

void main(List<String> argv) async {
  if (argv.length != 2) {
    print('Wrong number of args. Usage:');
    print('  dart run reverb.dart input.wav output.wav');
    return;
  }

  final wav = await Wav.readFile(argv[0]);
  final len = wav.channels[0].length;
  final n = nextPowerOf2(len);
  final reverb = makeReverb(wav.samplesPerSecond, n);
  final len2 = math.min(n, len + wav.samplesPerSecond);
  final fft = FFT(n);
  final reverbFreq = fft.realFft(reverb);
  final chan = <Float64List>[];
  for (final c in wav.channels) {
    final freq = fft.realFft(padWithZeros(c, n));
    for (int i = 0; i < freq.length; ++i) {
      freq[i] = complexMult(freq[i], reverbFreq[i]);
    }
    final b = fft.realInverseFft(freq);
    chan.add(normalizeRmsVolume(b.sublist(0, len2), 0.3));
  }
  await Wav(chan, wav.samplesPerSecond).writeFile(argv[1]);
}
