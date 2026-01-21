import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter/foundation.dart';
import '../segredos.dart'; 

class TelaAbrirChamado extends StatefulWidget {
  const TelaAbrirChamado({super.key});

  @override
  State<TelaAbrirChamado> createState() => _TelaAbrirChamadoState();
}

class _TelaAbrirChamadoState extends State<TelaAbrirChamado> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  // NOVA VARIÁVEL: Local Selecionado
  String? _localSelecionado;

  // LISTA DE LOCAIS
  final List<String> _locais = [
    'Bloco 1', 'Bloco 2', 'Bloco 3', 'Bloco 4', 'Bloco 5', 
    'Bloco 6', 'Bloco 7', 'Bloco 8', 'Bloco 9',
    'Estacionamento Piscina', 'Piscina', 'Pátio Principal', 
    'Estacionamento de Trás', 'Cantina', 'Salão de Festas', 
    'Canteiro Lateral', 'Canteiro Frontal', 'Outro'
  ];
  
  bool _enviando = false;
  XFile? _imagemSelecionada; 

  Future<void> _selecionarImagem() async {
    final ImagePicker picker = ImagePicker();
    
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? imagem = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                  if (imagem != null) setState(() => _imagemSelecionada = imagem);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? imagem = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                  if (imagem != null) setState(() => _imagemSelecionada = imagem);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImagem() async {
    if (_imagemSelecionada == null) return null;
    try {
      final cloudinary = CloudinaryPublic(cloudinaryCloudName, cloudinaryUploadPreset, cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_imagemSelecionada!.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _enviarChamado() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dê um título ao problema!")));
      return;
    }

    setState(() => _enviando = true);

    try {
      User? usuario = FirebaseAuth.instance.currentUser;
      String? urlFoto = await _uploadImagem(); 
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(usuario!.uid).get();
      Map<String, dynamic> userDados = userDoc.data() as Map<String, dynamic>? ?? {};

      await FirebaseFirestore.instance.collection('ocorrencias').add({
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'local': _localSelecionado ?? 'Não informado', // <--- SALVANDO O LOCAL
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
            
            // --- NOVO CAMPO: LOCAL ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Local da Ocorrência (Opcional)", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place)
              ),
              value: _localSelecionado,
              items: _locais.map((local) => DropdownMenuItem(value: local, child: Text(local))).toList(),
              onChanged: (valor) => setState(() => _localSelecionado = valor),
            ),
            const SizedBox(height: 16),
            // -------------------------

            TextField(controller: _tituloController, decoration: const InputDecoration(labelText: "Assunto", border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
            const SizedBox(height: 16),
            TextField(controller: _descricaoController, maxLines: 4, decoration: const InputDecoration(labelText: "Detalhes", border: OutlineInputBorder())),
            const SizedBox(height: 24),
            const Text("Evidência (Foto)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            InkWell(
              onTap: _selecionarImagem,
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
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        Text("Toque para adicionar foto", style: TextStyle(color: Colors.grey))
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
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