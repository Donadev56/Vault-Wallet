import 'package:moonwallet/types/account_related_types.dart';

final Map<NetworkType, TokenEcosystem> ecosystemInfo = {
  NetworkType.evm: TokenEcosystem(
      supportSmartContracts: true,
      name: 'Ethereum',
      type: NetworkType.evm,
      iconUrl:
          "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2/logo.png"),
  NetworkType.svm: TokenEcosystem(
      supportSmartContracts: true,
      name: "Solana",
      type: NetworkType.svm,
      iconUrl:
          "https://raw.githubusercontent.com/trustwallet/assets/refs/heads/master/blockchains/solana/info/logo.png"),
};
