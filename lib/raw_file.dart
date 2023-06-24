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

import 'wav_bytes_reader.dart';
import 'wav_bytes_writer.dart';
import 'wav_no_io.dart' if (dart.library.io) 'wav_io.dart';
import 'wav_types.dart';

class Raw {
  /// Reads raw audio data from a file.
  ///
  /// Convenience wrapper around [read]. See that method for details.
  static Future<List<Float64List>> readFile(
    String filename,
    int numChannels,
    WavFormat format,
  ) async =>
      read(await internalReadFile(filename), numChannels, format);

  /// Reads raw audio samples from a byte buffer.
  ///
  /// As the buffer won't contain metadata, the format and number of channels
  /// must be  must be known/specified as arguments.
  static List<Float64List> read(
    Uint8List bytes,
    int numChannels,
    WavFormat format,
  ) {
    // Make sure the file size is consistent with the arguments
    final bytesPerSample = format.bytesPerSample;
    if (bytes.length % (bytesPerSample * numChannels) != 0) {
      throw Exception('Unexpected file size. File size should be a multiple of '
          '${bytesPerSample * numChannels} bytes for '
          '${format.bitsPerSample} bit $numChannels channel audio');
    }

    // Calculate the number of samples
    var numSamples = bytes.length ~/ (bytesPerSample * numChannels);

    // Initialise the channels
    final channels = <Float64List>[];
    for (int i = 0; i < numChannels; ++i) {
      channels.add(Float64List(numSamples));
    }

    // Read samples.
    var byteReader = WavBytesReader(bytes);
    final readSample = byteReader.getSampleReader(format);
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        channels[j][i] = readSample();
      }
    }
    return channels;
  }

  /// Writes raw audio data to a file.
  ///
  /// Convenience wrapper around [write]. See that method for details.
  Future<void> writeFile(
    String filename,
    List<Float64List> channels,
    WavFormat format,
  ) async =>
      await internalWriteFile(filename, write(channels, format));

  /// Writes raw audio samples to a byte buffer.
  ///
  /// This will not write any meta-data to the buffer (bits per sample,
  /// number of channels or sample rate).
  static Uint8List write(List<Float64List> channels, WavFormat format) {
    // Calculate sizes etc.
    final numChannels = channels.length;
    int numSamples = 0;
    for (final channel in channels) {
      if (channel.length > numSamples) numSamples = channel.length;
    }

    // Write samples.
    final bytes = WavBytesWriter();
    final writeSample = bytes.getSampleWriter(format);
    for (int i = 0; i < numSamples; ++i) {
      for (int j = 0; j < numChannels; ++j) {
        double sample = i < channels[j].length ? channels[j][i] : 0;
        writeSample(sample);
      }
    }

    final dataSize = numSamples * format.bytesPerSample * numChannels;
    if (dataSize % 2 != 0) {
      bytes.writeU8(0);
    }

    return bytes.takeBytes();
  }
}
