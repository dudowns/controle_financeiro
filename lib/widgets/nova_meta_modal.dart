// lib/widgets/nova_meta_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../repositories/meta_repository.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../utils/validators.dart';
import '../utils/formatters.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/gradient_button.dart';

class NovaMetaModal extends StatefulWidget {
  final Function? onSalvo;

  const NovaMetaModal({super.key, this.onSalvo});

  @override
  State<NovaMetaModal> createState() => _NovaMetaModalState();

  static Future<void> show({
    required BuildContext context,
    Function? onSalvo,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: NovaMetaModal(onSalvo: onSalvo),
      ),
    );
  }
}

class _NovaMetaModalState extends State<NovaMetaModal> {
  final MetaRepository _metaRepo = MetaRepository();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorObjetivoController =
      TextEditingController();
  final TextEditingController _valorAtualController = TextEditingController();

  DateTime _dataFim = DateTime.now().add(const Duration(days: 365));
  String _iconeSelecionado = 'flag';
  String _corSelecionada = 'viagem';

  bool _salvando = false;

  final List<Map<String, dynamic>> _icones = const [
    {'valor': 'flag', 'icone': Icons.flag, 'label': 'Geral'},
    {'valor': 'viagem', 'icone': Icons.flight, 'label': 'Viagem'},
    {'valor': 'carro', 'icone': Icons.directions_car, 'label': 'Carro'},
    {'valor': 'casa', 'icone': Icons.home, 'label': 'Casa'},
    {'valor': 'estudo', 'icone': Icons.school, 'label': 'Estudo'},
    {
      'valor': 'investimento',
      'icone': Icons.trending_up,
      'label': 'Investimento'
    },
  ];

  final List<Map<String, dynamic>> _cores = const [
    {'valor': 'viagem', 'cor': Colors.blue, 'label': 'Viagem'},
    {'valor': 'carro', 'cor': Colors.red, 'label': 'Carro'},
    {'valor': 'casa', 'cor': Colors.green, 'label': 'Casa'},
    {'valor': 'estudo', 'cor': Colors.orange, 'label': 'Estudo'},
    {'valor': 'investimento', 'cor': Colors.purple, 'label': 'Investimento'},
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorObjetivoController.dispose();
    _valorAtualController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataFim,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() {
        _dataFim = data;
      });
    }
  }

  double _parseValor(String texto) {
    try {
      return double.parse(texto.replaceAll(',', '.'));
    } catch (e) {
      return 0;
    }
  }

  bool _validarCampos() {
    if (_tituloController.text.isEmpty) {
      _mostrarErro('Digite o título da meta');
      return false;
    }

    if (_valorObjetivoController.text.isEmpty) {
      _mostrarErro('Digite o valor da meta');
      return false;
    }

    final valor = _parseValor(_valorObjetivoController.text);
    if (valor <= 0) {
      _mostrarErro('O valor deve ser maior que zero');
      return false;
    }

    if (valor > 999999999) {
      _mostrarErro('Valor muito alto');
      return false;
    }

    return true;
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _salvarMeta() async {
    if (!_validarCampos()) return;

    setState(() => _salvando = true);

    try {
      final valorObjetivo = _parseValor(_valorObjetivoController.text);
      final valorAtual = _parseValor(_valorAtualController.text);

      final metaId = await _metaRepo.insertMeta({
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'valor_objetivo': valorObjetivo,
        'valor_atual': valorAtual,
        'data_inicio': DateTime.now().toIso8601String(),
        'data_fim': _dataFim.toIso8601String(),
        'icone': _iconeSelecionado,
        'cor': _corSelecionada,
        'concluida': 0,
      });

      if (mounted) {
        if (valorAtual > 0) {
          await _metaRepo.insertDepositoMeta({
            'meta_id': metaId,
            'valor': valorAtual,
            'data_deposito': DateTime.now().toIso8601String(),
            'observacao': 'Depósito inicial',
          });
        }

        widget.onSalvo?.call();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Meta "${_tituloController.text}" criada!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao salvar: $e');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Nova Meta',
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
                // Título
                Text(
                  'Título da Meta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tituloController,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Ex: Comprar um carro',
                    hintStyle: TextStyle(color: AppColors.textHint(context)),
                    prefixIcon: Icon(Icons.title, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Descrição
                Text(
                  'Descrição (opcional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descricaoController,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ex: Quero comprar um carro até o final do ano',
                    hintStyle: TextStyle(color: AppColors.textHint(context)),
                    prefixIcon:
                        Icon(Icons.description, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Valor Objetivo
                Text(
                  'Valor da Meta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _valorObjetivoController,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  keyboardType: TextInputType.number,
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

                // Valor Inicial (opcional)
                Text(
                  'Valor Inicial (opcional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _valorAtualController,
                  style: TextStyle(color: AppColors.textPrimary(context)),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0,00',
                    hintStyle: TextStyle(color: AppColors.textHint(context)),
                    prefixIcon: Icon(Icons.account_balance_wallet,
                        color: AppColors.primary),
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

                // Data Fim
                Text(
                  'Data Limite',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selecionarData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Limite',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_dataFim),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ícone
                Text(
                  'Ícone da Meta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    border: Border.all(color: AppColors.border(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _icones.map((icone) {
                      bool isSelected = _iconeSelecionado == icone['valor'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _iconeSelecionado = icone['valor'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icone['icone'],
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary(context),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                icone['label'],
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary(context),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Cor
                Text(
                  'Cor da Meta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _cores.map((cor) {
                      bool isSelected = _corSelecionada == cor['valor'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _corSelecionada = cor['valor'];
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cor['cor'],
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
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
                      child: _salvando
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : GradientButton(
                              text: 'CRIAR META',
                              icon: Icons.add,
                              onPressed: _salvarMeta,
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
