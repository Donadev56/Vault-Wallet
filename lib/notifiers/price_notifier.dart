import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/notifiers/providers.dart';
import 'package:moonwallet/types/types.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


final priceStreamProvider = StreamProvider<TradeData>((ref) async* {
  final url = await ref.watch(cryptoSymbolsStreamUrlProvider.future);
  final channel = WebSocketChannel.connect(Uri.parse(url));

  await for (final message in channel.stream) {
    final data = jsonDecode(message);

    if (data['data'] != null && data['data']['s'] != null && data['data']['p'] != null) {
      final symbol = data['data']['s']; 
      final price = double.tryParse(data['data']['p']) ?? 0.0;

      yield TradeData(binanceSymbol: symbol, price: price);
    }
  }
});

class PriceUpdate {
}
