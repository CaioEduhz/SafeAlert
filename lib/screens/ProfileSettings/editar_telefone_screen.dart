import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarTelefoneScreen extends StatefulWidget {
  @override
  _EditarTelefoneScreenState createState() => _EditarTelefoneScreenState();
}

class _EditarTelefoneScreenState extends State<EditarTelefoneScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _atualizarTelefone() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).update({
        'telefone': _controller.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Alterar Telefone'),
        backgroundColor: Colors.white,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'Novo telefone'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Informe um telefone válido' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _atualizarTelefone,
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
