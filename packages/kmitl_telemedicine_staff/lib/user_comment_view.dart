import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine/utils/date_time_extension.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';

class UserCommentView extends ConsumerStatefulWidget {
  const UserCommentView(this.visitRef, {super.key, this.width = 400});

  final DocumentReference<Visit> visitRef;
  final double width;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserCommentViewState();
}

class _UserCommentViewState extends ConsumerState<UserCommentView> {
  final TextEditingController _commentInput = TextEditingController();
  final ScrollController _commentListScroll = ScrollController();
  final Map<String, String> _usernameCache = {};

  List<Comment> _comments = [];
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      userCommentProvider(widget.visitRef),
      (_, snapshot) => setState(() {
        final comments = snapshot.valueOrNull;
        if (comments != null) {
          _comments = comments.docs.map((snapshot) => snapshot.data()).toList();
          fetchUsernames();
        }
        _isSending = false;
      }),
    );

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: SingleChildScrollView(
              controller: _commentListScroll,
              reverse: true,
              scrollDirection: Axis.vertical,
              child: _buildCommentList(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: Iterable<int>.generate(_comments.length).map((idx) {
          final comment = _comments[idx];
          return _buildComment(
            comment,
            _isSending && idx == _comments.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return AppBar(
      automaticallyImplyLeading: false,
      primary: false,
      title: const Text("Comments"),
    );
  }

  Widget _buildCommentHeader(Comment comment, bool sending) {
    String? uid = comment.authorUid;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(uid == null ? "" : _usernameCache[uid]!),
        Text(sending ? "Sending" : comment.createdAt.toShortTimestampString())
      ],
    );
  }

  Widget _buildComment(Comment comment, bool sending) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCommentHeader(comment, sending),
              Text(
                comment.text,
                style: TextStyle(
                  fontSize: 20,
                  color: sending ? Colors.black45 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            flex: 1,
            child: TextField(
              controller: _commentInput,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Comment",
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.all(4),
            child: ValueListenableBuilder(
              valueListenable: _commentInput,
              builder: (context, state, _) => IconButton(
                onPressed:
                    _isSending || state.text.isNotEmpty ? _onSendComment : null,
                color: theme.primaryColor,
                icon: const Icon(Icons.send),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchUsernames() async {
    for (final comment in _comments) {
      String? uid = comment.authorUid;

      if (uid != null && !_usernameCache.containsKey(uid)) {
        _usernameCache[uid] = "";

        () async {
          final snapshot = await KmitlTelemedicineDb.getUserRef(uid).get();
          final user = snapshot.exists ? snapshot.data() : null;

          setState(() {
            _usernameCache[uid] =
                user == null ? "[Deleted User]" : user.getDisplayName();
          });
        }();
      }
    }
  }

  Future<void> _onSendComment() async {
    String uid = ref.read(firebaseAuthStateProvider).requireValue!.uid;

    final commentText = _commentInput.text.trim();
    _commentInput.clear();

    if (commentText.isEmpty) {
      return;
    }

    setState(() {
      _comments.add(Comment(
          text: commentText, authorUid: uid, createdAt: DateTime.now()));
      _isSending = true;
    });

    try {
      await KmitlTelemedicineDb.addComment(
        widget.visitRef,
        commentText,
        uid,
      );
    } on Exception {
      setState(() {
        _commentInput.text = commentText;
        _comments.removeLast();
        _isSending = false;
      });
    }

    // Scroll to last item
    _commentListScroll.jumpTo(_commentListScroll.position.minScrollExtent);
  }
}
