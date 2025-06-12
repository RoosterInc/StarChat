import 'package:appwrite/appwrite.dart';
import '../models/feed_post.dart';
import '../models/post_comment.dart';
import '../models/post_like.dart';
import '../models/post_repost.dart';

class FeedService {
  final Databases databases;
  final String databaseId;
  final String postsCollectionId;
  final String commentsCollectionId;
  final String likesCollectionId;
  final String repostsCollectionId;

  FeedService({
    required this.databases,
    required this.databaseId,
    required this.postsCollectionId,
    required this.commentsCollectionId,
    required this.likesCollectionId,
    required this.repostsCollectionId,
  });

  Future<List<FeedPost>> getPosts(String roomId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: postsCollectionId,
      queries: [
        Query.equal('room_id', roomId),
        Query.orderDesc('\$createdAt'),
      ],
    );
    return res.documents.map((e) => FeedPost.fromJson(e.data)).toList();
  }

  Future<void> createPost(FeedPost post) async {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: postsCollectionId,
      documentId: ID.unique(),
      data: post.toJson(),
    );
  }

  Future<List<PostComment>> getComments(String postId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: commentsCollectionId,
      queries: [
        Query.equal('post_id', postId),
        Query.orderAsc('\$createdAt'),
      ],
    );
    return res.documents.map((e) => PostComment.fromJson(e.data)).toList();
  }

  Future<void> createComment(PostComment comment) async {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: commentsCollectionId,
      documentId: ID.unique(),
      data: comment.toJson(),
    );
  }

  Future<void> createLike(Map<String, dynamic> like) async {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: likesCollectionId,
      documentId: ID.unique(),
      data: like,
    );
  }

  Future<void> createRepost(Map<String, dynamic> repost) async {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: repostsCollectionId,
      documentId: ID.unique(),
      data: repost,
    );
  }

  Future<PostLike?> getUserLike(String itemId, String userId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: likesCollectionId,
      queries: [
        Query.equal('item_id', itemId),
        Query.equal('user_id', userId),
      ],
    );
    if (res.documents.isEmpty) return null;
    return PostLike.fromJson(res.documents.first.data);
  }

  Future<void> deleteLike(String likeId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: likesCollectionId,
      documentId: likeId,
    );
  }

  Future<PostRepost?> getUserRepost(String postId, String userId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: repostsCollectionId,
      queries: [
        Query.equal('post_id', postId),
        Query.equal('user_id', userId),
      ],
    );
    if (res.documents.isEmpty) return null;
    return PostRepost.fromJson(res.documents.first.data);
  }
}
