import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaMinhasReservas extends StatelessWidget {
  const TelaMinhasReservas({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Meus Agendamentos"), backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservas')
            .where('autor_uid', isEqualTo: user!.uid)
            .orderBy('data_reserva_timestamp', descending: true) // Mais recentes primeiro
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             // DICA: Se der erro de índice aqui, clique no link do terminal!
             return const Center(child: Text("Erro ao carregar (Verificar Índice)"));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Você não tem reservas."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var dados = docs[index].data() as Map<String, dynamic>;
              String status = dados['status'];
              String respostaAdmin = dados['resposta_admin'] ?? '';

              Color corCard = Colors.white;
              Color corStatus = Colors.grey;
              IconData icone = Icons.calendar_today;

              if (status == 'PENDENTE') {
                corStatus = Colors.orange;
                icone = Icons.hourglass_empty;
              } else if (status == 'APROVADO') {
                corCard = Colors.green[50]!;
                corStatus = Colors.green;
                icone = Icons.check_circle;
              } else if (status == 'REJEITADO') {
                corCard = Colors.red[50]!;
                corStatus = Colors.red;
                icone = Icons.cancel;
              }

              return Card(
                color: corCard,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(icone, color: corStatus),
                              const SizedBox(width: 8),
                              Text(dados['local'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Chip(
                            label: Text(status),
                            backgroundColor: corStatus,
                            labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Data: ${dados['data_reserva']}", style: const TextStyle(fontSize: 16)),
                      
                      // EXIBE MENSAGEM DO ADMIN SE TIVER (Contrato/Pagamento)
                      if (respostaAdmin.isNotEmpty) ...[
                        const Divider(),
                        const Text("Mensagem da Administração:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(respostaAdmin, style: const TextStyle(fontStyle: FontStyle.italic)),
                      ]
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