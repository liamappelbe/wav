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

void applyFadeIn(Float64List a, int to) {
  for (int i = 0; i < to; ++i) {
    a[i] *= i / to;
  }
}

void applyFadeOut(Float64List a, int from) {
  for (int i = from; i < a.length; ++i) {
    a[i] *= 1 - (i - from) / (a.length - from);
  }
}

Float64x2 complexMult(Float64x2 a, Float64x2 b) {
  return Float64x2(a.x * b.x - a.y * b.y, a.y * b.x + a.x * b.y);
}
