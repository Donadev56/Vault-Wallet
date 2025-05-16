import 'package:moonwallet/types/account_related_types.dart';

final Map<NetworkType, TokenEcosystem> ecosystemInfo = {
  NetworkType.evm: TokenEcosystem(
      supportSmartContracts: true,
      name: 'Ethereum',
      type: NetworkType.evm,
      iconUrl: "https://static.moonbnb.app/images/eth.png"),
  NetworkType.svm: TokenEcosystem(
      supportSmartContracts: true,
      name: "Solana",
      type: NetworkType.svm,
      iconUrl: "https://static.moonbnb.app/images/sol.png"),
};
