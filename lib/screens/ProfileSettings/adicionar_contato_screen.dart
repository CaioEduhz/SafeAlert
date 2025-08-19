import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdicionarContatoScreen extends StatefulWidget {
  const AdicionarContatoScreen({super.key});

  @override
  State<AdicionarContatoScreen> createState() => _AdicionarContatoScreenState();
}

class _AdicionarContatoScreenState extends State<AdicionarContatoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();

  void _salvarContato() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final contatoRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('contatos')
          .doc(); // ID automático

      await contatoRef.set({
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'email': _emailController.text.trim(),
        'contatoId': contatoRef.id,
      });

      Navigator.pop(context); // Volta para a tela de contatos
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adicionar Contato")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome"),
                validator: (value) =>
                    value!.isEmpty ? "Informe o nome" : null,
              ),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: "Telefone"),
                validator: (value) =>
                    value!.isEmpty ? "Informe o telefone" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "E-mail"),
                validator: (value) =>
                    value!.isEmpty ? "Informe o e-mail" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarContato,
                child: const Text("Salvar Contato"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
