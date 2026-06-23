import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'admin';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
           if (state is AuthRegistered) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration successful. Please login.")));
             context.go('/');
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
                children: [
                   Icon(Icons.person_add_outlined, size: 64, color: Color(0xFFA7F3D0)),
                   SizedBox(height: 16),
                   Text("JOIN CHANNEL", style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                   SizedBox(height: 32),
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
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                          validator: (value) => value!.isEmpty ? 'Enter name' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                          validator: (value) => value!.isEmpty ? 'Enter email' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                          obscureText: true,
                          validator: (value) => value!.isEmpty ? 'Enter password' : null,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _role,
                          dropdownColor: AppTheme.surfaceLight,
                          decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
                          items: ['admin', 'school_admin', 'teacher', 'parent']
                              .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                              .toList(),
                          onChanged: (v) => setState(() => _role = v!),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return ElevatedButton(
                                onPressed: state is AuthLoading 
                                  ? null 
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthBloc>().add(AuthRegister(
                                          _emailController.text,
                                          _passwordController.text,
                                          _nameController.text,
                                          _role,
                                        ));
                                      }
                                    },
                                child: state is AuthLoading 
                                  ? SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2)
                                    )
                                  : Text('Register'),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text("Already have an account? Login"),
                        )
                       ],
                     ),
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
