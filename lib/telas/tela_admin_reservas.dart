import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatar datas

class TelaAdminReservas extends StatefulWidget {
  const TelaAdminReservas({super.key});

  @override
  State<TelaAdminReservas> createState() => _TelaAdminReservasState();
}

class _TelaAdminReservasState extends State<TelaAdminReservas> {
  
  // Função mestre de aprovação
  void _processarAprovacao(DocumentSnapshot doc) {
    Map<String, dynamic> dados = doc.data() as Map<String, dynamic>;
    String local = dados['local'];
    String id = doc.id;

    // LÓGICA 1: Se for Salão, exige contrato/pagamento
    if (local == 'Salão de Festas') {
      final msgController = TextEditingController(
        text: "Comparecer à adm até ${DateFormat('dd/MM').format(DateTime.now().add(const Duration(days: 2)))} para assinar contrato e pagar taxa."
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Aprovar Salão de Festas"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Instruções para o morador (Ex: Prazo de pagamento):"),
              const SizedBox(height: 10),
              TextField(
                controller: msgController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                await _atualizarReserva(id, 'APROVADO', msgController.text);
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text("ENVIAR APROVAÇÃO"),
            )
          ],
        ),
      );
    } 
    // LÓGICA 2: Se for Churrasqueira, é simples
    else {
      _atualizarReserva(id, 'APROVADO', "Sua reserva da churrasqueira está confirmada! Bom proveito.");
    }
  }

  Future<void> _atualizarReserva(String docId, String status, String mensagem) async {
    await FirebaseFirestore.instance.collection('reservas').doc(docId).update({
      'status': status,
      'resposta_admin': mensagem, // <--- Salvamos a instrução aqui
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestão de Reservas"), backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservas')
            .orderBy('data_reserva_timestamp') // Ordenar por data real
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Nenhuma reserva registrada."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var dados = docs[index].data() as Map<String, dynamic>;
              String status = dados['status'];
              
              // Cores visuais
              Color corStatus = Colors.grey;
              if (status == 'PENDENTE') corStatus = Colors.orange;
              if (status == 'APROVADO') corStatus = Colors.green;
              if (status == 'REJEITADO') corStatus = Colors.red;

              return Card(
                elevation: status == 'PENDENTE' ? 4 : 1,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: status == 'PENDENTE' ? Colors.orange : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(12)
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: corStatus.withOpacity(0.1),
                        child: Icon(
                          dados['local'] == 'Salão de Festas' ? Icons.celebration : Icons.outdoor_grill,
                          color: corStatus
                        ),
                      ),
                      title: Text("${dados['local']} - ${dados['data_reserva']}"),
                      subtitle: Text("${dados['autor_nome']} • ${dados['autor_unidade']}"),
                      trailing: Chip(
                        label: Text(status), 
                        backgroundColor: corStatus.withOpacity(0.2),
                        labelStyle: TextStyle(color: corStatus, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    // Botões de Ação (Só aparecem se estiver Pendente)
                    if (status == 'PENDENTE')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _atualizarReserva(docs[index].id, 'REJEITADO', "Data indisponível ou regras não atendidas."), 
                              child: const Text("Recusar", style: TextStyle(color: Colors.red))
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _processarAprovacao(docs[index]), // <--- Chama a função inteligente
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text("APROVAR"),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}