/*class NewsData {
  final int code;
  final String? msg;
  final String? traceId;
  final NewsDataContent? data;

  NewsData({
    required this.code,
    this.msg,
    this.traceId,
    this.data,
  });

  factory NewsData.fromJson(Map<String, dynamic> json) {
    return NewsData(
      code: json['code'],
      msg: json['msg'],
      traceId: json['traceId'],
      data:
          json['data'] != null ? NewsDataContent.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'msg': msg,
        'traceId': traceId,
        'data': data?.toJson(),
      };

  NewsData copyWith({
    int? code,
    String? msg,
    String? traceId,
    NewsDataContent? data,
  }) {
    return NewsData(
      code: code ?? this.code,
      msg: msg ?? this.msg,
      traceId: traceId ?? this.traceId,
      data: data ?? this.data,
    );
  }
}

class NewsDataContent {
  final int pageNum;
  final int pageSize;
  final int totalPage;
  final int total;
  final List<Article> list;

  NewsDataContent({
    required this.pageNum,
    required this.pageSize,
    required this.totalPage,
    required this.total,
    required this.list,
  });

  factory NewsDataContent.fromJson(Map<String, dynamic> json) {
    return NewsDataContent(
      pageNum: json['pageNum'],
      pageSize: json['pageSize'],
      totalPage: json['totalPage'],
      total: json['total'],
      list: List<Article>.from(
        (json['list'] ?? []).map((x) => Article.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'pageNum': pageNum,
        'pageSize': pageSize,
        'totalPage': totalPage,
        'total': total,
        'list': list.map((x) => x.toJson()).toList(),
      };

  NewsDataContent copyWith({
    int? pageNum,
    int? pageSize,
    int? totalPage,
    int? total,
    List<Article>? list,
  }) {
    return NewsDataContent(
      pageNum: pageNum ?? this.pageNum,
      pageSize: pageSize ?? this.pageSize,
      totalPage: totalPage ?? this.totalPage,
      total: total ?? this.total,
      list: list ?? this.list,
    );
  }
}

class Article {
  final String id;
  final String sourceLink;
  final int releaseTime;
  final String author;
  final bool? isBlueVerified;
  final String? verifiedType;
  final String? authorDescription;
  final String? authorAvatarUrl;
  final int category;
  final List<Currency> matchedCurrencies;
  final List<String> tags;
  final List<MultilanguageContent> multilanguageContent;
  final String? nickName;
  final dynamic mediaInfo;
  final dynamic quoteInfo;

  Article({
    required this.id,
    required this.sourceLink,
    required this.releaseTime,
    required this.author,
    this.isBlueVerified,
    this.verifiedType,
    this.authorDescription,
    required this.authorAvatarUrl,
    required this.category,
    required this.matchedCurrencies,
    required this.tags,
    required this.multilanguageContent,
    this.nickName,
    this.mediaInfo,
    this.quoteInfo,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      sourceLink: json['sourceLink'],
      releaseTime: json['releaseTime'],
      author: json['author'],
      isBlueVerified: json['isBlueVerified'],
      verifiedType: json['verifiedType'],
      authorDescription: json['authorDescription'],
      authorAvatarUrl: json['authorAvatarUrl'],
      category: json['category'],
      matchedCurrencies: List<Currency>.from(
          (json['matchedCurrencies'] ?? []).map((x) => Currency.fromJson(x))),
      tags: List<String>.from(json['tags'] ?? []),
      multilanguageContent: List<MultilanguageContent>.from(
          (json['multilanguageContent'] ?? [])
              .map((x) => MultilanguageContent.fromJson(x))),
      nickName: json['nickName'],
      mediaInfo: json['mediaInfo'],
      quoteInfo: json['quoteInfo'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceLink': sourceLink,
        'releaseTime': releaseTime,
        'author': author,
        'isBlueVerified': isBlueVerified,
        'verifiedType': verifiedType,
        'authorDescription': authorDescription,
        'authorAvatarUrl': authorAvatarUrl,
        'category': category,
        'matchedCurrencies': matchedCurrencies.map((x) => x.toJson()).toList(),
        'tags': tags,
        'multilanguageContent':
            multilanguageContent.map((x) => x.toJson()).toList(),
        'nickName': nickName,
        'mediaInfo': mediaInfo,
        'quoteInfo': quoteInfo,
      };

  Article copyWith({
    String? id,
    String? sourceLink,
    int? releaseTime,
    String? author,
    bool? isBlueVerified,
    String? verifiedType,
    String? authorDescription,
    String? authorAvatarUrl,
    int? category,
    List<Currency>? matchedCurrencies,
    List<String>? tags,
    List<MultilanguageContent>? multilanguageContent,
    String? nickName,
    dynamic mediaInfo,
    dynamic quoteInfo,
  }) {
    return Article(
      id: id ?? this.id,
      sourceLink: sourceLink ?? this.sourceLink,
      releaseTime: releaseTime ?? this.releaseTime,
      author: author ?? this.author,
      isBlueVerified: isBlueVerified ?? this.isBlueVerified,
      verifiedType: verifiedType ?? this.verifiedType,
      authorDescription: authorDescription ?? this.authorDescription,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      category: category ?? this.category,
      matchedCurrencies: matchedCurrencies ?? this.matchedCurrencies,
      tags: tags ?? this.tags,
      multilanguageContent: multilanguageContent ?? this.multilanguageContent,
      nickName: nickName ?? this.nickName,
      mediaInfo: mediaInfo ?? this.mediaInfo,
      quoteInfo: quoteInfo ?? this.quoteInfo,
    );
  }
}

class Currency {
  final String id;
  final String fullName;
  final String name;

  Currency({
    required this.id,
    required this.fullName,
    required this.name,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'],
      fullName: json['fullName'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'name': name,
      };

  Currency copyWith({
    String? id,
    String? fullName,
    String? name,
  }) {
    return Currency(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      name: name ?? this.name,
    );
  }
}

class MultilanguageContent {
  final String language;
  final String title;
  final String content;

  MultilanguageContent({
    required this.language,
    required this.title,
    required this.content,
  });

  factory MultilanguageContent.fromJson(Map<String, dynamic> json) {
    return MultilanguageContent(
      language: json['language'],
      title: json['title'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'title': title,
        'content': content,
      };

  MultilanguageContent copyWith({
    String? language,
    String? title,
    String? content,
  }) {
    return MultilanguageContent(
      language: language ?? this.language,
      title: title ?? this.title,
      content: content ?? this.content,
    );
  }
}
*/

class NewsData {
  final List<NewsItem> news;
  final int count;

  NewsData({
    required this.news,
    required this.count,
  });

  factory NewsData.fromJson(Map<String, dynamic> json) => NewsData(
        news:
            List<NewsItem>.from(json['news'].map((x) => NewsItem.fromJson(x))),
        count: json['count'],
      );

  Map<String, dynamic> toJson() => {
        'news': news.map((x) => x.toJson()).toList(),
        'count': count,
      };
}

class NewsItem {
  final int id;
  final String title;
  final String description;
  final DateTime pubDate;
  final String author;
  final int categoryId;
  final String twitterPost;
  final int subCategoryId;
  final int upVote;
  final int downVote;
  final int favourites;
  final int viewsCount;
  final String imageUrl;
  final int mediaId;
  final int tokenId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic updatedBy;
  final Category? category;
  final Category? subCategory;
  final Token? token;
  final Media? media;
  final dynamic newsUpdatedByUser;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pubDate,
    required this.author,
    required this.categoryId,
    required this.twitterPost,
    required this.subCategoryId,
    required this.upVote,
    required this.downVote,
    required this.favourites,
    required this.viewsCount,
    required this.imageUrl,
    required this.mediaId,
    required this.tokenId,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
    required this.category,
    required this.subCategory,
    required this.token,
    required this.media,
    this.newsUpdatedByUser,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'] ?? 0,
        title: json['title'],
        description: json['description'],
        pubDate: DateTime.parse(json['pubDate']),
        author: json['author'],
        categoryId: json['categoryId'],
        twitterPost: json['twitterPost'],
        subCategoryId: json['subCategoryId'] ?? 0,
        upVote: json['upVote'] ?? 0,
        downVote: json['downVote'] ?? 0,
        favourites: json['favourites'] ?? 0,
        viewsCount: json['viewsCount'] ?? 0,
        imageUrl: json['imageUrl'],
        mediaId: json['mediaId'] ?? 0,
        tokenId: json['tokenId'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        updatedBy: json['updatedBy'],
        category: json['category'] != null
            ? Category.fromJson(json['category'])
            : null,
        subCategory: json['subCategory'] != null
            ? Category.fromJson(json['subCategory'])
            : null,
        token: json['token'] != null ? Token.fromJson(json['token']) : null,
        media: json['media'] != null ? Media.fromJson(json['media']) : null,
        newsUpdatedByUser: json['newsUpdatedByUser'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'pubDate': pubDate.toIso8601String(),
        'author': author,
        'categoryId': categoryId,
        'twitterPost': twitterPost,
        'subCategoryId': subCategoryId,
        'upVote': upVote,
        'downVote': downVote,
        'favourites': favourites,
        'viewsCount': viewsCount,
        'imageUrl': imageUrl,
        'mediaId': mediaId,
        'tokenId': tokenId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
        'category': category?.toJson(),
        'subCategory': subCategory?.toJson(),
        'token': token?.toJson(),
        'media': media?.toJson(),
        'newsUpdatedByUser': newsUpdatedByUser,
      };
}

class Category {
  final int id;
  final String name;
  final bool isBlockchain;
  final bool isToken;

  Category({
    required this.id,
    required this.name,
    required this.isBlockchain,
    required this.isToken,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        isBlockchain: json['isBlockchain'],
        isToken: json['isToken'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBlockchain': isBlockchain,
        'isToken': isToken,
      };
}

class Token {
  final int id;
  final String name;
  final bool isBlockchain;
  final bool isToken;

  Token({
    required this.id,
    required this.name,
    required this.isBlockchain,
    required this.isToken,
  });

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        id: json['id'],
        name: json['name'],
        isBlockchain: json['isBlockchain'],
        isToken: json['isToken'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isBlockchain': isBlockchain,
        'isToken': isToken,
      };
}

class Media {
  final int id;
  final String filename;
  final String fileDescriptor;

  Media({
    required this.id,
    required this.filename,
    required this.fileDescriptor,
  });

  factory Media.fromJson(Map<String, dynamic> json) => Media(
        id: json['id'],
        filename: json['filename'],
        fileDescriptor: json['fileDescriptor'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'fileDescriptor': fileDescriptor,
      };
}
