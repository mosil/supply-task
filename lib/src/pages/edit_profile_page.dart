import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../widgets/shared/confirmation_dialog.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _contactInfoController.text = user.contactInfo;
      _contactPhoneController.text = user.phoneNumber;
    }

    void setDirty() => setState(() => _isDirty = true);
    _displayNameController.addListener(setDirty);
    _contactInfoController.addListener(setDirty);
    _contactPhoneController.addListener(setDirty);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isDirty = false);
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _contactInfoController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user!;

      final updatedProfile = UserProfile(
        uid: currentUser.uid,
        email: currentUser.email,
        displayName: _displayNameController.text,
        contactInfo: _contactInfoController.text,
        phoneNumber: _contactPhoneController.text,
      );

      await authProvider.updateUserProfile(updatedProfile);

      if (mounted) {
        setState(() => _isDirty = false);
        context.go('/profile');
      }
    }
  }

  Future<void> _onWillPop() async {
    if (!_isDirty) {
      if (mounted) context.go('/profile');
      return;
    }

    final shouldPop = await showConfirmationDialog(
          context: context,
          title: '確認捨棄變更',
          content: const Text('您確定要離開嗎？所有未儲存的變更將會遺失。'),
          confirmButtonText: '確定捨棄',
          onConfirm: () {},
        ) ??
        false;

    if (shouldPop && mounted) {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewUser = context.read<AuthProvider>().isNewUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('編輯個人資料'),
          leading: isNewUser
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _onWillPop,
                ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '顯示名稱',
                  hintText: '請輸入要顯示於外的名稱',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '顯示名稱為必填欄位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactInfoController,
                decoration: const InputDecoration(
                  labelText: '聯絡資訊',
                  hintText: '可輸入任何聯絡電話外的資訊，比方說 LINE 的 ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  labelText: '聯絡電話',
                  hintText: '請輸入聯絡電話',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]+'))],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('儲存'),
          ),
        ),
      ),
    );
  }
}
