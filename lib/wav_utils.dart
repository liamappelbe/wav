class WavUtils {
  // [0, 2] => [0, 2 ^ bits - 1]
  static double wScale(int bits) => (1 << (bits - 1)) * 1.0;
  static double rScale(int bits) => wScale(bits) - 0.5;
  static int fold(int x, int bits) => (x + (1 << (bits - 1))) % (1 << bits);

  // Chunk is always padded to an even number of bytes.
  static int roundUp(int x) => x + (x % 2);
}
