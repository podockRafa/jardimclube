import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter/foundation.dart';

// --- IMPORTANTE: Importando o cofre de segredos ---
import '../segredos.dart'; 

class TelaCriarAnuncio extends StatefulWidget {
  const TelaCriarAnuncio({super.key});

  @override
  State<TelaCriarAnuncio> createState() => _TelaCriarAnuncioState();
}

class _TelaCriarAnuncioState extends State<TelaCriarAnuncio> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  
  String _tipoSelecionado = 'VENDA'; 
  bool _enviando = false;
  XFile? _imagemSelecionada; 

  // --- FUNÇÃO 1: TIRAR FOTO ---
  Future<void> _tirarFoto() async {
    final ImagePicker picker = ImagePicker();
    // Usa 'gallery' para permitir pegar da galeria ou 'camera' para tirar foto na hora
    // Vamos deixar o usuário escolher seria o ideal, mas para simplificar vamos de Camera ou Galeria?
    // Vou colocar GALERIA como padrão aqui pois geralmente anúncio a pessoa já tem a foto.
    // Se quiser mudar para Camera, troque ImageSource.gallery por ImageSource.camera
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    
    if (imagem != null) {
      setState(() {
        _imagemSelecionada = imagem;
      });
    }
  }

  // --- FUNÇÃO 2: UPLOAD SEGURO 🔒 ---
  Future<String?> _uploadImagem() async {
    if (_imagemSelecionada == null) return null;

    try {
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
      if (kDebugMode) {
        print("Erro no upload Cloudinary: $e");
      }
      return null;
    }
  }

  // --- FUNÇÃO 3: SALVAR ANÚNCIO ---
  Future<void> _enviarAnuncio() async {
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("O título é obrigatório!")));
      return;
    }

    setState(() => _enviando = true);

    try {
      User? usuario = FirebaseAuth.instance.currentUser;
      
      // 1. Sobe a foto (se tiver)
      String? urlFoto = await _uploadImagem();

      // 2. Pega dados do usuário
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(usuario!.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // 3. Salva no banco
      await FirebaseFirestore.instance.collection('anuncios').add({
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'valor': _valorController.text, 
        'tipo': _tipoSelecionado, 
        'autor_uid': usuario.uid,
        'autor_nome': userData['nome'] ?? 'Vizinho',
        'autor_unidade': "Bloco ${userData['bloco']} - Apt ${userData['unidade']}",
        'data_criacao': FieldValue.serverTimestamp(),
        'status': 'AGUARDANDO_APROVACAO',
        'foto_url': urlFoto, // <--- Link da foto aqui
      });

      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anúncio enviado para aprovação!"), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text("Criar Anúncio"), backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("O que você quer divulgar?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _radioOpcao("Vender Algo", "VENDA")),
                Expanded(child: _radioOpcao("Oferecer Serviço", "SERVICO")),
              ],
            ),
            const SizedBox(height: 16),
            
            // --- CAMPO DE FOTO ---
            const Text("Foto do Produto (Opcional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _tirarFoto,
              child: Container(
                height: 180,
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
            const SizedBox(height: 20),
            // ---------------------

            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: "Título (Ex: Bicicleta / Aulas de Inglês)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _valorController,
              keyboardType: TextInputType.text, // Mudei para text para aceitar "A combinar"
              decoration: const InputDecoration(labelText: "Valor (Ex: R\$ 150,00 ou 'A Combinar')", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Descrição Detalhada", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarAnuncio,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
                child: _enviando ? const CircularProgressIndicator(color: Colors.white) : const Text("ENVIAR ANÚNCIO"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioOpcao(String titulo, String valor) {
    return RadioListTile(
      title: Text(titulo, style: const TextStyle(fontSize: 14)),
      value: valor,
      groupValue: _tipoSelecionado,
      activeColor: const Color(0xFF1B4D3E),
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _tipoSelecionado = v.toString()),
    );
  }
}