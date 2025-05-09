/// The number of lamport per sol (1 billion).
const int lamportsPerSol = 1000000000;

/// Converts [sol] to lamports.
BigInt _intToLamports(final int sol) {
  return sol.toBigInt() * lamportsPerSol.toBigInt();
}

/// Converts [sol] to lamports.
BigInt _numToLamports(final num sol) {
  const int decimalPlaces = 9;
  final String value = sol.toStringAsFixed(decimalPlaces);
  final int decimalPosition = value.length - decimalPlaces;
  return BigInt.parse(value.substring(0, decimalPosition - 1) +
      value.substring(decimalPosition));
}

/// Converts [sol] to lamports.
BigInt solToLamports(final num sol) {
  assert(sol is int || sol is double);
  return sol is int ? _intToLamports(sol) : _numToLamports(sol);
}

///Convert the value into bigint with  input number
double getPrecision(int precision) {
  double result = 1;
  double baseValue = 10;
  for (int i = 0; i < precision; i++) {
    result = result * baseValue;
  }
  return result;
}

/// Num Extension
/// ------------------------------------------------------------------------------------------------

extension NumToBigInt on num {
  /// Creates a [BigInt] from `this` number value.
  BigInt toBigInt() => BigInt.from(this);
}
