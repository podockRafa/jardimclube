import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../segredos.dart'; // <--- NÃO PRECISA DISSO AQUI (O Admin só lê, não sobe fotos)

class TelaAdminAnuncios extends StatelessWidget {
  const TelaAdminAnuncios({super.key});

  Future<void> _decidirAnuncio(String docId, bool aprovado) async {
    await FirebaseFirestore.instance.collection('anuncios').doc(docId).update({
      'status': aprovado ? 'APROVADO' : 'REJEITADO',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moderar Anúncios"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('anuncios')
            .where('status', isEqualTo: 'AGUARDANDO_APROVACAO')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Nenhum anúncio para moderar."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var anuncio = docs[index];
              var dados = anuncio.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CABEÇALHO (Tipo e Valor) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(dados['tipo'] ?? 'VENDA')),
                          Text(dados['valor'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                        ],
                      ),
                      
                      const SizedBox(height: 10),

                      // --- MUDANÇA: MOSTRAR A FOTO (Se existir) ---
                      if (dados['foto_url'] != null && dados['foto_url'].toString().isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(dados['foto_url']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      // --- TÍTULO E DESCRIÇÃO ---
                      Text(dados['titulo'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(dados['descricao'] ?? '', style: const TextStyle(color: Colors.black87)),
                      
                      const SizedBox(height: 12),
                      const Divider(),
                      
                      // --- RODAPÉ (Autor e Botões) ---
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Autor: ${dados['autor_nome']}\nUnidade: ${dados['autor_unidade']}", 
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                          
                          // Botão Rejeitar
                          TextButton(
                            onPressed: () => _decidirAnuncio(anuncio.id, false),
                            child: const Text("REJEITAR", style: TextStyle(color: Colors.red)),
                          ),
                          
                          // Botão Aprovar
                          ElevatedButton(
                            onPressed: () => _decidirAnuncio(anuncio.id, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text("APROVAR"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}