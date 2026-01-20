import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  // Controladores de Texto
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _blocoController = TextEditingController();
  final _aptoController = TextEditingController();

  bool _carregando = false;

  Future<void> _realizarCadastro() async {
    // 1. Validações Básicas
    if (_senhaController.text != _confirmarSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("As senhas não conferem!")));
      return;
    }
    if (_nomeController.text.isEmpty || _blocoController.text.isEmpty || _aptoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha todos os campos!")));
      return;
    }

    setState(() => _carregando = true);

    try {
      // 2. Criar Usuário no Firebase Auth (Email/Senha)
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      // 3. Salvar dados extras no Firestore (Nome, Bloco, Apto)
      String uid = userCredential.user!.uid;
      
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'nome': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'bloco': _blocoController.text.trim(),
        'unidade': _aptoController.text.trim(), // Ex: "101"
        'perfil': 'MORADOR', // Padrão é morador
        'status': 'AGUARDANDO_APROVACAO', // <--- O Pulo do Gato: Você aprova depois!
        'data_cadastro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      // Sucesso! O main.dart vai detectar o login e levar pra Home.
      // Mas podemos mostrar um aviso antes ou só fechar a tela.
      Navigator.pop(context); // Volta pro Login (ou o Auth lida com o resto)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conta criada! Aguarde aprovação do síndico."), backgroundColor: Colors.green),
      );

    } on FirebaseAuthException catch (e) {
      String erro = "Erro ao cadastrar";
      if (e.code == 'email-already-in-use') erro = "Este email já está cadastrado.";
      if (e.code == 'weak-password') erro = "A senha é muito fraca (mínimo 6 caracteres).";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro), backgroundColor: Colors.red));
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Criar Conta"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1B4D3E),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Bem-vindo ao Jardim Clube",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Preencha seus dados para solicitar acesso.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // --- DADOS PESSOAIS ---
              TextField(
                controller: _nomeController,
                decoration: _decoracaoInput("Nome Completo", Icons.person),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _blocoController,
                      keyboardType: TextInputType.number,
                      decoration: _decoracaoInput("Bloco", Icons.apartment),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _aptoController,
                      keyboardType: TextInputType.number,
                      decoration: _decoracaoInput("Apto", Icons.meeting_room),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- DADOS DE LOGIN ---
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoracaoInput("Email", Icons.email),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: _decoracaoInput("Senha", Icons.lock),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmarSenhaController,
                obscureText: true,
                decoration: _decoracaoInput("Confirmar Senha", Icons.lock_outline),
              ),
              const SizedBox(height: 32),

              // --- BOTÃO CADASTRAR ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _carregando ? null : _realizarCadastro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _carregando 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CRIAR MINHA CONTA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracaoInput(String label, IconData icone) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: const Color(0xFF1B4D3E)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}