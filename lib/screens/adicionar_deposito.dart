// lib/screens/adicionar_deposito.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
// Adicionar no início:
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../utils/validators.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/date_picker_field.dart';

class AdicionarDepositoScreen extends StatefulWidget {
  final int metaId;
  final double valorAtual;
  final double valorObjetivo;

  const AdicionarDepositoScreen({
    super.key,
    required this.metaId,
    required this.valorAtual,
    required this.valorObjetivo,
  });

  @override
  State<AdicionarDepositoScreen> createState() =>
      _AdicionarDepositoScreenState();
}

class _AdicionarDepositoScreenState extends State<AdicionarDepositoScreen> {
  final DBHelper db = DBHelper();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  DateTime _dataDeposito = DateTime.now();

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataDeposito,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() {
        _dataDeposito = data;
      });
    }
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(valor);
  }

  double _parseValor(String texto) {
    try {
      return double.parse(texto.replaceAll(',', '.'));
    } catch (e) {
      return 0;
    }
  }

  Future<void> _salvarDeposito() async {
    try {
      final valor = _parseValor(_valorController.text);
      if (valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite um valor válido!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 🔥 AGORA CRIA O DEPÓSITO NA TABELA CORRETA!
      await db.insertDepositoMeta({
        'meta_id': widget.metaId,
        'valor': valor,
        'data_deposito': _dataDeposito.toIso8601String(),
        'observacao': _observacaoController.text.isNotEmpty
            ? _observacaoController.text
            : null,
      });

      // Atualiza o valor atual da meta
      final novoValor = widget.valorAtual + valor;
      await db.atualizarProgressoMeta(widget.metaId, novoValor);

      // Verifica se a meta foi concluída
      if (novoValor >= widget.valorObjetivo) {
        await db.concluirMeta(widget.metaId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Parabéns! Meta alcançada!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Depósito de ${_formatarValor(valor)} adicionado!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double valorDeposito = 0;
    try {
      valorDeposito = double.parse(_valorController.text.replaceAll(',', '.'));
    } catch (e) {
      valorDeposito = 0;
    }

    double totalAposDeposito = widget.valorAtual + valorDeposito;
    bool vaiUltrapassar = totalAposDeposito > widget.valorObjetivo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Depósito'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de resumo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SITUAÇÃO ATUAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatarValor(widget.valorAtual),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Acumulado',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatarValor(widget.valorObjetivo),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Meta',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (widget.valorAtual / widget.valorObjetivo)
                        .clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formulário
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados do Depósito',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Valor do depósito
                  TextField(
                    controller: _valorController,
                    decoration: InputDecoration(
                      labelText: 'Valor do Depósito',
                      hintText: '0,00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.attach_money,
                          color: Color(0xFF6A1B9A)),
                      prefixText: 'R\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Data do depósito
                  InkWell(
                    onTap: _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF6A1B9A)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data do Depósito',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_dataDeposito),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down,
                              color: Color(0xFF6A1B9A)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Observação (opcional)
                  TextField(
                    controller: _observacaoController,
                    decoration: InputDecoration(
                      labelText: 'Observação (opcional)',
                      hintText: 'Ex: Depósito mensal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon:
                          const Icon(Icons.note, color: Color(0xFF6A1B9A)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Preview após depósito
            if (_valorController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: vaiUltrapassar
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: vaiUltrapassar ? Colors.orange : Colors.green,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Após este depósito:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatarValor(totalAposDeposito),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                vaiUltrapassar ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (vaiUltrapassar) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Atenção: Este depósito ultrapassará o valor da meta!',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF6A1B9A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _valorController.text.isEmpty ? null : _salvarDeposito,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Adicionar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }
}
