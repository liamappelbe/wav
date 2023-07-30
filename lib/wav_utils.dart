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

class WavUtils {
  /// Returns the closest number to [x] int the range [0, y].
  static int clamp(int x, int y) => x < 0
      ? 0
      : x > y
          ? y
          : x;

  /// When writing the WAV file using any of the formats that store audio as
  /// an integer, this scaling factor can be used to map the floating point
  /// representation of audio amplitude (a value between -1.0 and 1.0) to the
  /// range of integers.
  ///
  /// For example, using 16 bits per sample, the range of integers is
  /// -1 * 2 ^ 15 to 2 ^ 15 - 1 and we use a scaling factor of 2 ^ 15 to map
  /// our floating point amplitudes into this range.
  static double writeScale(int bits) => (1 << (bits - 1)) * 1.0;

  /// When reading integer format WAV files, we subtract 0.5 to account for
  /// the asymetry in the range of integers (|int.min| ==  |int.max| + 1).
  static double readScale(int bits) => writeScale(bits) - 0.5;

  static int fold(int x, int bits) => (x + (1 << (bits - 1))) % (1 << bits);

  // Chunk is always padded to an even number of bytes.
  static int roundUp(int x) => x + (x % 2);
}
