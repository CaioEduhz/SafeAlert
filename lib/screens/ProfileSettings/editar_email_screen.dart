// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditarEmailScreen extends StatefulWidget {
  const EditarEmailScreen({super.key});

  @override
  State<EditarEmailScreen> createState() => _EditarEmailScreenState();
}

class _EditarEmailScreenState extends State<EditarEmailScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _atualizarEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum usuário logado.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }
    
    final newEmail = _emailController.text.trim();
    final currentPassword = _senhaController.text.trim();

    try {
      final credenciais = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credenciais);

      await user.verifyBeforeUpdateEmail(newEmail);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail de verificação enviado! Por favor, confirme no seu novo e-mail para concluir a alteração.'),
          duration: Duration(seconds: 5),
        ),
      );
      
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String mensagemErro;
      if (e.code == 'wrong-password') {
        mensagemErro = 'A senha atual está incorreta. Tente novamente.';
      } else if (e.code == 'email-already-in-use') {
        mensagemErro = 'Este e-mail já está sendo usado por outra conta.';
      } else {
        mensagemErro = 'Ocorreu um erro. Tente novamente mais tarde.';
        // A linha 'print' foi removida daqui
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Alterar E-mail'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Novo e-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Informe um e-mail válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe sua senha atual' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _atualizarEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

