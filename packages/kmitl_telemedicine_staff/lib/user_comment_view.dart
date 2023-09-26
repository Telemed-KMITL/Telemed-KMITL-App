import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine/visit.dart';
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
  List<String> _comments = [];
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      userVisitProvider(widget.visitRef)
          .select((asyncVal) => asyncVal.value?.data()?.comments),
      (_, comments) => setState(() {
        _comments = comments == null ? [] : List.from(comments);
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

  Widget _buildComment(String text, bool sending) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: sending ? Colors.black54 : null,
            ),
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

  Future<void> _onSendComment() async {
    final comment = _commentInput.text;

    setState(() {
      _commentInput.clear();
      _comments.add(comment);
      _isSending = true;
    });

    try {
      await KmitlTelemedicineDb.addComment(widget.visitRef, comment);
    } on Exception {
      setState(() {
        _commentInput.text = comment;
        _comments.removeLast();
        _isSending = false;
      });
    }

    // Scroll to last item
    _commentListScroll.jumpTo(_commentListScroll.position.minScrollExtent);
  }
}
