// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarTelefoneScreen extends StatefulWidget {
  // 1ª CORREÇÃO: Adicionado o construtor com a chave (key)
  const EditarTelefoneScreen({super.key});

  @override
  // 2ª CORREÇÃO: O tipo do State agora é público
  State<EditarTelefoneScreen> createState() => _EditarTelefoneScreenState();
}

class _EditarTelefoneScreenState extends State<EditarTelefoneScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _carregando = false;

  Future<void> _atualizarTelefone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _carregando = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nenhum usuário logado para atualizar.")),
        );
        setState(() => _carregando = false);
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'telefone': _controller.text.trim(),
      });

      // 3ª CORREÇÃO: Adicionada a verificação 'mounted' antes de usar o BuildContext
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telefone atualizado com sucesso!")),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao atualizar o telefone.")),
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
        title: const Text('Alterar Telefone'),
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
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Novo telefone'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe um telefone válido' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _carregando ? null : _atualizarTelefone,
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
