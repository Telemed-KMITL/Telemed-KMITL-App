import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FormDialog extends ConsumerStatefulWidget {
  const FormDialog({
    required this.title,
    required this.content,
    required this.onSubmit,
    this.submitButtonText = "Submit",
    super.key,
  });

  final Widget title;
  final Widget content;
  final FutureOr<String?> Function() onSubmit;
  final String submitButtonText;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateUserRecordDialogState();
}

class _CreateUserRecordDialogState extends ConsumerState<FormDialog> {
  static const double kActionWidgetHeight = 40;

  final _formKey = GlobalKey<FormState>();

  final StateProvider<bool> _isSubmittingProvider =
      StateProvider((ref) => false);
  final StateProvider<String> _submitErrorTextProvider =
      StateProvider((ref) => "");

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(_isSubmittingProvider);
    final submitErrorText = ref.watch(_submitErrorTextProvider);
    return AlertDialog(
      title: widget.title,
      contentPadding: const EdgeInsets.only(top: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: widget.content,
                ),
              ),
            ),
          ),
          if (submitErrorText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              color: Theme.of(context).colorScheme.errorContainer,
              alignment: Alignment.center,
              child: Text(
                submitErrorText,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => context.pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isSubmitting
              ? null
              : () async {
                  if (await _submit() && context.mounted) {
                    context.pop(true);
                  }
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.submitButtonText),
              if (ref.watch(_isSubmittingProvider)) ...const [
                SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ].map((w) => SizedBox(height: kActionWidgetHeight, child: w)).toList(),
    );
  }

  Future<bool> _submit() async {
    final form = _formKey.currentState!;

    if (!form.validate()) {
      return false;
    }
    form.save();

    ref.read(_isSubmittingProvider.notifier).state = true;
    ref.read(_submitErrorTextProvider.notifier).state = "";

    try {
      final errorMessage = await widget.onSubmit();
      if (errorMessage != null) {
        ref.read(_submitErrorTextProvider.notifier).state = errorMessage;
        return false;
      }
    } on Exception {
      ref.read(_submitErrorTextProvider.notifier).state = "Unknown error";
      return false;
    } finally {
      ref.read(_isSubmittingProvider.notifier).state = false;
    }

    return true;
  }
}
