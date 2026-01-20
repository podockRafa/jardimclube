import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_cadastro.dart'; // Certifique-se que este arquivo existe na mesma pasta
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  // Controladores
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  
  // Variáveis de Estado
  bool _estaCarregando = false;
  bool _mostrarSenha = false; 

  // Função para logar no Firebase
  // Função BLINDADA para logar no Firebase
  Future<void> _fazerLogin() async {
    if (_estaCarregando) return;

    setState(() => _estaCarregando = true);

    try {
      // 1. Tenta logar com senha (O Porteiro confere a identidade)
      UserCredential credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      // 2. AGORA VEM A MÁGICA: Conferir o crachá (Status) no Banco de Dados
      String uid = credencial.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> dados = userDoc.data() as Map<String, dynamic>;
        
        // Se o status for "AGUARDANDO_APROVACAO", nós barramos a entrada!
        if (dados['status'] == 'AGUARDANDO_APROVACAO') {
          await FirebaseAuth.instance.signOut(); // 🚫 Logout forçado imediato!
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Acesso negado: Seu cadastro aguarda aprovação do Síndico."),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5), // Fica mais tempo na tela pra lerem
            ),
          );
          return; // Para a função aqui. Não deixa mudar de tela.
        }
        
        // Se for "BLOQUEADO", também barramos
        if (dados['status'] == 'BLOQUEADO') {
           await FirebaseAuth.instance.signOut();
           if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Esta conta foi desativada."), backgroundColor: Colors.red),
           );
           return;
        }
      }

      // Se passou por tudo isso, o main.dart vai detectar o login e mudar a tela sozinho.

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String mensagemErro = "Ocorreu um erro desconhecido.";
      if (e.code == 'invalid-credential') {
        mensagemErro = "E-mail ou senha incorretos.";
      } else if (e.code == 'invalid-email') {
        mensagemErro = "O formato do e-mail é inválido.";
      } else {
        mensagemErro = e.message ?? mensagemErro;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $mensagemErro"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _estaCarregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO ---
              const Icon(Icons.apartment_rounded, size: 80, color: Color(0xFF1B4D3E)),
              const SizedBox(height: 20),
              
              const Text(
                "JARDIM CLUBE",
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // --- CARTÃO DE LOGIN ---
              Container(
                width: larguraTela > 600 ? 400 : double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Acesso Morador/Adm", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 24),
                    
                    // Campo Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo Senha
                    TextField(
                      controller: _senhaController,
                      obscureText: !_mostrarSenha, 
                      textInputAction: TextInputAction.done, 
                      onSubmitted: (_) => _fazerLogin(), 
                      decoration: InputDecoration(
                        labelText: "Senha",
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_mostrarSenha ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _mostrarSenha = !_mostrarSenha;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão de Entrar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _estaCarregando ? null : _fazerLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4D3E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _estaCarregando 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("ENTRAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botão Esqueci Senha
                    TextButton(
                      onPressed: () {}, 
                      child: const Text("Esqueci minha senha", style: TextStyle(color: Colors.grey)),
                    ),

                    const SizedBox(height: 30),

                    // --- RODAPÉ DE CADASTRO (Agora no lugar certo!) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Ainda não tem conta?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TelaCadastro()),
                            );
                          },
                          child: const Text(
                            "Cadastre-se",
                            style: TextStyle(
                              color: Color(0xFF1B4D3E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}