class Report {
  final String id;
  final String reporterId;
  final String? reportedPostId;
  final String? reportedUserId;
  final String reportType;
  final String description;
  final String status;

  Report({
    required this.id,
    required this.reporterId,
    this.reportedPostId,
    this.reportedUserId,
    required this.reportType,
    required this.description,
    required this.status,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['\$id'] ?? json['id'],
      reporterId: json['reporter_id'] ?? '',
      reportedPostId: json['reported_post_id'],
      reportedUserId: json['reported_user_id'],
      reportType: json['report_type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
