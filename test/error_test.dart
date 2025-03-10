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
  test('Valid', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(() => Wav.read(buf), returnsNormally);
  });

  test('Not a RIFF', () {
    final buf = (BytesBuilder()
          ..add('RAFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message == 'WAV is corrupted, or not a WAV file.',
        ),
      ),
    );
  });

  test('Not a WAVE', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAYV'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message == 'WAV is corrupted, or not a WAV file.',
        ),
      ),
    );
  });

  test('Missing fmt chunk', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message == 'WAV is corrupted, or not a WAV file.',
        ),
      ),
    );
  });

  test('Missing data chunk', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message == 'WAV is corrupted, or not a WAV file.',
        ),
      ),
    );
  });

  test('Data chunk before fmt chunk', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0])
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message == 'WAV is corrupted, or not a WAV file.',
        ),
      ),
    );
  });

  test('Unknown format code', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([47, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException && e.message == 'Unsupported format: 47, 8',
        ),
      ),
    );
  });

  test('Bad PCM width', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([47, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException && e.message == 'Unsupported format: 1, 47',
        ),
      ),
    );
  });

  test('Bad float width', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([3, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([47, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException && e.message == 'Unsupported format: 3, 47',
        ),
      ),
    );
  });

  test('Truncated fmt chunk', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message == 'WAV is corrupted, or not a WAV file.',
        ),
      ),
    );
  });

  test('Truncated data chunk', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([1, 0])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message == 'WAV is corrupted, or not a WAV file.',
        ),
      ),
    );
  });

  test('Wrong extension size for extensible format', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([254, 255])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([8, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message ==
                  'Extension size of WAVE_FORMAT_EXTENSIBLE should be 22',
        ),
      ),
    );
  });

  test('Wrong valid bits per sample for extensible format', () {
    final buf = (BytesBuilder()
          ..add('RIFF'.codeUnits)
          ..add([46, 0, 0, 0])
          ..add('WAVE'.codeUnits)
          ..add('fmt '.codeUnits)
          ..add([16, 0, 0, 0])
          ..add([254, 255])
          ..add([1, 0])
          ..add([100, 0, 0, 0])
          ..add([100, 0, 0, 0])
          ..add([1, 0])
          ..add([16, 0])
          ..add([22, 0])
          ..add([8, 0])
          ..add([4, 0, 0, 0])
          ..add([3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
          ..add('data'.codeUnits)
          ..add([8, 0, 0, 0])
          ..add([255, 0, 255, 0, 255, 0, 255, 0]))
        .takeBytes();
    expect(
      () => Wav.read(buf),
      throwsA(
        predicate(
          (e) =>
              e is FormatException &&
              e.message ==
                  'wValidBitsPerSample is different from wBitsPerSample',
        ),
      ),
    );
  });
}
