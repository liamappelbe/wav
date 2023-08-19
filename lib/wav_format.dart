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

/// The supported WAV formats.
enum WavFormat {
  /// 8-bit unsigned PCM.
  pcm8bit,

  /// 16-bit signed PCM.
  pcm16bit,

  /// 24-bit signed PCM.
  pcm24bit,

  /// 32-bit signed PCM.
  pcm32bit,

  /// 32-bit float.
  float32,

  /// 64-bit float.
  float64,
}

/// Extension methods for [WavFormat].
extension WavFormatExtension on WavFormat {
  /// The number of bits per sample for this [WavFormat].
  int get bitsPerSample => [8, 16, 24, 32, 32, 64][index];

  /// The number of bytes per sample for this [WavFormat].
  int get bytesPerSample => bitsPerSample ~/ 8;
}
