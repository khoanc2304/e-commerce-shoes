import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signUpWithEmail(
            _fullNameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _onGoogleSignIn() {
    context.read<AuthCubit>().signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF161622) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF232332) : const Color(0xFFEEEEF4);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration complete! Welcome ${state.user.fullName}'), backgroundColor: Colors.green),
            );
            context.go('/home');
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shopify style stylized header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_add_outlined, size: 44, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.w900, 
                              color: isDark ? Colors.white : const Color(0xFF1A1B2D),
                              letterSpacing: 1.5
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign up now to start matching your sneakers catalog',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs Container Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: borderColor),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'e.g. John Doe',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Enter your full name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'name@example.com',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Enter an email' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (value) =>
                                value != null && value.length < 6
                                    ? 'Password must be at least 6 characters'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (state is AuthLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      // Primary Button
                      ElevatedButton(
                        onPressed: _onSignUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      const SizedBox(height: 16),
                      // Google Sign Up Button
                      OutlinedButton.icon(
                        onPressed: _onGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata, size: 30),
                        label: const Text('Sign up with Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: borderColor),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
