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
import 'package:wav/wav.dart';
import 'util.dart';

void main(List<String> argv) async {
  if (argv.length != 2) {
    print('Wrong number of args. Usage:');
    print('  dart run normalize.dart input.wav output.wav');
    return;
  }

  final wav = await Wav.readFile(argv[0]);
  final chan = <Float64List>[];
  for (final c in wav.channels) {
    chan.add(normalizeRmsVolume(c, 0.3));
  }
  await Wav(chan, wav.samplesPerSecond).writeFile(argv[1]);
}
