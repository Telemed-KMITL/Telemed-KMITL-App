import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:kmitl_telemedicine_server/kmitl_telemedicine_server.dart'
    as api;
import 'package:kmitl_telemedicine_staff/providers.dart';
import 'package:kmitl_telemedicine_staff/views/form_dialog.dart';

class CreateUserRecordDialog extends ConsumerStatefulWidget {
  const CreateUserRecordDialog({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateUserRecordDialogState();
}

class _CreateUserRecordDialogState
    extends ConsumerState<CreateUserRecordDialog> {
  bool _isExistingUser = true;
  bool _isExistingUserHintUid = false;
  String _existingUserHint = ""; // UserID or Email
  String _newUserEmail = "";
  bool _isNewUserEmailVerified = false;
  String _newUserPassword = "";
  late api.User _userRecord;

  StringValidationCallback get _userIdValidator =>
      ValidationBuilder().required().maxLength(128).build();
  StringValidationCallback get _emailValidator =>
      ValidationBuilder().required().email().build();
  StringValidationCallback get _passwordValidator =>
      ValidationBuilder().required().minLength(6).build();
  StringValidationCallback get _nameValidator =>
      ValidationBuilder().required().build();

  @override
  void initState() {
    _resetUserFieldValues();
    _resetUserRecord();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: const Text("Create User (Record)"),
      content: _buildBody(),
      onSubmit: _submit,
      submitButtonText: "Create",
    );
  }

  Widget _buildBody() {
    return SizedBox(
      width: 450,
      child: Column(
        children: [
          // [ Existing User | New User ]
          ToggleButtons(
            isSelected: [
              _isExistingUser,
              !_isExistingUser,
            ],
            onPressed: (index) => setState(() {
              _isExistingUser = index == 0;
              _resetUserFieldValues();
            }),
            constraints: const BoxConstraints(
              minWidth: 110.0,
              minHeight: 40.0,
            ),
            children: const [
              Text("Existing User"),
              Text("New User"),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isExistingUser
                ? _buildExistingUserFields()
                : _buildNewUserFields(),
          ),
          const Divider(thickness: 2, height: 40),
          _buildUserRecordFields(),
        ],
      ),
    );
  }

  Widget _buildExistingUserFields() {
    return Column(
      key: const ValueKey("existing_user_fields"),
      children: [
        // [@ Email ⇄] / [# UserID ⇄]
        TextFormField(
          initialValue: _existingUserHint,
          validator:
              _isExistingUserHintUid ? _userIdValidator : _emailValidator,
          decoration: InputDecoration(
            labelText: _isExistingUserHintUid ? "UserID" : "Email",
            prefixIcon: _isExistingUserHintUid
                ? const Icon(Icons.numbers)
                : const Icon(Icons.email),
            suffixIcon: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.swap_horiz),
              tooltip: _isExistingUserHintUid
                  ? "Switch to Email"
                  : "Switch to UserID",
              onPressed: () => setState(() {
                _isExistingUserHintUid = !_isExistingUserHintUid;
              }),
            ),
          ),
          onSaved: (value) => setState(() {
            _existingUserHint = value ?? "";
          }),
        ),
      ],
    );
  }

  Widget _buildNewUserFields() {
    return Column(
      key: const ValueKey("new_user_fields"),
      children: [
        // [@ Email] ☑ Verified
        Row(
          children: [
            Flexible(
              child: TextFormField(
                initialValue: _newUserEmail,
                validator: _emailValidator,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                onSaved: (value) => setState(() {
                  _newUserEmail = value ?? "";
                }),
              ),
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: _isNewUserEmailVerified,
              onChanged: (value) => setState(() {
                _isNewUserEmailVerified = value ?? false;
              }),
            ),
            const Text("Verified"),
          ],
        ),
        const SizedBox(height: 6),
        // [🔒 Password]
        TextFormField(
          initialValue: _newUserPassword,
          validator: _passwordValidator,
          decoration: const InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock),
          ),
          onSaved: (value) => setState(() {
            _newUserPassword = value ?? "";
          }),
        ),
      ],
    );
  }

  Widget _buildUserRecordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "User Details",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        // [First name] [Last name]
        Row(
          children: [
            Flexible(
              child: TextFormField(
                initialValue: _userRecord.firstName,
                validator: _nameValidator,
                decoration: const InputDecoration(
                  labelText: "First name",
                ),
                onSaved: (value) => _userRecord = api.User(
                  firstName: value!,
                  lastName: _userRecord.lastName,
                  role: _userRecord.role,
                  HN: _userRecord.HN,
                  status: _userRecord.status,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextFormField(
                initialValue: _userRecord.lastName,
                validator: _nameValidator,
                decoration: const InputDecoration(
                  labelText: "Last name",
                ),
                onSaved: (value) => _userRecord = api.User(
                  firstName: _userRecord.firstName,
                  lastName: value!,
                  role: _userRecord.role,
                  HN: _userRecord.HN,
                  status: _userRecord.status,
                ),
              ),
            ),
          ],
        ),
        // [Role ▼]
        DropdownButtonFormField<api.UserRole>(
          value: _userRecord.role,
          items: api.UserRole.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ))
              .toList(),
          decoration: const InputDecoration(
            labelText: "Role",
          ),
          onChanged: (value) {
            if (value == null) return;
            _userRecord = api.User(
              firstName: _userRecord.firstName,
              lastName: _userRecord.lastName,
              role: value,
              HN: _userRecord.HN,
              status: _userRecord.status,
            );
          },
        ),
        // [HN]
        TextFormField(
          decoration: const InputDecoration(
            labelText: "HN",
          ),
          onSaved: (value) => _userRecord = api.User(
            firstName: _userRecord.firstName,
            lastName: _userRecord.lastName,
            role: _userRecord.role,
            HN: value,
            status: _userRecord.status,
          ),
        ),
        // [Status ▼]
        DropdownButtonFormField<api.UserStatus>(
          value: _userRecord.status,
          items: api.UserStatus.values
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name),
                  ))
              .toList(),
          decoration: const InputDecoration(
            labelText: "Status",
          ),
          onChanged: (value) {
            if (value == null) return;
            _userRecord = api.User(
              firstName: _userRecord.firstName,
              lastName: _userRecord.lastName,
              role: _userRecord.role,
              HN: _userRecord.HN,
              status: value,
            );
          },
        ),
      ],
    );
  }

  void _resetUserFieldValues() => setState(() {
        _isExistingUserHintUid = false;
        _existingUserHint = "";
        _newUserEmail = "";
        _isNewUserEmailVerified = false;
        _newUserPassword = "";
      });

  void _resetUserRecord() => setState(() {
        _userRecord = api.User(
          firstName: "",
          lastName: "",
          role: api.UserRole.patient,
          HN: null,
          status: api.UserStatus.active,
        );
      });

  Future<String?> _submit() async {
    try {
      final server = await ref.read(kmitlTelemedServerProvider.future);

      if (!_isExistingUser) {
        // Create new user
        await server.getUsersApi().usersPost(
              createUserRequest: api.CreateUserRequest(
                email: _newUserEmail,
                password: _newUserPassword,
                user: _userRecord,
                emailVerified: _isNewUserEmailVerified,
              ),
            );
      } else if (_isExistingUserHintUid) {
        // Register existing user by UserID
        await server.getUsersApi().usersRegisterUseridPost(
              userid: _existingUserHint,
              user: _userRecord,
            );
      } else {
        // Register existing user by Email
        await server.getUsersApi().usersRegisterEmailPost(
              email: _existingUserHint,
              user: _userRecord,
            );
      }
    } on DioException catch (e) {
      final response = e.response;
      final data = response?.data;
      return data is String && data.isNotEmpty ? data : "Network error";
    }

    return null;
  }
}
