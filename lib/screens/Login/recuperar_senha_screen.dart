// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  // 1ª CORREÇÃO: Adicionado o construtor com a chave (key)
  const RecuperarSenhaScreen({super.key});

  @override
  // 2ª CORREÇÃO: O tipo do State agora é público
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _carregando = false;

  Future<void> _enviarRecuperacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    final email = _emailController.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // 3ª CORREÇÃO: Adicionada a verificação 'mounted' antes de usar o BuildContext
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Link de redefinição enviado para $email. Verifique a sua caixa de entrada e a de spam.")),
      );
      Navigator.pop(context); // Volta para a tela de login
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro ao enviar o link')),
      );
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Recuperar senha",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        leading: const BackButton(),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Informe o seu e-mail para receber um link de redefinição de senha.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-mail"),
                validator: (value) =>
                    value == null || !value.contains('@') ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregando ? null : _enviarRecuperacao,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Enviar link"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
