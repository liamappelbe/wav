/// The supported WAV formats.
enum WavFormat {
  pcm8bit,
  pcm16bit,
  pcm24bit,
  pcm32bit,
  float32,
  float64,
}

extension WavFormatExtension on WavFormat {
  int get bitsPerSample {
    switch(this){
      case WavFormat.pcm8bit: return 8;
      case WavFormat.pcm16bit: return 16;
      case WavFormat.pcm24bit: return 24;
      case WavFormat.pcm32bit: return 32;
      case WavFormat.float32: return 32;
      case WavFormat.float64: return 64;
    }
  }  

  int get bytesPerSample {
    return bitsPerSample ~/ 8;
  }
}

class WavHeader {
  WavFormat format;
  int numChannels;
  int numSamples;
  int samplesPerSecond;

  WavHeader(
    this.numChannels, 
    this.numSamples, 
    this.format, 
    this.samplesPerSecond,
  );
}