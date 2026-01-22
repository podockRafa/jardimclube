import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class TelaMinhasMensagens extends StatefulWidget {
  const TelaMinhasMensagens({super.key});

  @override
  State<TelaMinhasMensagens> createState() => _TelaMinhasMensagensState();
}

class _TelaMinhasMensagensState extends State<TelaMinhasMensagens> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Função para abrir o chat (reutiliza a lógica visual, mas focada no comprador)
  void _abrirChat(String docId, String tituloAnuncio) {
    final msgCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o teclado empurre o chat
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 500, // Altura fixa para o chat
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[800],
                  width: double.infinity,
                  child: Text("Chat: $tituloAnuncio", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                
                // LISTA DE MENSAGENS
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classificados')
                        .doc(docId)
                        .collection('mensagens')
                        .orderBy('data_envio', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      var msgs = snapshot.data!.docs;
                      if (msgs.isEmpty) return const Center(child: Text("Nenhuma conversa iniciada."));

                      return ListView.builder(
                        reverse: true, // Mensagens novas embaixo
                        itemCount: msgs.length,
                        itemBuilder: (context, index) {
                          var msg = msgs[index];
                          bool souEu = msg['remetente_uid'] == _user!.uid;

                          return Align(
                            alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: souEu ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    souEu ? "Você" : msg['remetente_nome'],
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: souEu ? Colors.blue[900] : Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(msg['mensagem'], style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // CAMPO DE RESPOSTA
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgCtrl,
                          decoration: const InputDecoration(hintText: "Escreva sua resposta...", border: OutlineInputBorder()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          if (msgCtrl.text.isEmpty) return;
                          
                          var userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
                          String meuNome = userDoc.data()?['nome'] ?? 'Comprador';
                          
                          await FirebaseFirestore.instance.collection('classificados').doc(docId).collection('mensagens').add({
                            'mensagem': msgCtrl.text,
                            'remetente_uid': _user!.uid,
                            'remetente_nome': meuNome,
                            'data_envio': FieldValue.serverTimestamp(),
                            'tipo': 'PERGUNTA' // Mantemos o padrão
                          });
                          msgCtrl.clear();
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Minhas Mensagens"), backgroundColor: Colors.blue),
      body: StreamBuilder<QuerySnapshot>(
        // USANDO COLLECTION GROUP: Busca em todas as subcoleções 'mensagens' onde EU sou o remetente
        // Isso encontra todos os anúncios onde eu mandei mensagem
        stream: FirebaseFirestore.instance.collectionGroup('mensagens')
            .where('remetente_uid', isEqualTo: _user!.uid)
            .orderBy('data_envio', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             // Dica: Se der erro, é porque precisa criar o índice no link que aparece no console
             return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Criando índices... (Verifique o console se persistir)")));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filtra para pegar apenas 1 item por anúncio (para não repetir na lista)
          var msgs = snapshot.data!.docs;
          Set<String> anunciosIds = {};
          
          for (var msg in msgs) {
            // O pai da mensagem é a coleção 'mensagens', o pai da coleção é o documento do Anúncio
            anunciosIds.add(msg.reference.parent.parent!.id);
          }

          if (anunciosIds.isEmpty) {
            return const Center(child: Text("Você ainda não iniciou nenhuma conversa."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: anunciosIds.length,
            itemBuilder: (context, index) {
              String idAnuncio = anunciosIds.elementAt(index);

              // Agora buscamos os dados do Anúncio para mostrar o título
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('classificados').doc(idAnuncio).get(),
                builder: (context, anuncioSnap) {
                  if (!anuncioSnap.hasData) return const SizedBox.shrink();
                  var dadosAnuncio = anuncioSnap.data!.data() as Map<String, dynamic>?;
                  
                  if (dadosAnuncio == null) return const SizedBox.shrink(); // Anúncio pode ter sido deletado

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.chat, color: Colors.white)),
                      title: Text(dadosAnuncio['titulo'] ?? 'Anúncio'),
                      subtitle: const Text("Toque para ver a conversa"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _abrirChat(idAnuncio, dadosAnuncio['titulo']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}