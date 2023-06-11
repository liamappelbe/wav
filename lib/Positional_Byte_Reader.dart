import 'dart:typed_data';

/// Reads a series of bytes, keeping track of the position (i.e. number of bytes
/// already read) in the bytes stream.
class PositionalByteReader
{
  final Uint8List bytes;
  int p;

  PositionalByteReader(this.bytes, { this.p = 0, });
    
  void skip(int n) {
    p += n;
    if (p > bytes.length) {
      throw FormatException('WAV is corrupted, or not a WAV file.');
    }
  }

  ByteData read(int n) {
    final p0 = p;
    skip(n);
    return ByteData.sublistView(bytes, p0, p);
  }
}