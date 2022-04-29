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

int nextPowerOf2(int x) {
  --x;
  x |= x >> 1;
  x |= x >> 2;
  x |= x >> 4;
  x |= x >> 8;
  x |= x >> 16;
  x |= x >> 32;
  ++x;
  return x;
}

Float64List padWithZeros(Float64List a, int n) {
  final b = Float64List(n);
  for (int i = 0; i < a.length; ++i) {
    b[i] = a[i];
  }
  return b;
}

Float64List normalizeRmsVolume(List<double> a, double target) {
  final b = Float64List.fromList(a);
  double squareSum = 0;
  for (final x in b) {
    squareSum += x * x;
  }
  double factor = target * math.sqrt(b.length / squareSum);
  for (int i = 0; i < b.length; ++i) {
    b[i] *= factor;
  }
  return b;
}

Float64x2 conjugate(Float64x2 z) {
  return Float64x2(z.x, -z.y);
}

Float64x2List createConjugates(Float64x2List a) {
  final b = Float64x2List((a.length - 2) * 2 + 2);
  for (int i = 0; i < a.length; ++i) {
    b[i] = a[i];
  }
  for (int i = 1; i < a.length - 1; ++i) {
    b[a.length - 1 + i] = conjugate(a[a.length - 1 - i]);
  }
  return b;
}

void main(List<String> argv) async {
  if (argv.length != 2) {
    print('Wrong number of args. Usage:');
    print('  dart run faster.dart input.wav output.wav');
    return;
  }

  final wav = await Wav.readFile(argv[0]);
  final n = nextPowerOf2(wav.channels[0].length);
  final fft = FFT(n);
  //final stft = STFT(2048);
  final chan = <Float64List>[];
  for (final c in wav.channels) {
    final freq = fft.realFft(padWithZeros(c, n)).discardConjugates();
    for (int i = freq.length ~/ 2; i < freq.length; ++i) {
      //final z = freq[i];
      //final amp = math.sqrt(z.x * z.x + z.y * z.y);
      //var phase = math.atan2(z.y, z.x);
      //freq[i] = Float64x2(amp * math.cos(phase), amp * math.sin(phase));
      //freq[0] = Float64x2(0, 0);
    }
    final b = fft.realInverseFft(createConjugates(freq));
    normalizeRmsVolume(b, 0.3);
    chan.add(b);
    //final b = <double>[];
    //stft.run(c, (freq) {
    //  for (int i = 0; i < freq.length; ++i) {
    //    final z = freq[i];
    //    freq[i] = Float64x2(math.sqrt(z.x * z.x + z.y * z.y), 0);
    //  }
    //  final d = fft.realInverseFft(freq);
    //  b.addAll(d);
    //});
    //chan.add(normalizeRmsVolume(b, 0.3));
  }
  Wav(chan, wav.samplesPerSecond).writeFile(argv[1]);
}
