// Copyright 2023 The wav authors
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

// Random number generator based on 32-bit FNV hash.
//
// We can't use Dart's built in random number generator because we're saving the
// values to a file, and their implementation may change in future.
class Rand {
  static const _prime = 0x1000193;
  static const _mask = (1 << 32) - 1;

  int _x = 0x811c9dc5;

  Rand() {}

  double next() {
    final x = _x;
    _x *= _prime;
    _x &= _mask;
    return 2 * (x.toDouble() / _mask.toDouble()) - 1;
  }
}
