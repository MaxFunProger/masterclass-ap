import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/session_storage.dart';
import '../../../../core/strings.dart';

/// Данные аккаунта: телефон из профиля и пароль, сохранённый на устройстве после входа.
class ProfileDataScreen extends StatefulWidget {
  const ProfileDataScreen({
    super.key,
    required this.phoneFromProfile,
  });

  final String phoneFromProfile;

  @override
  State<ProfileDataScreen> createState() => _ProfileDataScreenState();
}

class _ProfileDataScreenState extends State<ProfileDataScreen> {
  String? _savedPassword;
  bool _obscurePassword = true;
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _phone = widget.phoneFromProfile.trim();
    _loadStored();
  }

  Future<void> _loadStored() async {
    final p = await SessionStorage.getSavedPassword();
    String phone = _phone;
    if (phone.isEmpty) {
      final ph = await SessionStorage.getSavedPhone();
      if (ph != null && ph.isNotEmpty) phone = ph;
    }
    if (!mounted) return;
    setState(() {
      _phone = phone;
      _savedPassword = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phone.isEmpty ? ' - ' : _phone;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.yourData),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.profileDataExplanation,
            style: TextStyle(
                fontSize: 14, height: 1.4, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          _DataBlock(
            label: AppStrings.phoneField,
            value: phone,
            onCopy: phone != ' - '
                ? () => Clipboard.setData(ClipboardData(text: phone))
                : null,
          ),
          const SizedBox(height: 20),
          _DataBlock(
            label: AppStrings.passwordField,
            value: _savedPassword == null || _savedPassword!.isEmpty
                ? null
                : (_obscurePassword
                    ? '*' * _savedPassword!.length
                    : _savedPassword!),
            placeholder: AppStrings.passwordPlaceholder,
            trailing: _savedPassword != null && _savedPassword!.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword
                        ? AppStrings.showPassword
                        : AppStrings.hidePassword,
                  )
                : null,
            onCopy: (_savedPassword != null && _savedPassword!.isNotEmpty)
                ? () => Clipboard.setData(ClipboardData(text: _savedPassword!))
                : null,
          ),
        ],
      ),
    );
  }
}

class _DataBlock extends StatelessWidget {
  const _DataBlock({
    required this.label,
    this.value,
    this.placeholder,
    this.trailing,
    this.onCopy,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final Widget? trailing;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: value != null
                      ? SelectableText(
                          value!,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w500),
                        )
                      : Text(
                          placeholder ?? ' - ',
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey.shade600),
                        ),
                ),
                if (trailing != null) trailing!,
                if (onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 22),
                    onPressed: onCopy,
                    tooltip: AppStrings.copy,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
