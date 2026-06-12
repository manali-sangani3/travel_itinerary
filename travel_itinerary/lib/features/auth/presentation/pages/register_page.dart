import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() { _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    context.read<AuthBloc>().add(RegisterRequested(_email.text.trim(), _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please sign in.')));
            context.go('/login');
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  IconButton(onPressed: () => context.go('/login'), icon: const Icon(Icons.arrow_back_rounded)),
                  const SizedBox(height: 16),
                  Text('Create account', style: AppTextStyles.h1),
                  const SizedBox(height: 8),
                  Text('Start planning your perfect trips', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 40),
                  AppTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _email,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefix: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hint: 'Minimum 8 characters',
                    controller: _password,
                    validator: Validators.password,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                    prefix: const Icon(Icons.lock_outlined, size: 20, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirm Password',
                    hint: '••••••••',
                    controller: _confirm,
                    validator: (v) {
                      if (v != _password.text) return 'Passwords do not match';
                      return null;
                    },
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    prefix: const Icon(Icons.lock_outlined, size: 20, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => AppButton(
                      label: 'Create Account',
                      loading: state is AuthLoading,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Sign In', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
