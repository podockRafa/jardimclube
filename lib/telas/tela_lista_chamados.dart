import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatar a data (adicione intl no pubspec se não tiver)

class TelaListaChamados extends StatelessWidget {
  const TelaListaChamados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Síndico"),
        backgroundColor: Colors.blueGrey,
      ),
      // StreamBuilder: O ouvido que fica escutando o banco de dados
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('ocorrencias')
            .orderBy('data_abertura', descending: true) // Mais recentes primeiro
            .snapshots(),
        builder: (context, snapshot) {
          
          // 1. Tratamento de erros e carregamento
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar dados :("));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Se não tiver nenhum chamado
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhuma ocorrência registrada."));
          }

          // 3. Monta a lista
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // Pegamos os dados do documento
              var doc = snapshot.data!.docs[index];
              var dados = doc.data() as Map<String, dynamic>;

              // Formatando a data (ex: 20/01/2026 15:30)
              String dataFormatada = "Data desconhecida";
              if (dados['data_abertura'] != null) {
                Timestamp t = dados['data_abertura'];
                dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(t.toDate());
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 3,
                child: Column(
                  children: [
                    // --- AQUI ESTÁ A MÁGICA DA FOTO ---
                    if (dados['foto_url'] != null && dados['foto_url'] != "")
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Image.network(
                          dados['foto_url'], // O link do Cloudinary!
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                          },
                        ),
                      ),
                    
                    // --- DADOS DO TEXTO ---
                    ListTile(
                      title: Text(dados['titulo'] ?? "Sem título", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dados['descricao'] ?? ""),
                          const SizedBox(height: 5),
                          Text("Por: ${dados['autor_nome']} em $dataFormatada", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      trailing: _buildStatusChip(dados['status']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Uma funçãozinha visual para colorir o status
  Widget _buildStatusChip(String? status) {
    Color cor;
    String texto = status ?? "ABERTO";
    
    switch (texto.toUpperCase()) {
      case 'CONCLUIDO':
        cor = Colors.green;
        break;
      case 'EM_ANDAMENTO':
        cor = Colors.orange;
        break;
      default:
        cor = Colors.red;
    }

    return Chip(
      label: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: cor,
      padding: EdgeInsets.zero,
    );
  }
}