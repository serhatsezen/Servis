import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  final _sifreTekrarController = TextEditingController();
  String _secilenRol = AppConstants.rolPersonel;
  bool _sifreGizli = true;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    _sifreTekrarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ad Soyad
                  TextFormField(
                    controller: _adSoyadController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ad soyad gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // E-posta
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta adresi gerekli';
                      }
                      if (!value.contains('@')) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şifre
                  TextFormField(
                    controller: _sifreController,
                    obscureText: _sifreGizli,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sifreGizli
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _sifreGizli = !_sifreGizli);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şifre Tekrar
                  TextFormField(
                    controller: _sifreTekrarController,
                    obscureText: _sifreGizli,
                    decoration: const InputDecoration(
                      labelText: 'Şifre Tekrar',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    validator: (value) {
                      if (value != _sifreController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Rol Seçimi
                  DropdownButtonFormField<String>(
                    value: _secilenRol,
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AppConstants.rolPersonel,
                        child: Text('Personel'),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.rolSofor,
                        child: Text('Şoför'),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.rolAdmin,
                        child: Text('Admin'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _secilenRol = value);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Kayıt Butonu
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state is AuthLoading ? null : _kayitOl,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Kayıt Ol',
                                style: TextStyle(fontSize: 16),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _kayitOl() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterRequested(
            email: _emailController.text.trim(),
            sifre: _sifreController.text,
            adSoyad: _adSoyadController.text.trim(),
            rol: _secilenRol,
          ));
    }
  }
}
