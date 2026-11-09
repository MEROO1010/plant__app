import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).register(_name.text.trim(), _email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: PageFrame(
              maxWidth: 420,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.tr('create_account'), style: text.headlineLarge),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('register_name'),
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: context.tr('name')),
                      validator: localized(context, Validators.required),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register_email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: context.tr('email')),
                      validator: localized(context, Validators.email),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('register_password'),
                      controller: _password,
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(labelText: context.tr('password')),
                      validator: localized(context, Validators.password),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      Text(auth.error!, style: text.bodyMedium?.copyWith(color: AppColors.coral)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('register_submit'),
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(context.tr('create_account')),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () => context.go('/login'), child: Text(context.tr('have_account'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
