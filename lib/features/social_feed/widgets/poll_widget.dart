import 'package:flutter/material.dart';
import '../../../design_system/modern_ui_system.dart';
import '../models/poll.dart';

class PollWidget extends StatelessWidget {
  final Poll poll;
  final ValueChanged<int>? onVote;
  const PollWidget({super.key, required this.poll, this.onVote});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: DesignTokens.sm(context).all,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll.question),
          SizedBox(height: DesignTokens.sm(context)),
          ...List.generate(
            poll.options.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.xs(context)),
              child: AnimatedButton(
                onPressed: () => onVote?.call(index),
                child: Text(poll.options[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
