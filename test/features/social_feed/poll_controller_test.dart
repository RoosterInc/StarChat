import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/features/social_feed/controllers/poll_controller.dart';
import 'package:myapp/features/social_feed/models/poll_vote.dart';
import 'package:myapp/features/social_feed/services/poll_service.dart';
import 'package:appwrite/appwrite.dart' as aw;

class FakePollService extends PollService {
  FakePollService()
      : super(
          databases: aw.Databases(aw.Client()),
          databaseId: 'db',
          pollsCollectionId: 'polls',
          votesCollectionId: 'votes',
        );

  final List<PollVote> store = [];

  @override
  Future<List<PollVote>> getVotes(String pollId) async {
    return store.where((v) => v.pollId == pollId).toList();
  }
}

void main() {
  test('initial votes empty', () async {
    final controller = PollController(service: FakePollService());
    await controller.loadVotes('1');
    expect(controller.votes, isEmpty);
  });
}
