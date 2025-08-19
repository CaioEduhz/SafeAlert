import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  @override
  _RecuperarSenhaScreenState createState() => _RecuperarSenhaScreenState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Link de redefinição enviado para $email, verifique a caixa de entrada e a caixa de spam.")),
      );
      Navigator.pop(context); // Volta para tela de login
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro ao enviar link')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Recuperar senha", 
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      ),
              backgroundColor: Colors.black, 
              leading: BackButton(),
              iconTheme: IconThemeData(
                color: Colors.white,
              ),
              ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Informe seu e-mail para receber um link de redefinição de senha.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "E-mail"),
                validator: (value) =>
                    value == null || !value.contains('@') ? 'E-mail inválido' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregando ? null : _enviarRecuperacao,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  backgroundColor: Colors.black,
                ),
                child: _carregando
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Enviar link",
                    style: TextStyle(color: Colors.white),
                    ),
                
              ),
            ],
          ),
        ),
      ),
    );
  }
}
