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

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:wav/wav.dart';

void main() async {
  test('toMono', () {
    expect(Wav([], 123).toMono(), []);
    expect(
      Wav(
        [
          Float64List.fromList([1, -1, 0])
        ],
        123,
      ).toMono(),
      [1, -1, 0],
    );
    expect(
      Wav(
        [
          Float64List.fromList([1, -1, 0]),
          Float64List.fromList([-1, -1, 1])
        ],
        123,
      ).toMono(),
      [0, -1, 0.5],
    );
  });
}
