// lib/screens/editar_conta_fixa_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conta_fixa_model.dart';
import '../utils/currency_formatter.dart';

class EditarContaFixaDialog extends StatefulWidget {
  final ContaFixa conta;

  const EditarContaFixaDialog({super.key, required this.conta});

  @override
  State<EditarContaFixaDialog> createState() => _EditarContaFixaDialogState();
}

class _EditarContaFixaDialogState extends State<EditarContaFixaDialog> {
  late final TextEditingController _nomeController;
  late final TextEditingController _categoriaController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.conta.nome);
    _categoriaController =
        TextEditingController(text: widget.conta.categoria ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Conta Fixa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Conta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoriaController,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoLinha('Valor Total',
                      CurrencyFormatter.format(widget.conta.valorTotal)),
                  _buildInfoLinha(
                      'Total Parcelas', '${widget.conta.totalParcelas}'),
                  _buildInfoLinha(
                      'Parcelas Pagas', '${widget.conta.parcelasPagas}'),
                  _buildInfoLinha('Saldo Restante',
                      CurrencyFormatter.format(widget.conta.saldoRestante)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final contaAtualizada = ContaFixa(
              id: widget.conta.id,
              nome: _nomeController.text,
              valorTotal: widget.conta.valorTotal,
              totalParcelas: widget.conta.totalParcelas,
              dataInicio: widget.conta.dataInicio,
              categoria: _categoriaController.text.isNotEmpty
                  ? _categoriaController.text
                  : null,
              parcelas: widget.conta.parcelas,
            );
            Navigator.pop(context, contaAtualizada);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A1B9A),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _buildInfoLinha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }
}
