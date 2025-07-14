import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/crypto_manager.dart';
import 'package:moonwallet/service/db/dynamic_bd.dart';
import 'package:moonwallet/types/account_related_types.dart';
import 'package:moonwallet/utils/app_utils.dart';

class NodesNotifier extends AsyncNotifier<Nodes> {
  @override
  Future<Nodes> build() => init();
  final String _key = "available-web3-nodes";

  Future<Nodes> init() async {
    try {
      final savedNodes = await getSavedNodes();
      if (savedNodes != null) {
        updateState();
        return savedNodes;
      }
      return await getAvailableNodes();
    } catch (e) {
      logError(e.toString());
      return Nodes.fromJson({"nodes": []});
    }
  }

  Future<void> updateState() async {
    try {
      log("Updating Nodes State");
      final nodes = await getAvailableNodes();
      state = AsyncData(nodes);
      log("Nodes State Updated");
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<Nodes> getAvailableNodes() async {
    try {
      List<Crypto> tokens = [];
      try {
        tokens = await CryptoManager().getDefaultTokens();
      } catch (e) {
        logError(e.toString());
      }
      if (tokens.isEmpty) {
        final savedData = await getSavedNodes();
        if (savedData != null) {
          return savedData;
        }
        throw "No data found";
      }

      final networks = tokens.onlyNative;

      final availableNodes =
          await Future.wait(networks.map((e) => findAvailableNode(e)));

      if (availableNodes.isNotEmpty) {
        final nodes = Nodes(nodes: availableNodes);
        await saveNodes(nodes);
        return nodes;
      }
      final savedNodes = await getSavedNodes();
      if (savedNodes != null) {
        return savedNodes;
      }
      throw "No data found";
    } catch (e) {
      logError(e.toString());
      return Nodes.fromJson({"nodes": []});
    }
  }

  Future<Node> findAvailableNode(Crypto token) async {
    try {
      if (token.networkType == NetworkType.svm) {
        // this method is not supported by non-evm chains
        return Node(
            rpcUrl: token.rpcUrls?.firstOrNull ?? '',
            chainId: token.chainId ?? 0,
            chainType: NetworkType.svm);
      }
      String nodeUrl = '';
      nodeUrl = await getAvailableEthRpc(token.rpcUrls ?? []);
      if (nodeUrl.isEmpty) {
        nodeUrl = token.rpcUrls?.firstOrNull ?? '';
      }
      return Node(
          rpcUrl: nodeUrl,
          chainId: token.chainId ?? 1,
          chainType: token.networkType ?? NetworkType.evm);
    } catch (e) {
      logError(e.toString());
      return Node(
          rpcUrl: token.rpcUrls?.firstOrNull ?? '',
          chainId: token.chainId ?? 1,
          chainType: token.networkType ?? NetworkType.evm);
    }
  }

  Future<bool> saveNodes(Nodes nodes) async {
    try {
      final db = DynamicDatabase(path: _key);
      return await db.saveData(json.encode(nodes.toJson()));
    } catch (e) {
      logError(e.toString());
      return false;
    }
  }

  Future<Nodes?> getSavedNodes() async {
    try {
      final db = DynamicDatabase(path: _key);
      final data = await db.getData();
      if (data == null) {
        throw "No data saved";
      }
      return Nodes.fromJson(json.decode(data));
    } catch (e) {
      logError(e.toString());
      return null;
    }
  }
}
