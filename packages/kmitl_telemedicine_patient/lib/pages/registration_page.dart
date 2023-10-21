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
  const RegistrationPage({super.key, this.showCancelButton = true});

  static const String path = "/register";

  final bool showCancelButton;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RegistrationPageState();
}

class _RegistrationPageState extends ConsumerState<RegistrationPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  User? _user;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Registration"),
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
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        FormBuilder(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: _buildFormItems()
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: w,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed:
                      !_isSending && (_formKey.currentState?.isDirty ?? false)
                          ? () => _onSubmit(_formKey.currentState!)
                          : null,
                  child: const Text("Register"),
                ),
                if (context.canPop() && widget.showCancelButton) ...[
                  const SizedBox(height: 2),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    // Close this page
                    onPressed: () => context.pop(false),
                    child: const Text("Cancel"),
                  ),
                ]
              ],
            ),
          ),
        )
      ],
    );
  }

  Iterable<Widget> _buildFormItems() {
    return [
      FormBuilderTextField(
        name: "firstName",
        initialValue: _user?.firstName,
        decoration: const InputDecoration(labelText: "First name (Required)"),
        keyboardType: TextInputType.name,
        validator: FormBuilderValidators.required(),
      ),
      FormBuilderTextField(
        name: "lastName",
        initialValue: _user?.lastName,
        decoration: const InputDecoration(labelText: "Last name (Required)"),
        keyboardType: TextInputType.name,
        validator: FormBuilderValidators.required(),
      ),
    ];
  }

  Future<void> _onSubmit(FormBuilderState form) async {
    // When form values are invalid
    if (!form.saveAndValidate()) {
      return;
    }

    // Disable UI
    setState(() => _isSending = true);

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

      ref.invalidate(firebaseTokenProvider);
    } on DioException catch (e) {
      showErrorMessage("Internal Error: ${e.message}");
      print(e.response?.data);
      return;
    } finally {
      // Enable UI
      setState(() => _isSending = false);
    }

    // Close this page
    if (context.mounted) {
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go("/");
      }
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
