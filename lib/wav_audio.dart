import 'dart:typed_data';

import 'Positional_Byte_Reader.dart';
import 'wav_format.dart';
import 'wav_header.dart';

class WavAudioReader
 {
  /// Read a Wav from a byte buffer.
  ///
  /// Not all formats are supported. See [WavFormat] for a canonical list.
  /// Unrecognized metadata will be ignored.
  static List<Float64List> readAudio(
    PositionalByteReader position, 
    WavHeader header,
    )
  {
    // Read samples.
    final readSample = position.sampleReader(header.format);
    final channels = <Float64List>[];
    for (int i = 0; i < header.numChannels; ++i) {
      channels.add(Float64List(header.numSamples));
    }
    for (int i = 0; i < header.numSamples; ++i) {
      for (int j = 0; j < header.numChannels; ++j) {
        channels[j][i] = readSample();
      }
    }
    return channels;
  }
}