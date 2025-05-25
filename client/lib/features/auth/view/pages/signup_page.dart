import 'package:client/core/theme/app_pallete.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:client/features/auth/view/widgets/auth_gradient_button.dart';
import 'package:client/features/auth/view/widgets/custom_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewmodelProvider.select((val) => val?.isLoading == true));

    ref.listen(authViewmodelProvider, (_, next) {
      next?.when(
        data: (_) {
          showSnackBar(context, 'Account created successfully! Please login.');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        error: (error, _) => showSnackBar(context, error.toString()),
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: isLoading
          ? const Loader()
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomField(hintText: 'Name', controller: nameController),
                            const SizedBox(height: 16),
                            CustomField(hintText: 'Email', controller: emailController),
                            const SizedBox(height: 16),
                            CustomField(
                              hintText: 'Password',
                              controller: passwordController,
                              isObscureText: true,
                            ),
                            const SizedBox(height: 28),
                            AuthGradientButton(
                              buttonText: 'Sign Up',
                              onTap: () async {
                                if (formKey.currentState!.validate()) {
                                  await ref
                                      .read(authViewmodelProvider.notifier)
                                      .signUpUser(
                                        name: nameController.text,
                                        email: emailController.text,
                                        password: passwordController.text,
                                      );
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            Divider(color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                );
                              },
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'Already have an account? ',
                                  style: Theme.of(context).textTheme.titleMedium,
                                  children: const [
                                    TextSpan(
                                      text: 'Sign In',
                                      style: TextStyle(
                                        color: Pallete.gradient2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
