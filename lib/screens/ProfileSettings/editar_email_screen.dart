// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class EditarEmailScreen extends StatefulWidget {
  const EditarEmailScreen({super.key});

  @override
  _EditarEmailScreenState createState() => _EditarEmailScreenState();
}

class _EditarEmailScreenState extends State<EditarEmailScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _atualizarEmail() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      final credenciais = EmailAuthProvider.credential(
        email: user!.email!,
        password: _senhaController.text.trim(),
      );

      try {
        await user.reauthenticateWithCredential(credenciais);
        await user.updateEmail(_emailController.text.trim());
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar e-mail: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Alterar E-mail'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Novo e-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? 'Informe um e-mail válido' : null,
              ),
              TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(labelText: 'Senha atual'),
                obscureText: true,
                validator: (value) =>
                    value!.isEmpty ? 'Informe sua senha atual' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _atualizarEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  backgroundColor: Colors.black,
                ), 
                child: Text('Salvar', 
                style: TextStyle(color: Colors.white),),
              )
            ],
          ),
        ),
      ),
    );
  }
}