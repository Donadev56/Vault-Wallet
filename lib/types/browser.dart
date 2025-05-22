import 'package:moonwallet/types/account_related_types.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final bool isFeatured;
  final List<String> keywords;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.isFeatured = false,
    this.keywords = const [],
  });

  factory Category.fromJson(Map<dynamic, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'isFeatured': isFeatured,
      'keywords': keywords,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    bool? isFeatured,
    List<String>? keywords,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      keywords: keywords ?? this.keywords,
    );
  }
}

class DApp {
  final String name;
  final String imageUrl;
  final String description;
  final String? providerUrl;
  final String websiteUrl;
  final bool isPrimary;
  final bool isNew;
  final bool isTrend;
  final bool isSuspended;
  final List<Crypto> ecosystems;
  final List<Category> categories;

  DApp(
      {required this.name,
      required this.imageUrl,
      required this.description,
      required this.websiteUrl,
      required this.isPrimary,
      required this.isNew,
      required this.isTrend,
      required this.isSuspended,
      required this.ecosystems,
      required this.categories,
      this.providerUrl});

  factory DApp.fromJson(Map<dynamic, dynamic> json) {
    return DApp(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      websiteUrl: json['websiteUrl'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      isNew: json['isNew'] ?? false,
      isTrend: json['isTrend'] ?? false,
      isSuspended: json['isSuspended'] ?? false,
      providerUrl: json["providerUrl"],
      ecosystems: (json['ecosystems'] as List? ?? [])
          .map((e) => Crypto.fromJson(e))
          .toList(),
      categories: (json['categories'] as List? ?? [])
          .map((e) => Category.fromJson(e))
          .toList(),
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'websiteUrl': websiteUrl,
      'isPrimary': isPrimary,
      'isNew': isNew,
      'isTrend': isTrend,
      'isSuspended': isSuspended,
      'ecosystems': ecosystems.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      "providerUrl": providerUrl
    };
  }

  DApp copyWith({
    String? name,
    String? imageUrl,
    String? description,
    String? websiteUrl,
    bool? isPrimary,
    bool? isNew,
    bool? isTrend,
    bool? isSuspended,
    List<Crypto>? ecosystems,
    String? providerUrl,
    List<Category>? categories,
  }) {
    return DApp(
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        description: description ?? this.description,
        websiteUrl: websiteUrl ?? this.websiteUrl,
        isPrimary: isPrimary ?? this.isPrimary,
        isNew: isNew ?? this.isNew,
        isTrend: isTrend ?? this.isTrend,
        isSuspended: isSuspended ?? this.isSuspended,
        ecosystems: ecosystems ?? this.ecosystems,
        providerUrl: providerUrl ?? this.providerUrl,
        categories: categories ?? this.categories);
  }
}
