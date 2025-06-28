import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:gloryfit_version_3/models/comment_model.dart';

class PostModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String content;
  final List<String> imageUrls;
  final DateTime createdAt;
  final List<String> likes;
  final List<CommentModel> comments;
  final bool isQuestion;
  final String? location;
  final List<String> tags;

  const PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    this.likes = const [],
    required this.comments,
    this.isQuestion = false,
    this.location,
    this.tags = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userImage: json['userImage'] as String,
      content: json['content'] as String,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isQuestion: json['isQuestion'] as bool? ?? false,
      location: json['location'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'comments': comments.map((e) => e.toJson()).toList(),
      'isQuestion': isQuestion,
      'location': location,
      'tags': tags,
    };
  }

  PostModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userImage,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    List<String>? likes,
    List<CommentModel>? comments,
    bool? isQuestion,
    String? location,
    List<String>? tags,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isQuestion: isQuestion ?? this.isQuestion,
      location: location ?? this.location,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userImage,
        content,
        imageUrls,
        createdAt,
        likes,
        comments,
        isQuestion,
        location,
        tags,
      ];
} 