import 'package:appwrite/appwrite.dart';
import '../models/poll.dart';
import '../models/poll_vote.dart';

class PollService {
  final Databases databases;
  final String databaseId;
  final String pollsCollectionId;
  final String votesCollectionId;

  PollService({
    required this.databases,
    required this.databaseId,
    required this.pollsCollectionId,
    required this.votesCollectionId,
  });

  Future<Poll> createPoll(Poll poll) async {
    final res = await databases.createDocument(
      databaseId: databaseId,
      collectionId: pollsCollectionId,
      documentId: ID.unique(),
      data: poll.toJson(),
    );
    return Poll.fromJson(res.data);
  }

  Future<void> vote(PollVote vote) async {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: votesCollectionId,
      documentId: ID.unique(),
      data: vote.toJson(),
    );
  }

  Future<List<PollVote>> getVotes(String pollId) async {
    final res = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: votesCollectionId,
      queries: [Query.equal('poll_id', pollId)],
    );
    return res.documents.map((e) => PollVote.fromJson(e.data)).toList();
  }
}
