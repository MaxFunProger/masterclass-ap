import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/auth_service.dart';
import '../../../../core/api_client.dart';
import '../../../../core/strings.dart';
import '../../../../core/utils/ru_phone_input_formatter.dart';
import '../../../../core/session_storage.dart';
import '../../../../core/widgets/labeled_svg_button.dart';
import '../widgets/auth_rounded_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isRepeatPasswordVisible = false;
  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _repeatPasswordError;
  final _authService = AuthService(ApiClient());

  static const _kErrorStyle = TextStyle(color: Colors.red, fontSize: 12);

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+7';
    _phoneController.selection =
        TextSelection.collapsed(offset: _phoneController.text.length);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final pass = _passwordController.text;
    final pass2 = _repeatPasswordController.text;

    String? nameErr;
    String? phoneErr;
    String? passwordErr;
    String? repeatErr;

    if (name.isEmpty) {
      nameErr = AppStrings.nameRequired;
    }
    if (!RuPhoneInputFormatter.isValid(_phoneController.text)) {
      phoneErr = AppStrings.phoneFormatError;
    }
    if (pass.isEmpty) {
      passwordErr = AppStrings.passwordRequired;
    }
    if (pass2.isEmpty) {
      repeatErr = AppStrings.repeatPasswordRequired;
    } else if (pass.isNotEmpty && pass != pass2) {
      repeatErr = AppStrings.passwordsMismatch;
    }

    if (nameErr != null ||
        phoneErr != null ||
        passwordErr != null ||
        repeatErr != null) {
      setState(() {
        _nameError = nameErr;
        _phoneError = phoneErr;
        _passwordError = passwordErr;
        _repeatPasswordError = repeatErr;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _repeatPasswordError = null;
    });

    setState(() => _isLoading = true);
    try {
      final response = await _authService.register(
        phone: _phoneController.text,
        password: pass,
        fullName: name,
      );

      final userId = response['user_id'];
      if (userId != null) {
        await SessionStorage.saveUserId(userId);
        await SessionStorage.saveLoginCredentials(
          _phoneController.text,
          pass,
        );
        await SessionStorage.setAwaitingPostTutorialFeedFilterPrompt(true);
        if (mounted) {
          context.go('/tutorial');
        }
      } else if (mounted) {
        setState(() => _passwordError = AppStrings.registerFailed);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      final lower = msg.toLowerCase();
      setState(() {
        if (lower.contains('phone already') ||
            lower.contains('already registered')) {
          _phoneError = AppStrings.phoneAlreadyRegistered;
        } else if (lower.contains('full_name') && lower.contains('missing')) {
          _nameError = AppStrings.nameRequired;
        } else if (lower.contains('invalid phone')) {
          _phoneError = AppStrings.checkPhoneFormat;
        } else if (lower.contains('нет связи') ||
            lower.contains('connection') ||
            lower.contains('network') ||
            lower.contains('failed host lookup') ||
            lower.contains('socketexception')) {
          _passwordError =
              AppStrings.noConnectionCheck(ApiClient.defaultBaseUrl);
        } else {
          _passwordError = msg;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final kbInset = mq.viewInsets.bottom;
    final guyHeight = w * 0.6;
    final bottomScrollGap = guyHeight + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Image.asset(
            'assets/background_orange.png',
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: kbInset,
            child: IgnorePointer(
              child: SvgPicture.asset(
                'assets/guy_love.svg',
                width: w,
                height: guyHeight,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Padding(
                  padding: EdgeInsets.only(bottom: kbInset),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.registerTitle,
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.registerSubtitle,
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 32),
                              AuthRoundedField(
                                child: TextField(
                                  controller: _nameController,
                                  scrollPadding:
                                      AuthRoundedField.fieldScrollPadding,
                                  onChanged: (_) =>
                                      setState(() => _nameError = null),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.nameLabel,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    errorText: _nameError,
                                    errorStyle: _kErrorStyle,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  height: AuthRoundedField.fieldSpacing),
                              AuthRoundedField(
                                child: TextField(
                                  controller: _phoneController,
                                  scrollPadding:
                                      AuthRoundedField.fieldScrollPadding,
                                  onChanged: (_) =>
                                      setState(() => _phoneError = null),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.phoneLabel,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    errorText: _phoneError,
                                    errorStyle: _kErrorStyle,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    RuPhoneInputFormatter(),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  height: AuthRoundedField.fieldSpacing),
                              AuthRoundedField(
                                child: TextField(
                                  controller: _passwordController,
                                  scrollPadding:
                                      AuthRoundedField.fieldScrollPadding,
                                  onChanged: (_) => setState(() {
                                    _passwordError = null;
                                    _repeatPasswordError = null;
                                  }),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.passwordLabel,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    errorText: _passwordError,
                                    errorStyle: _kErrorStyle,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                ),
                              ),
                              const SizedBox(
                                  height: AuthRoundedField.fieldSpacing),
                              AuthRoundedField(
                                child: TextField(
                                  controller: _repeatPasswordController,
                                  scrollPadding:
                                      AuthRoundedField.fieldScrollPadding,
                                  onChanged: (_) => setState(() {
                                    _repeatPasswordError = null;
                                    _passwordError = null;
                                  }),
                                  decoration: InputDecoration(
                                    labelText: AppStrings.repeatPasswordLabel,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    errorText: _repeatPasswordError,
                                    errorStyle: _kErrorStyle,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isRepeatPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isRepeatPasswordVisible =
                                              !_isRepeatPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: !_isRepeatPasswordVisible,
                                ),
                              ),
                              const SizedBox(height: 16),
                              LabeledSvgButton(
                                svgAssetPath: 'assets/button_big_orange.svg',
                                label: AppStrings.register,
                                textColor: Colors.white,
                                showMaterialSplash: false,
                                onTap: _isLoading ? null : _register,
                              ),
                              SizedBox(height: bottomScrollGap),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
