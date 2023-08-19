## 1.3.0

- Support raw audio files, which are essentially Wav files without their format
  header (ie just the samples).
- Expose some of the internal utils, which may be useful for other serialization
  tasks (eg BytesReader and BytesWriter).

## 1.2.0

- Added a duration method to Wav.

## 1.1.0

- Added support for web by making file IO methods conditional on dart:io.
- Added support for 32/64 bit float formats.

## 1.0.0

- Initial version
