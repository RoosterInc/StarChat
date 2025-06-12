import 'package:get/get.dart';
import '../models/poll.dart';
import '../models/poll_vote.dart';
import '../services/poll_service.dart';

class PollController extends GetxController {
  final PollService service;
  PollController({required this.service});

  final _poll = Rxn<Poll>();
  Poll? get poll => _poll.value;

  final _votes = <PollVote>[].obs;
  List<PollVote> get votes => _votes;

  Future<void> loadVotes(String pollId) async {
    final data = await service.getVotes(pollId);
    _votes.assignAll(data);
  }

  Future<void> vote(PollVote vote) async {
    await service.vote(vote);
    _votes.add(vote);
  }
}
