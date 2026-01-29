import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
// Notifications disabled: skip FCM and push manager initialization

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _titleFade;
  late Animation<double> _titleScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );


    // title animation delayed slightly
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
    );
    _titleScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.failure!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (next.isAuthenticated && next.user != null) {
            // Navigate to home after login (notifications disabled)
            if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFA726), // orange
              Color(0xFFFFEB3B), // yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enlarged centered illustration (static — no zoom/fade)
              SizedBox(
                height: screenHeight * 0.55,
                child: Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Image.asset('assets/images/auth.png', fit: BoxFit.contain),
                  ),
                ),
              ),

              // Centered title and welcome text (title slightly larger)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _titleFade,
                      child: ScaleTransition(
                        scale: _titleScale,
                        child: Text(
                          'Tenzin',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 56,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Тавтай морилно уу',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                          ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const EmailAuthScreen(isRegister: false),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('НЭВТРЭХ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const EmailAuthScreen(isRegister: true),
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('БҮРТГҮҮЛЭХ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Notifications disabled: navigation handled in listener directly.
}

class EmailAuthScreen extends ConsumerStatefulWidget {
  final bool isRegister;
  const EmailAuthScreen({super.key, this.isRegister = false});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late bool _isSignUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isRegister;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    if (_isSignUp) {
      ref.read(authProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
    } else {
      ref.read(authProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  // Notifications disabled: no FCM initialization here.

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.failure!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
        if (next.isAuthenticated && next.user != null) {
          if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isSignUp ? 'Бүртгүүлэх' : 'Нэвтрэх'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFA726),
              Color(0xFFFFEB3B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  labelStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                  ),
                  prefixIconColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black45,
                  suffixIconColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black45,
                ),
                textTheme: Theme.of(context).textTheme.copyWith(
                      bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                          ),
                    ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                if (_isSignUp) ...[
                  AppTextField(
                    controller: _nameController,
                    label: 'Нэр',
                    hint: 'Таны нэр',
                    prefixIcon: const Icon(Icons.person_outline),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Нэр оруулна уу';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  controller: _emailController,
                  label: 'И-мэйл',
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'И-мэйл оруулна уу';
                    }
                    if (!value.contains('@')) {
                      return 'Зөв и-мэйл оруулна уу';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PasswordTextField(
                  controller: _passwordController,
                  label: 'Нууц үг',
                  hint: '••••••••',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Нууц үг оруулна уу';
                    }
                    if (value.length < 6) {
                      return 'Нууц үг 6-аас дээш тэмдэгт байх ёстой';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: _isSignUp ? 'Бүртгүүлэх' : 'Нэвтрэх',
                  onPressed: _submit,
                  isLoading: authState.isLoading,
                  isFullWidth: true,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _isSignUp = !_isSignUp);
                  },
                  child: Text(
                      _isSignUp
                          ? 'Бүртгэлтэй юу? Нэвтрэх'
                          : 'Бүртгэлгүй юу? Бүртгүүлэх',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    )));
  }
}
