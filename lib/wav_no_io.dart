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

/// Internal detail. Fake file reader function that just throws.
Future<Uint8List> internalReadFile(String filename) {
  throw UnsupportedError('File IO is not available on this platform.');
}

/// Internal detail. Fake file writer function that just throws.
Future<void> internalWriteFile(String filename, Uint8List bytes) {
  throw UnsupportedError('File IO is not available on this platform.');
}
