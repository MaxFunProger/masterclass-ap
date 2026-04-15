import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/auth_service.dart';
import '../../../../core/api_client.dart';
import '../../../../core/strings.dart';
import '../../../../core/session_storage.dart';
import '../../../../core/utils/ru_phone_input_formatter.dart';
import '../../../../core/widgets/labeled_svg_button.dart';
import '../widgets/auth_rounded_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _phoneError;
  String? _passwordError;
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
    super.dispose();
  }

  Future<void> _login() async {
    String? phoneErr;
    String? passwordErr;
    if (!RuPhoneInputFormatter.isValid(_phoneController.text)) {
      phoneErr = AppStrings.phoneFormatError;
    }
    if (_passwordController.text.isEmpty) {
      passwordErr = AppStrings.passwordRequired;
    }
    if (phoneErr != null || passwordErr != null) {
      setState(() {
        _phoneError = phoneErr;
        _passwordError = passwordErr;
      });
      return;
    }

    setState(() {
      _phoneError = null;
      _passwordError = null;
    });

    setState(() => _isLoading = true);
    try {
      final response = await _authService.login(
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      final userId = response['user_id'];
      if (userId != null) {
        await SessionStorage.saveUserId(userId);
        await SessionStorage.saveLoginCredentials(
          _phoneController.text,
          _passwordController.text,
        );
        if (mounted) {
          context.go('/home');
        }
      } else if (mounted) {
        setState(() => _passwordError = AppStrings.loginFailed);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      final lower = msg.toLowerCase();
      setState(() {
        if (lower.contains('user not found')) {
          _phoneError = AppStrings.userNotFound;
        } else if (lower.contains('invalid password')) {
          _passwordError = AppStrings.invalidPassword;
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
                                AppStrings.loginTitle,
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.loginSubtitle,
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 32),
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
                                  onChanged: (_) =>
                                      setState(() => _passwordError = null),
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
                              const SizedBox(height: 16),
                              LabeledSvgButton(
                                svgAssetPath: 'assets/button_big_black.svg',
                                label: AppStrings.login,
                                textColor: Colors.white,
                                showMaterialSplash: false,
                                onTap: _isLoading ? null : _login,
                              ),
                              const SizedBox(height: 12),
                              LabeledSvgButton(
                                svgAssetPath: 'assets/button_big_orange.svg',
                                label: AppStrings.register,
                                textColor: Colors.white,
                                onTap: () => context.push('/register'),
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
