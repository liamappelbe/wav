# wav

[![pub package](https://img.shields.io/pub/v/wav.svg)](https://pub.dev/packages/wav)
[![Build Status](https://github.com/liamappelbe/wav/workflows/CI/badge.svg)](https://github.com/liamappelbe/wav/actions?query=workflow%3ACI+branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/liamappelbe/wav/badge.svg?branch=main)](https://coveralls.io/github/liamappelbe/wav?branch=main)

Simple tools for reading and writing WAV and raw audio files. Written in pure
Dart, with no dependencies.

This package currently supports reading and writing 8/16/24/32 bit PCM, and
32/64 bit float formats. Other formats can be added as needed (just file a bug).

This package also supports WAVE_FORMAT_EXTENSIBLE, but only for reading.
Extensible WAVs are essentially treated as ordinary WAV files, because
wValidBitsPerSample and dwChannelMask are ignored. Please file a bug if you have
a use case for either of these metadata fields, or for writing extensible WAV
files.

## Usage

```dart
// Read a WAV file.
final wav = await Wav.readFile(filename);

// Look at its metadata.
print(wav.format);
print(wav.samplesPerSecond);

// Mess with its audio data.
for (final chan in wav.channels) {
  for (int i = 0; i < chan.length; ++i) {
    chan[i] /= 2;  // Decrease the volume.
  }
}

// Write to another WAV file.
await wav.writeFile(otherFilename);
```
