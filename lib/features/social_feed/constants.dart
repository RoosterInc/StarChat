const int maxHashtags = 10;

List<String> limitHashtags(List<String> tags) =>
    tags.take(maxHashtags).toList();

