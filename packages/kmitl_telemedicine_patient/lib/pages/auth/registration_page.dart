import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:go_router/go_router.dart";
import "package:kmitl_telemedicine/kmitl_telemedicine.dart";
import "package:kmitl_telemedicine_patient/providers.dart";
import "package:kmitl_telemedicine_server/kmitl_telemedicine_server.dart"
    show UserRegisterMyselfRequest;

class RegistrationPage extends ConsumerStatefulWidget {
  const RegistrationPage({
    super.key,
    this.hasPreviousPage = false,
  });

  final bool hasPreviousPage;

  static const String route = "register";
  static const String path = "/auth/register";

  static Future<bool> needsToShow(WidgetRef ref) async {
    final user = await ref.read(currentUserProvider.future);
    return !(user?.exists ?? false);
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  User? _user;

  final StateProvider<bool> _isSendingProvider = StateProvider((_) => false);
  late final Provider<bool> _canSubmitProvider;

  @override
  void initState() {
    super.initState();
    _canSubmitProvider = Provider((ref) =>
        !ref.watch(_isSendingProvider) &&
        (_formKey.currentState?.isDirty ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade900,
        elevation: 0,
        leadingWidth: 120,
        leading: widget.hasPreviousPage
            ? Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go("/auth?signout=true"),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: "Sign out",
                ),
              )
            : TextButton.icon(
                onPressed: () => context.go("/auth?signout=true"),
                icon: const Icon(Icons.logout),
                label: const Text("Sign out"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade900,
                ),
              ),
      ),
      body: user.when(
        skipError: true,
        data: (snapshot) {
          _user ??=
              snapshot != null && snapshot.exists ? snapshot.data() : null;
          return _buildForm();
        },
        error: (_, __) => Container(),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: _formKey,
      onChanged: () => ref.invalidate(_canSubmitProvider),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text("User Registration",
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ..._buildFormItems().map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: w,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: ref.watch(_canSubmitProvider)
                  ? () => _onSubmit(_formKey.currentState!)
                  : null,
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _buildFormItems() {
    return [
      FormBuilderTextField(
        name: "firstName",
        initialValue: _user?.firstName,
        decoration: const InputDecoration(labelText: "First name"),
        keyboardType: TextInputType.name,
        validator: FormBuilderValidators.required(),
        textInputAction: TextInputAction.next,
      ),
      FormBuilderTextField(
        name: "lastName",
        initialValue: _user?.lastName,
        decoration: const InputDecoration(labelText: "Last name"),
        keyboardType: TextInputType.name,
        validator: FormBuilderValidators.required(),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) {
          if (ref.read(_canSubmitProvider)) {
            _onSubmit(_formKey.currentState!);
          }
        },
      ),
    ];
  }

  Future<void> _onSubmit(FormBuilderState form) async {
    // When form values are invalid
    if (!form.saveAndValidate()) {
      return;
    }

    // Disable UI
    ref.read(_isSendingProvider.notifier).state = true;

    final server = await ref.read(kmitlTelemedServerProvider.future);

    try {
      final response = await server.getUsersApi().usersRegisterMePost(
            userRegisterMyselfRequest: UserRegisterMyselfRequest(
              firstName: (form.value["firstName"] as String).trim(),
              lastName: (form.value["lastName"] as String).trim(),
            ),
          );

      if (response.statusCode != 200) {
        showErrorMessage("HTTP Error: ${response.statusMessage}");
        return;
      }
    } on DioException catch (e) {
      showErrorMessage("Internal Error: ${e.message}");
      return;
    } finally {
      // Enable UI
      ref.read(_isSendingProvider.notifier).state = false;
    }

    if (context.mounted) {
      context.go("/");
    }
  }

  void showErrorMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.deepOrange,
      ));
    }
  }
}
