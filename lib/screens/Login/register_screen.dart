import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_alert/screens/main_navigation.dart';


class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _telefoneController = TextEditingController();

  String? _generoSelecionado;

  bool _carregando = false;

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();
    final telefone = _telefoneController.text.trim();
    final genero = _generoSelecionado;

    setState(() => _carregando = true);

    try {
      // 1. Cria o usuário no Auth
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);

      // 2. Salva os dados adicionais no Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'genero': genero,
        'uid': cred.user!.uid,
        'criado_em': Timestamp.now(),
      });

      // 3. Redireciona para tela inicial
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro ao cadastrar')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Cadastro', 
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome completo ou apelido'),
                validator: (value) => value == null || value.isEmpty ? 'Informe seu nome' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Informe um e-mail válido' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) =>
                    value != null && value.length >= 6 ? null : 'Mínimo 6 caracteres',
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _confirmarSenhaController,
                decoration: InputDecoration(labelText: 'Confirmar senha'),
                obscureText: true,
                validator: (value) => value != _senhaController.text ? 'As senhas não coincidem' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Informe o telefone' : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _generoSelecionado,
                dropdownColor: Colors.white,
                decoration: InputDecoration(labelText: 'Gênero (opcional)'),
                items: ['Masculino', 'Feminino', 'Outro', 'Prefiro não dizer']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (valor) => setState(() => _generoSelecionado = valor),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregando ? null : _registrarUsuario,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  backgroundColor: Colors.black,
                ),
                child: _carregando
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Registrar', 
                    style: TextStyle(
                        color: Colors.white, 
                        ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
