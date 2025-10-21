// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditarSenhaScreen extends StatefulWidget {
  // 1ª CORREÇÃO: Adicionado o construtor com a chave (key)
  const EditarSenhaScreen({super.key});

  @override
  // 2ª CORREÇÃO: O tipo do State agora é público
  State<EditarSenhaScreen> createState() => _EditarSenhaScreenState();
}

class _EditarSenhaScreenState extends State<EditarSenhaScreen> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _carregando = false;

  Future<void> _atualizarSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _carregando = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum usuário logado.')),
        );
        setState(() => _carregando = false);
      }
      return;
    }
    
    final currentPassword = _senhaAtualController.text.trim();
    final newPassword = _novaSenhaController.text.trim();

    try {
      final credenciais = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credenciais);
      await user.updatePassword(newPassword);

      // 3ª CORREÇÃO: Adicionada a verificação 'mounted'
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso!')),
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensagemErro = 'Ocorreu um erro ao atualizar a senha.';
      if (e.code == 'wrong-password') {
        mensagemErro = 'A senha atual está incorreta.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro)),
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
        title: const Text('Alterar Senha'),
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
                controller: _senhaAtualController,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe sua senha atual' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _novaSenhaController,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _carregando ? null : _atualizarSenha,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: _carregando
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
