import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter/foundation.dart';

// --- IMPORTANTE: Importando o cofre de segredos ---
import '../segredos.dart'; 

class TelaAbrirChamado extends StatefulWidget {
  const TelaAbrirChamado({super.key});

  @override
  State<TelaAbrirChamado> createState() => _TelaAbrirChamadoState();
}

class _TelaAbrirChamadoState extends State<TelaAbrirChamado> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  bool _enviando = false;
  XFile? _imagemSelecionada; 

  // --- FUNÇÃO 1: TIRAR FOTO ---
  Future<void> _tirarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = imagem;
      });
    }
  }

  // --- FUNÇÃO 2: UPLOAD PARA CLOUDINARY (AGORA SEGURO 🔒) ---
  Future<String?> _uploadImagem() async {
    if (_imagemSelecionada == null) return null;

    try {
      // AQUI ESTÁ A MUDANÇA: Usamos as variáveis do arquivo segredos.dart
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,    // Vem do cofre
        cloudinaryUploadPreset, // Vem do cofre
        cache: false
      );

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_imagemSelecionada!.path, resourceType: CloudinaryResourceType.Image),
      );

      return response.secureUrl;

    } catch (e) {
      print("Erro no upload Cloudinary: $e");
      return null;
    }
  }

  // --- FUNÇÃO 3: SALVAR NO BANCO ---
  Future<void> _enviarChamado() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dê um título ao problema!")));
      return;
    }

    setState(() => _enviando = true);

    try {
      User? usuario = FirebaseAuth.instance.currentUser;
      
      // 1. Tenta subir a foto primeiro (se tiver)
      String? urlFoto = await _uploadImagem(); 

      // 2. Prepara os dados do usuário
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(usuario!.uid).get();
      Map<String, dynamic> userDados = userDoc.data() as Map<String, dynamic>? ?? {};

      // 3. Salva no Firestore
      await FirebaseFirestore.instance.collection('ocorrencias').add({
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'autor_uid': usuario.uid,
        'autor_nome': userDados['nome'] ?? 'Morador',
        'unidade': userDados['unidade_vinculada'] ?? 'Sem unidade',
        'data_abertura': FieldValue.serverTimestamp(),
        'status': 'ABERTO', 
        'foto_url': urlFoto, 
      });

      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chamado aberto com sucesso!"), backgroundColor: Colors.green),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Chamado"), backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("O que aconteceu?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: "Assunto (Ex: Lâmpada Queimada)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Detalhes (Opcional)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            const Text("Evidência (Foto)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            InkWell(
              onTap: _tirarFoto,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                  image: _imagemSelecionada != null 
                    ? DecorationImage(
                        image: kIsWeb 
                          ? NetworkImage(_imagemSelecionada!.path) 
                          : FileImage(File(_imagemSelecionada!.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: _imagemSelecionada == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                        Text("Toque para fotografar", style: TextStyle(color: Colors.grey))
                      ],
                    )
                  : null,
              ),
            ),
            
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarChamado,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4D3E),
                  foregroundColor: Colors.white,
                ),
                child: _enviando 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENVIAR SOLICITAÇÃO", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}