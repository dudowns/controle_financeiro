// lib/widgets/adicionar_deposito_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/meta_repository.dart';
import '../constants/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/gradient_button.dart';

class AdicionarDepositoModal extends StatefulWidget {
  final int metaId;
  final double valorAtual;
  final double valorObjetivo;
  final Future<void> Function()? onDepositoAdicionado;

  const AdicionarDepositoModal({
    super.key,
    required this.metaId,
    required this.valorAtual,
    required this.valorObjetivo,
    this.onDepositoAdicionado,
  });

  @override
  State<AdicionarDepositoModal> createState() => _AdicionarDepositoModalState();

  static Future<void> show({
    required BuildContext context,
    required int metaId,
    required double valorAtual,
    required double valorObjetivo,
    Future<void> Function()? onDepositoAdicionado,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AdicionarDepositoModal(
          metaId: metaId,
          valorAtual: valorAtual,
          valorObjetivo: valorObjetivo,
          onDepositoAdicionado: onDepositoAdicionado,
        ),
      ),
    );
  }
}

class _AdicionarDepositoModalState extends State<AdicionarDepositoModal> {
  final MetaRepository _metaRepo = MetaRepository();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  double _parseValor(String texto) {
    try {
      return double.parse(texto.replaceAll(',', '.'));
    } catch (e) {
      return 0;
    }
  }

  Future<void> _salvarDeposito() async {
    if (_valorController.text.isEmpty) {
      _mostrarErro('Digite o valor do depósito');
      return;
    }

    final valor = _parseValor(_valorController.text);
    if (valor <= 0) {
      _mostrarErro('O valor deve ser maior que zero');
      return;
    }

    final novoTotal = widget.valorAtual + valor;
    if (novoTotal > widget.valorObjetivo) {
      _mostrarErro(
          'O valor ultrapassa a meta (Máx: ${Formatador.moeda(widget.valorObjetivo - widget.valorAtual)})');
      return;
    }

    setState(() => _carregando = true);

    try {
      await _metaRepo.insertDepositoMeta({
        'meta_id': widget.metaId,
        'valor': valor,
        'data_deposito': DateTime.now().toIso8601String(),
        'observacao': _observacaoController.text,
      });

      final atingiu = (novoTotal >= widget.valorObjetivo);

      if (mounted) {
        if (widget.onDepositoAdicionado != null) {
          await widget.onDepositoAdicionado!();
        }
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(atingiu
                ? '🎉 Parabéns! Meta alcançada!'
                : '✅ Depósito adicionado!'),
            backgroundColor: atingiu ? Colors.green : AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao adicionar: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRIGIDO: .toDouble() para converter num para double
    final double valorRestante = (widget.valorObjetivo - widget.valorAtual)
        .clamp(0, widget.valorObjetivo)
        .toDouble();

    return Column(
      children: [
        // 🔝 CABEÇALHO
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Adicionar Depósito',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 📝 FORMULÁRIO
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info da meta
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso atual:',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          Text(
                            Formatador.moeda(widget.valorAtual),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Falta:',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          Text(
                            Formatador.moeda(
                                valorRestante), // ✅ AGORA É DOUBLE!
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Valor do depósito
                Text(
                  'Valor do depósito',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: '0,00',
                    hintStyle: TextStyle(color: AppColors.textHint(context)),
                    prefixIcon:
                        Icon(Icons.attach_money, color: AppColors.primary),
                    prefixText: 'R\$ ',
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Observação
                Text(
                  'Observação (opcional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _observacaoController,
                  maxLines: 2,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Ex: Depósito mensal, Bônus, etc',
                    hintStyle: TextStyle(color: AppColors.textHint(context)),
                    prefixIcon: Icon(Icons.note, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                              color: AppColors.textSecondary(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _carregando
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : GradientButton(
                              text: 'ADICIONAR',
                              onPressed: _salvarDeposito,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
