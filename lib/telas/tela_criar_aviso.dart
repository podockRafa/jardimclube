import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaCriarAviso extends StatefulWidget {
  const TelaCriarAviso({super.key});

  @override
  State<TelaCriarAviso> createState() => _TelaCriarAvisoState();
}

class _TelaCriarAvisoState extends State<TelaCriarAviso> {
  final _tituloController = TextEditingController();
  final _mensagemController = TextEditingController();
  bool _urgente = false;
  bool _enviando = false;

  Future<void> _enviarAviso() async {
    if (_tituloController.text.isEmpty || _mensagemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha título e mensagem.")));
      return;
    }

    setState(() => _enviando = true);

    try {
      String nomeAutor = "Administração"; // Pode pegar do user se quiser

      await FirebaseFirestore.instance.collection('avisos').add({
        'titulo': _tituloController.text,
        'mensagem': _mensagemController.text,
        'urgente': _urgente, // Se for urgente, o ícone muda
        'data_envio': FieldValue.serverTimestamp(),
        'autor': nomeAutor,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aviso enviado a todos!"), backgroundColor: Colors.green));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Comunicado"), backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: "Título (Ex: Manutenção da Piscina)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mensagemController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: "Mensagem detalhada...", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Marcar como Importante/Urgente?"),
              subtitle: const Text("Destaque vermelho no histórico"),
              value: _urgente,
              activeColor: Colors.red,
              onChanged: (val) => setState(() => _urgente = val),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarAviso,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
                child: _enviando ? const CircularProgressIndicator(color: Colors.white) : const Text("ENVIAR COMUNICADO"),
              ),
            )
          ],
        ),
      ),
    );
  }
}