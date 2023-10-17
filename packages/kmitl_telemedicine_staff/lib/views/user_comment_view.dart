import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine_staff/views/comment_view.dart';
import 'package:kmitl_telemedicine_staff/providers.dart';

class UserCommentView extends ConsumerStatefulWidget {
  const UserCommentView(
    this.userRef, {
    super.key,
    this.visitId,
    this.showPreviousVisitComments = true,
    this.width = 400,
  });

  final DocumentReference<User> userRef;
  final String? visitId;
  final bool showPreviousVisitComments;
  final double width;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserCommentViewState();
}

class _PagingControllerKey {
  _PagingControllerKey({
    required this.baseQuery,
    required this.currentQuery,
    required this.expectedCount,
  });

  _PagingControllerKey getNextKey(Query<Comment> query, int limit) =>
      _PagingControllerKey(
        baseQuery: baseQuery,
        currentQuery: query.limit(limit),
        expectedCount: limit,
      );

  Query<Comment> baseQuery;
  Query<Comment> currentQuery;
  int expectedCount;
}

class _UserCommentViewState extends ConsumerState<UserCommentView> {
  final TextEditingController _commentInput = TextEditingController();
  final ScrollController _commentListScroll = ScrollController();

  // Visit

  DocumentReference<Visit>? get visitRef => widget.visitId == null
      ? null
      : KmitlTelemedicineDb.getVisitRef(widget.userRef, widget.visitId!);

  // Usernames

  /// UserID -> Username(Displayname) dictionary
  ///
  /// To update this cache, use [_fetchUsernames] method.
  final Map<String, String> _usernameCache = {};

  // Comments

  PagingController<_PagingControllerKey, DocumentSnapshot<Comment>>?
      _commentHistoryController;

  List<DocumentSnapshot<Comment>> _currentComments = [];
  Comment? _sendingComment;
  bool get hasCommentInput => widget.visitId != null;

  @override
  void initState() {
    if (!hasCommentInput) {
      _initCommentHistory(oldestSnapshot: _currentComments.firstOrNull);
    }
    super.initState();
  }

  // UI

  @override
  Widget build(BuildContext context) {
    if (hasCommentInput) {
      ref.listen(userCommentProvider(visitRef!), _currentCommentListener);
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: CustomScrollView(
              controller: _commentListScroll,
              reverse: true,
              scrollDirection: Axis.vertical,
              slivers: [
                _buildCurrentCommentSliver(),
                if (_commentHistoryController != null)
                  _buildCommentHistorySliver(),
              ],
            ),
          ),
          if (hasCommentInput) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCurrentCommentSliver() {
    return SliverList.list(children: [
      if (_sendingComment != null)
        CommentView(
          _sendingComment!,
          isSending: true,
          getUsernameCallback: _getUsername,
        ),
      ..._currentComments.map(
        (comment) => CommentView(
          comment.data()!,
          getUsernameCallback: _getUsername,
        ),
      ),
      if (_currentComments.isNotEmpty) _buildVisitHeader(visitRef!.id, false),
    ]);
  }

  Widget _buildCommentHistorySliver() {
    return PagedSliverList<_PagingControllerKey, DocumentSnapshot<Comment>>(
      pagingController: _commentHistoryController!,
      builderDelegate: PagedChildBuilderDelegate<DocumentSnapshot<Comment>>(
        itemBuilder: (context, snapshot, index) {
          final comment = snapshot.data()!;
          final itemList = _commentHistoryController!.itemList!;
          final nextComment = itemList.elementAtOrNull(index + 1)?.data()!;

          final commentView = CommentView(
            comment,
            getUsernameCallback: _getUsername,
          );

          return comment.visitId != null &&
                  comment.visitId != nextComment?.visitId
              ? Column(
                  children: [
                    _buildVisitHeader(comment.visitId!, true),
                    commentView,
                  ],
                )
              : commentView;
        },
        noItemsFoundIndicatorBuilder: (context) => const SizedBox(),
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
                onPressed: _sendingComment == null && state.text.isNotEmpty
                    ? _sendComment
                    : null,
                color: theme.primaryColor,
                icon: const Icon(Icons.send),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitHeader(String visitId, bool isHistory) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.grey.shade300,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            visitId,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
          if (isHistory) const Icon(Icons.history),
        ],
      ),
    );
  }

  // Username

  void _fetchUsernames(Iterable<Comment> newComments) {
    for (final comment in newComments) {
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

  String _getUsername(Comment comment) {
    return comment.authorUid == null
        ? ""
        : _usernameCache[comment.authorUid!] ?? "";
  }

  // Comment

  Future<void> _sendComment() async {
    String uid = ref.read(firebaseUserProvider).requireValue!.uid;

    final commentText = _commentInput.text.trim();
    _commentInput.clear();

    if (commentText.isEmpty) {
      return;
    }

    setState(() {
      _sendingComment = Comment(
        text: commentText,
        authorUid: uid,
        createdAt: DateTime.now(),
      );
    });

    try {
      await KmitlTelemedicineDb.addComment(
        visitRef!,
        commentText,
        uid,
      );
    } on Exception {
      setState(() {
        _commentInput.text = commentText;
        _sendingComment = null;
      });
    }

    // Scroll to last item
    //_commentListScroll.jumpTo(_commentListScroll.position.minScrollExtent);
  }

  void _currentCommentListener(
          _, AsyncValue<QuerySnapshot<Comment>> snapshot) =>
      setState(() {
        _sendingComment = null;

        final comments = snapshot.valueOrNull;
        if (comments == null) {
          return;
        }

        _currentComments = comments.docs;
        _fetchUsernames(
            _currentComments.map((s) => s.data()).whereType<Comment>());

        _initCommentHistory(oldestSnapshot: _currentComments.lastOrNull);
      });

  void _initCommentHistory({DocumentSnapshot<Comment>? oldestSnapshot}) {
    if (_commentHistoryController != null ||
        !widget.showPreviousVisitComments) {
      return;
    }

    var baseQuery = KmitlTelemedicineDb.getAllComments(widget.userRef);

    late _PagingControllerKey firstKey;
    if (widget.visitId == null) {
      firstKey = _PagingControllerKey(
        baseQuery: baseQuery,
        currentQuery: baseQuery.limit(20),
        expectedCount: 20,
      );
    } else if (oldestSnapshot == null) {
      firstKey = _PagingControllerKey(
        baseQuery: baseQuery,
        currentQuery: baseQuery.limit(20),
        expectedCount: 20,
      );
    } else {
      firstKey = _PagingControllerKey(
        baseQuery: baseQuery,
        currentQuery: baseQuery.startAfterDocument(oldestSnapshot).limit(10),
        expectedCount: 10,
      );
    }

    _commentHistoryController = PagingController(
      firstPageKey: firstKey,
      invisibleItemsThreshold: 1,
    )..addPageRequestListener(_appendCommentHistory);
  }

  Future<void> _appendCommentHistory(_PagingControllerKey key) async {
    var snapshot = await key.currentQuery.get();

    _fetchUsernames(snapshot.docs.map((s) => s.data()).whereType<Comment>());

    if (snapshot.size == key.expectedCount) {
      _commentHistoryController!.appendPage(
          snapshot.docs,
          key.getNextKey(
            key.baseQuery.startAfterDocument(snapshot.docs.last),
            20,
          ));
    } else {
      _commentHistoryController!.appendLastPage(snapshot.docs);
    }
  }
}
