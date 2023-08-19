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

import 'package:wav/wav.dart';

void main(List<String> argv) async {
  if (argv.length != 1) {
    print('Wrong number of args. Usage:');
    print('  dart run info.dart input.wav');
    return;
  }

  final wav = await Wav.readFile(argv[0]);
  print(argv[0]);
  print('Format: ${wav.format}');
  print('Channels: ${wav.channels.length}');
  print('Sample rate: ${wav.samplesPerSecond} Hz');
  print('Duration: ${wav.duration.toStringAsFixed(3)} sec');
}
