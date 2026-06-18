import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   const Icon(Icons.blur_on, size: 80, color: Color(0xFF4354FF)),
                   const SizedBox(height: 20),
                   Text("CHANNEL", style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textDark, fontWeight: FontWeight.bold, letterSpacing: 2)),
                   const Text("PORTAL ACCESS", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 4)),
                   const SizedBox(height: 48),
                   Container(
                     constraints: const BoxConstraints(maxWidth: 400),
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: const Color(0xFF111111),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.white.withOpacity(0.05))
                     ),
                     child: Column(
                       children: [
                         TextFormField(
                           controller: _emailController,
                           decoration: const InputDecoration(
                             labelText: "Email Address",
                             prefixIcon: Icon(Icons.email_outlined)
                           ),
                           keyboardType: TextInputType.emailAddress,
                           validator: (val) => val!.isEmpty ? 'Enter email' : null,
                         ),
                         const SizedBox(height: 16),
                         TextFormField(
                           controller: _passwordController,
                           decoration: const InputDecoration(
                             labelText: "Password",
                             prefixIcon: Icon(Icons.lock_outline)
                           ),
                           obscureText: true,
                           validator: (val) => val!.isEmpty ? 'Enter password' : null,
                         ),
                         const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: BlocBuilder<AuthBloc, AuthState>(
                             builder: (context, state) {
                               return ElevatedButton(
                                 onPressed: state is AuthLoading 
                                  ? null 
                                  : () {
                                     if (_formKey.currentState!.validate()) {
                                       context.read<AuthBloc>().add(AuthLogin(_emailController.text, _passwordController.text));
                                     }
                                  },
                                 child: state is AuthLoading ? const CircularProgressIndicator() : const Text("Login"),
                               );
                             },
                           ),
                         ),
                         const SizedBox(height: 16),
                         TextButton(
                           onPressed: () => context.push('/register'),
                           child: const Text("Don't have an account? Register"),
                         )
                       ],
                     ),
                   )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
