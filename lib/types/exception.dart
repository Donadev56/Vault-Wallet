class InvalidPasswordException implements Exception {
  final String message;
  InvalidPasswordException([this.message = "Invalid credentials."]);

  @override
  String toString() => message;
}

class TransactionFailureException implements Exception {
  final String message;
  TransactionFailureException([this.message = "Invalid credentials."]);

  @override
  String toString() => message;
}

class InsufficientTransactionFeesException implements Exception {
  final String message;
  InsufficientTransactionFeesException([this.message = "Invalid credentials."]);

  @override
  String toString() => message;
}

class RpcUrlLimitException implements Exception {
  final String message;
  RpcUrlLimitException([this.message = "Invalid credentials."]);

  @override
  String toString() => message;
}

class InvalidSignatureException implements Exception {
  final String message;
  InvalidSignatureException(
      [this.message = "Signature is invalid or tampered."]);

  @override
  String toString() => message;
}

class MalformedPrivateKeyException implements Exception {
  final String message;
  MalformedPrivateKeyException(
      [this.message = "Private key format is invalid."]);

  @override
  String toString() => message;
}

class InvalidAddressException implements Exception {
  final String message;
  InvalidAddressException([this.message = "Private key format is invalid."]);

  @override
  String toString() => message;
}
