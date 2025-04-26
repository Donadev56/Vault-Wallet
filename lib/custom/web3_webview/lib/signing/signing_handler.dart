// lib/ethereum/signing/signing_handler.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../../../../logger/logger.dart';
import '../json_rpc_method.dart';
import '../utils/hex_utils.dart';
import '../exceptions.dart';
import 'package:eth_sig_util/eth_sig_util.dart';

class SigningHandler {
  final Credentials _credentials;
  final String _key;

  SigningHandler(this._credentials, this._key);

  Future<String> signMessage(
      String method, String from, dynamic message, String password) async {
    try {
      // Validate signer
      await _validateSigner(from);

      switch (JsonRpcMethod.fromString(method)) {
        case JsonRpcMethod.PERSONAL_SIGN:
          return await _personalSign(message);
        case JsonRpcMethod.ETH_SIGN:
          return await _ethSign(message);

        case JsonRpcMethod.ETH_SIGN_TYPED_DATA:
          return await _signTypedData(message[0]);
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V1:
          return await _signTypedDataV1(message);
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V3:
          return await _signTypedDataV3(jsonDecode(message));
        case JsonRpcMethod.ETH_SIGN_TYPED_DATA_V4:
          return await _signTypedDataV4(jsonDecode(message));
        default:
          throw WalletException('Unsupported signing method: $method');
      }
    } catch (e) {
      throw WalletException('Signing failed: $e');
    }
  }

  Future<void> _validateSigner(String address) async {
    final credentialsAddress = _credentials.address;
    if (credentialsAddress.hex.toLowerCase() != address.toLowerCase()) {
      throw WalletException('Signer address does not match current account');
    }
  }

  // do not edit

  /* Future<String> _personalSign(dynamic message) async {
    try {
      Uint8List messageBytes;

      if (message is! String) {
        throw WalletException('Message must be a string');
      }

      if (message.startsWith('0x')) {
        // Nếu là hex string, decode trực tiếp thành bytes
        messageBytes = HexUtils.hexToBytes(message);
        // Thêm prefix sau khi decode hex
        final prefix = '\x19Ethereum Signed Message:\n${messageBytes.length}';
        messageBytes =
            Uint8List.fromList([...utf8.encode(prefix), ...messageBytes]);
      } else {
        // Nếu là plain text
        final utf8Bytes = utf8.encode(message);
        // final prefix = '\x19Ethereum Signed Message:\n${utf8Bytes.length}';
        const prefix = ''; // Không cần prefix cho plain text
        messageBytes =
            Uint8List.fromList([...utf8.encode(prefix), ...utf8Bytes]);
      }

      final signature =
          _credentials.signPersonalMessageToUint8List(messageBytes);
      return HexUtils.bytesToHex(signature, include0x: true);
    } catch (e) {
      throw WalletException('Personal sign failed: $e');
    }
  } */

  Future<String> _personalSign(dynamic message) async {
    try {
      log("Message to sign : $message");

      final bytes = (message is String && message.startsWith('0x'))
          ? hexToBytes(message)
          : utf8.encode(message.toString());

      final result = EthSigUtil.signPersonalMessage(
        privateKey: _key,
        message: bytes,
      );

      if (result.isEmpty) {
        throw WalletException("An error has occurred");
      }

      log("result $result");
      return result;
    } catch (e) {
      logError(e.toString());
      throw WalletException('Personal sign failed: $e');
    }
  }

  Future<String> _ethSign(dynamic message) async {
    try {
      log("Message to sign : ${message}");

      final bytes = (message is String && message.startsWith('0x'))
          ? hexToBytes(message)
          : utf8.encode(message.toString());

      return EthSigUtil.signMessage(privateKey: _key, message: bytes);
    } catch (e) {
      throw WalletException('Personal sign failed: $e');
    }
  }

  Future<String> _signTypedData(dynamic message) async {
    try {
      if (message is! Map<String, dynamic>) {
        throw WalletException('Invalid typed data format');
      }
      log("Message ${message}");

      final result = EthSigUtil.signTypedData(
        privateKey: _key,
        jsonData: jsonEncode(message),
        version: TypedDataVersion.V1,
      );
      log(result);

      return result;
    } catch (e) {
      log(e.toString());
      throw WalletException('Typed data sign failed: $e');
    }
  }

  Future<String> _signTypedDataV1(dynamic message) async {
    try {
      log("Message : $message");
      String? signature;
      try {
        signature = EthSigUtil.signTypedData(
            privateKey: _key,
            jsonData: message == String ? message : json.encode(message),
            version: TypedDataVersion.V1);
      } catch (e) {
        logError(e.toString());
      }
      log("Signature : $signature");
      if (signature != null) {
        return signature;
      } else {
        throw WalletException('Typed data v4 sign failed: Signature is null');
      }
    } catch (e) {
      logError(e.toString());
      throw WalletException('Typed data v4 sign failed: $e');
    }
  }

  Future<String> _signTypedDataV3(dynamic message) async {
    try {
      log("Message : $message");
      String? signature;
      try {
        signature = EthSigUtil.signTypedData(
            privateKey: _key,
            jsonData: message == String ? message : json.encode(message),
            version: TypedDataVersion.V3);
      } catch (e) {
        logError(e.toString());
      }
      log("Signature : $signature");
      if (signature != null) {
        return signature;
      } else {
        throw WalletException('Typed data v4 sign failed: Signature is null');
      }
    } catch (e) {
      logError(e.toString());
      throw WalletException('Typed data v4 sign failed: $e');
    }
  }

  Future<String> _signTypedDataV4(dynamic message) async {
    try {
      log("Message : $message");
      String? signature;
      try {
        signature = EthSigUtil.signTypedData(
            privateKey: _key,
            jsonData: message == String ? message : json.encode(message),
            version: TypedDataVersion.V4);
      } catch (e) {
        logError(e.toString());
      }
      log("Signature : $signature");
      if (signature != null) {
        return signature;
      } else {
        throw WalletException('Typed data v4 sign failed: Signature is null');
      }
    } catch (e) {
      logError(e.toString());
      throw WalletException('Typed data v4 sign failed: $e');
    }
  }

  /// Khôi phục địa chỉ Ethereum từ chữ ký được tạo bởi personal_sign
  String personalEcRecover(String message, String signature) {
    try {
      // Chuẩn bị message
      Uint8List messageBytes;
      if (message.startsWith('0x')) {
        messageBytes = hexToBytes(message.substring(2));
      } else {
        messageBytes = Uint8List.fromList(utf8.encode(message));
      }

      final prefix = '\x19Ethereum Signed Message:\n${messageBytes.length}';
      final prefixBytes = Uint8List.fromList(utf8.encode(prefix));

      // Kết hợp prefix và message
      final prefixedMessage =
          Uint8List(prefixBytes.length + messageBytes.length);
      prefixedMessage.setAll(0, prefixBytes);
      prefixedMessage.setAll(prefixBytes.length, messageBytes);

      // Hash message đã được prefix
      final Uint8List hash = keccak256(prefixedMessage);

      // Xử lý signature
      String sigHex = signature;
      if (sigHex.startsWith('0x')) {
        sigHex = sigHex.substring(2);
      }

      // Đảm bảo signature có độ dài đúng
      if (sigHex.length != 130) {
        throw Exception(
            'Invalid signature length: ${sigHex.length} chars, expected 130');
      }

      // Tách r, s, v từ signature
      final r = BigInt.parse(sigHex.substring(0, 64), radix: 16);
      final s = BigInt.parse(sigHex.substring(64, 128), radix: 16);

      // Lấy v từ byte cuối cùng và điều chỉnh nếu cần
      int v = int.parse(sigHex.substring(128, 130), radix: 16);
      if (v < 27) {
        v += 27;
      }

      // Tạo MsgSignature
      final msgSignature = MsgSignature(r, s, v);

      // Khôi phục public key
      final Uint8List publicKey = ecRecover(hash, msgSignature);

      // Chuyển public key thành địa chỉ
      final EthereumAddress address = EthereumAddress.fromPublicKey(publicKey);
      return address.hexEip55;
    } catch (e) {
      throw Exception('Failed to recover address: $e');
    }
  }

  /// Lấy encryption public key từ private key sử dụng web3dart
  String getEncryptionPublicKey(String privateKeyHex) {
    try {
      // 1. Parse private key
      final privateKey = EthPrivateKey.fromHex(privateKeyHex.startsWith('0x')
          ? privateKeyHex.substring(2)
          : privateKeyHex);

      // 2. Lấy public key dạng compressed
      final publicKeyPoints = privateKey.encodedPublicKey;

      // 3. Convert sang compressed format (33 bytes)
      // Prefix (0x02 nếu y chẵn, 0x03 nếu y lẻ) + x coordinates
      final compressedPubKey = Uint8List(33);
      compressedPubKey[0] = publicKeyPoints[64] & 1 == 0 ? 0x02 : 0x03;
      compressedPubKey.setRange(1, 33, publicKeyPoints.sublist(1, 33));

      // 4. Convert sang hex và thêm prefix 0x
      return '0x${HEX.encode(compressedPubKey)}';
    } catch (e) {
      throw Exception('Failed to get encryption public key: $e');
    }
  }

  Uint8List _encodeData(
      String type, dynamic value, Map<String, dynamic> types) {
    // Handle array types
    if (type.endsWith('[]')) {
      if (value is! List) {
        throw WalletException('Expected array value for type $type');
      }

      final baseType = type.substring(0, type.length - 2);
      final elements =
          value.map((item) => _encodeData(baseType, item, types)).toList();
      return keccak256(Buffer.concat(elements));
    }

    // Handle fixed-size array types
    final arrayMatch = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(type);
    if (arrayMatch != null) {
      if (value is! List) {
        throw WalletException('Expected array value for type $type');
      }

      final baseType = arrayMatch.group(1)!;
      final size = int.parse(arrayMatch.group(2)!);

      if (value.length != size) {
        throw WalletException(
            'Array length mismatch. Expected: $size, got: ${value.length}');
      }

      final elements =
          value.map((item) => _encodeData(baseType, item, types)).toList();
      return keccak256(Buffer.concat(elements));
    }

    // Handle struct types
    if (types.containsKey(type)) {
      if (value is! Map<String, dynamic>) {
        throw WalletException('Expected object value for type $type');
      }
      return _encodeStruct(type, value, types);
    }

    // Handle atomic types
    if (type == 'string' || type == 'bytes') {
      return keccak256(Uint8List.fromList(utf8.encode(value.toString())));
    }

    if (type == 'bool') {
      return Uint8List.fromList([value ? 1 : 0]);
    }

    if (type.startsWith('uint') || type.startsWith('int')) {
      final bigInt = BigInt.parse(value.toString());
      return encodeBigInt(bigInt);
    }

    if (type == 'address') {
      // Remove '0x' prefix if present and ensure proper length
      String hexAddress = value.toString().toLowerCase();
      if (hexAddress.startsWith('0x')) {
        hexAddress = hexAddress.substring(2);
      }
      if (hexAddress.length != 40) {
        throw WalletException('Invalid address length');
      }
      return HexUtils.hexToBytes('0x$hexAddress');
    }

    if (type.startsWith('bytes')) {
      if (type == 'bytes') {
        // Dynamic bytes
        final bytes = HexUtils.hexToBytes(value.toString());
        return keccak256(bytes);
      } else {
        // Fixed bytes
        final size = int.parse(type.substring(5));
        final bytes = HexUtils.hexToBytes(value.toString());
        if (bytes.length != size) {
          throw WalletException('Invalid bytes length for $type');
        }
        return bytes;
      }
    }

    throw WalletException('Unsupported type: $type');
  }

  Uint8List _encodeStruct(
      String type, Map<String, dynamic> value, Map<String, dynamic> types) {
    final fields = types[type] as List;
    final List<Uint8List> encodedValues = [];

    for (final field in fields) {
      final name = field['name'] as String;
      final fieldType = field['type'] as String;
      encodedValues.add(_encodeData(fieldType, value[name], types));
    }

    return keccak256(Buffer.concat(encodedValues));
  }
}

// Helper class for encoding typed data
class TypedDataEncoder {
  static Uint8List encodeBasic(Map<String, dynamic> data) {
    // Basic implementation for legacy typed data
    final encoded = jsonEncode(data);
    return keccak256(Uint8List.fromList(utf8.encode(encoded)));
  }

  static Uint8List encodeV1(List data) {
    // Implementation for v1 encoding
    final encoded = jsonEncode(data);
    return keccak256(Uint8List.fromList(utf8.encode(encoded)));
  }
}

// TypedData class for handling EIP-712 structured data
class TypedData {
  final Map<String, dynamic> types;
  final String primaryType;
  final Map<String, dynamic> domain;
  final Map<String, dynamic> message;

  TypedData({
    required this.types,
    required this.primaryType,
    required this.domain,
    required this.message,
  });

  factory TypedData.fromJson(Map<String, dynamic> json) {
    return TypedData(
      types: json['types'] as Map<String, dynamic>,
      primaryType: json['primaryType'] as String,
      domain: json['domain'] as Map<String, dynamic>,
      message: json['message'] as Map<String, dynamic>,
    );
  }
}

class Buffer {
  static Uint8List concat(List<Uint8List> lists) {
    int length = 0;
    for (final list in lists) {
      length += list.length;
    }

    final result = Uint8List(length);
    int offset = 0;

    for (final list in lists) {
      result.setAll(offset, list);
      offset += list.length;
    }

    return result;
  }
}

Uint8List encodeBigInt(BigInt number) {
  if (number == BigInt.zero) {
    return Uint8List.fromList([0]);
  }

  // Convert to bytes removing leading zeros
  var result = number.toUint8List();

  // Ensure the size is 32 bytes for EIP-712
  if (result.length < 32) {
    var padded = Uint8List(32);
    padded.setAll(32 - result.length, result);
    result = padded;
  }

  return result;
}

// Extension method để convert BigInt sang Uint8List
extension BigIntExtension on BigInt {
  Uint8List toUint8List() {
    var hexString = toRadixString(16);
    if (hexString.length % 2 != 0) {
      hexString = '0$hexString';
    }

    var result = Uint8List(hexString.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      var hex = hexString.substring(i * 2, (i * 2) + 2);
      result[i] = int.parse(hex, radix: 16);
    }

    return result;
  }
}
