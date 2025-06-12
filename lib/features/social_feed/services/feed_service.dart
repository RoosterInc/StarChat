import 'package:appwrite/appwrite.dart';
import '../models/feed_post.dart';
import '../models/post_comment.dart';

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
}
