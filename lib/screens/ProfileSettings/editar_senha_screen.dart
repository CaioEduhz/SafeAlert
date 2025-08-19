import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditarSenhaScreen extends StatefulWidget {
  @override
  _EditarSenhaScreenState createState() => _EditarSenhaScreenState();
}

class _EditarSenhaScreenState extends State<EditarSenhaScreen> {
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _atualizarSenha() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      final credenciais = EmailAuthProvider.credential(
        email: user!.email!,
        password: _senhaAtualController.text.trim(),
      );

      try {
        await user.reauthenticateWithCredential(credenciais);
        await user.updatePassword(_novaSenhaController.text.trim());
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar senha: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Alterar Senha'),
        backgroundColor: Colors.white,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _senhaAtualController,
                decoration: InputDecoration(labelText: 'Senha atual'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Informe sua senha atual' : null,
              ),
              TextFormField(
                controller: _novaSenhaController,
                decoration: InputDecoration(labelText: 'Nova senha'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _atualizarSenha,
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