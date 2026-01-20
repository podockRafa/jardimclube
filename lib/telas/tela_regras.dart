import 'package:flutter/material.dart';

class TelaRegras extends StatelessWidget {
  const TelaRegras({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Regras do Condomínio"),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _itemRegra(Icons.volume_off, "Lei do Silêncio", "Proibido barulho excessivo após as 22h."),
          _itemRegra(Icons.pool, "Área da Piscina", "Não é permitido vidros na área da piscina. Horário até as 20h."),
          _itemRegra(Icons.pets, "Animais de Estimação", "Obrigatório uso de coleira nas áreas comuns. Limpe a sujeira do seu pet."),
          _itemRegra(Icons.directions_car, "Estacionamento", "Respeite sua vaga. Velocidade máxima de 10km/h na garagem."),
          _itemRegra(Icons.delete, "Lixo", "O lixo deve ser descartado nas lixeiras do andar térreo, devidamente ensacado."),
          _itemRegra(Icons.build, "Obras e Reformas", "Permitidas apenas de segunda a sexta, das 8h às 17h."),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.yellow[100],
            child: const Text(
              "Nota: O desrespeito às regras está sujeito a multa conforme convenção do condomínio.",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.brown),
            ),
          )
        ],
      ),
    );
  }

  Widget _itemRegra(IconData icone, String titulo, String descricao) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1B4D3E).withOpacity(0.1),
          child: Icon(icone, color: const Color(0xFF1B4D3E)),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descricao),
      ),
    );
  }
}