import 'package:flutter/material.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine/utils/date_time_extension.dart';

class CommentView extends StatelessWidget {
  const CommentView(
    this.comment, {
    super.key,
    this.isSending = false,
    this.getUsernameCallback,
  });

  final Comment comment;
  final bool isSending;
  final String Function(Comment comment)? getUsernameCallback;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Text(
              comment.text,
              style: TextStyle(
                fontSize: 20,
                color: isSending ? Colors.black45 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String? uid = comment.authorUid;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(uid == null || getUsernameCallback == null
            ? ""
            : getUsernameCallback!(comment)),
        Text(isSending ? "Sending" : comment.createdAt.toShortTimestampString())
      ],
    );
  }
}
