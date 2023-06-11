const kFormatSize = 16;
const kFactSize = 4;
const kFileSizeWithoutData = 36;
const kFloatFmtExtraSize = 12;
const kPCM = 1;
const kFloat = 3;
const kStrRiff = 'RIFF';
const kStrWave = 'WAVE';
const kStrFmt = 'fmt ';
const kStrData = 'data';
const kStrFact = 'fact';

// [0, 2] => [0, 2 ^ bits - 1]
double wScale(int bits) => (1 << (bits - 1)) * 1.0;
double rScale(int bits) => wScale(bits) - 0.5;
int fold(int x, int bits) => (x + (1 << (bits - 1))) % (1 << bits);
double u2f(int x, int b) => (x / rScale(b)) - 1;
