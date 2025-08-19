import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_alert/screens/main_navigation.dart';
import 'register_screen.dart';
import 'recuperar_senha_screen.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _carregando = false;

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    setState(() => _carregando = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainNavigation()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erro ao fazer login')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 32),
                        Image.asset('assets/logo_safealert.png', width: 120),
                        SizedBox(height: 24),

                        Text("Bem-vindo de volta", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                          "Entre com seu e-mail e senha para continuar",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 24),

                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:BorderSide(color: Colors.black54)),
                          ),
                          validator: (value) =>
                              value == null || !value.contains('@') ? 'Informe um e-mail válido' : null,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),

                        TextFormField(
                          controller: _senhaController,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          obscureText: true,
                          validator: (value) =>
                              value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RecuperarSenhaScreen()),
                              );
                            },
                            child: Text("Esqueceu a senha?", 
                                    style: TextStyle(color: Colors.blue),
                                    ),
                          ),
                        ),
                                          
                        SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _carregando ? null : _fazerLogin,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _carregando
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Entrar"),
                        ),

                        Spacer(),

                        SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Não tem uma conta?"),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                                );
                              },
                              child: Text("Cadastre-se", 
                              style: TextStyle(color: Colors.blue),),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

                        Text.rich(
                          TextSpan(
                            text: "Ao continuar, você concorda com nossos\n",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            children: [
                              TextSpan(
                                text: "Termos de Serviço",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                                // TODO: adicionar link
                              ),
                              TextSpan(text: " e "),
                              TextSpan(
                                text: "Política de Privacidade",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                                // TODO: adicionar link
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                       
                        SizedBox(height: 10),

                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
