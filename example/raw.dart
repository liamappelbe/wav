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

import 'dart:io';

import 'package:wav/positional_byte_reader.dart';
import 'package:wav/wav.dart';

void main(List<String> argv) async {
  if (argv.length != 4) {
    print('Wrong number of args. Usage:');
    print('  dart run raw.dart input.raw format numChannels samplesPerSecond');
    print('');
    print('Outputs input_format_numChannels_samplesPerSecond.wav');
    return;
  }

  final filename = argv[0];
  final format = parseFormat(argv[1]);
  final numChannels = int.parse(argv[2]);
  final samplesPerSecond = int.parse(argv[3]);

  // Try to work out how many samples there are, based on the samples per second
  final numSamples = await countSamples(filename, format, numChannels);

  // Since this is raw data, we don't have a header, so we need to construct one
  // from the apriori information supplied in the header
  final header = WavHeader(numChannels, numSamples, format, samplesPerSecond);

  // Construct a wav from the raw audio data
  var bytes = await File(filename).readAsBytes();
  var byteReader = PositionalByteReader(bytes);
  final channels = WavDataReader(byteReader).readData(header);
  var wav = Wav(channels, header.samplesPerSecond, header.format);

  // Write to output file
  var fileParts = filename.split('.');
  var outputFile = '${fileParts[0]}_${argv[1]}_${argv[2]}_${argv[3]}.wav';
  await wav.writeFile(outputFile);
}

WavFormat parseFormat(String formatParam) {
  switch (formatParam) {
    case 'pcm8bit':
      return WavFormat.pcm8bit;
    case 'pcm16bit':
      return WavFormat.pcm16bit;
    case 'pcm24bit':
      return WavFormat.pcm24bit;
    case 'pcm32bit':
      return WavFormat.pcm32bit;
    case 'float32':
      return WavFormat.float32;
    case 'float64':
      return WavFormat.float64;
    default:
      throw Exception('Unknown format: $formatParam');
  }
}

Future<int> countSamples(String filename, WavFormat format, int numChannels) 
  async
{
  var fileSize = await File(filename).length();
  
  // Make sure the file size is consistent with the arguments
  if (fileSize  % (format.bytesPerSample * numChannels) != 0) {
    throw Exception(
      'Unexpected file size. File size should be a multiple of '
      '${format.bytesPerSample * numChannels} bytes for '
      '${format.bitsPerSample} bit $numChannels channel audio');
  }

  return fileSize ~/ (format.bytesPerSample * numChannels);
}
