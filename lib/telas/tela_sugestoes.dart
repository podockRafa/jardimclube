import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaSugestoes extends StatefulWidget {
  const TelaSugestoes({super.key});

  @override
  State<TelaSugestoes> createState() => _TelaSugestoesState();
}

class _TelaSugestoesState extends State<TelaSugestoes> {
  final _textoController = TextEditingController();
  String _tipoSelecionado = 'Sugestão'; // Padrão
  bool _enviando = false;

  final List<String> _tipos = ['Sugestão', 'Reclamação', 'Elogio', 'Denúncia'];

  Future<void> _enviarMensagem() async {
    if (_textoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Escreva algo antes de enviar.")));
      return;
    }

    setState(() => _enviando = true);

    try {
      User? usuario = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(usuario!.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('caixa_sugestoes').add({
        'tipo': _tipoSelecionado,
        'texto': _textoController.text.trim(),
        'autor_uid': usuario.uid,
        'autor_nome': userData['nome'],
        'autor_unidade': "Bloco ${userData['bloco']} - Apt ${userData['unidade']}",
        'data_envio': FieldValue.serverTimestamp(),
        'lido': false, // Para o admin marcar como lido depois
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mensagem enviada à administração!"), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text("Fale com o Síndico"), backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mail_outline, size: 80, color: Color(0xFF1B4D3E)),
            const SizedBox(height: 20),
            const Text(
              "Sua opinião é fundamental para melhorarmos nosso condomínio.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            DropdownButtonFormField<String>(
              value: _tipoSelecionado,
              decoration: const InputDecoration(labelText: "Do que se trata?", border: OutlineInputBorder()),
              items: _tipos.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
              onChanged: (val) => setState(() => _tipoSelecionado = val!),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _textoController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Escreva sua mensagem aqui...",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: _enviando ? const CircularProgressIndicator(color: Colors.white) : const Text("ENVIAR MENSAGEM"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
                onPressed: _enviando ? null : _enviarMensagem,
              ),
            )
          ],
        ),
      ),
    );
  }
}