import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../utils/validators.dart';
import '../utils/mask_formatters.dart';
import '../utils/currency_formatter.dart';

class EditarTransacaoScreen extends StatefulWidget {
  final Map<String, dynamic> lancamento;

  const EditarTransacaoScreen({Key? key, required this.lancamento})
      : super(key: key);

  @override
  State<EditarTransacaoScreen> createState() => _EditarTransacaoScreenState();
}

class _EditarTransacaoScreenState extends State<EditarTransacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();

  late String _tipoSelecionado;
  late String _categoriaSelecionada;
  late DateTime _dataSelecionada;

  final List<String> _categoriasReceita = [
    'Renda Extra',
    'Salário',
    'Investimentos',
    'Outros',
  ];

  final List<String> _categoriasGasto = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Investimentos',
    'Cuidados Pessoais',
    'Empréstimo',
    'Outros',
  ];

  List<String> get _categoriasAtuais {
    return _tipoSelecionado == 'receita'
        ? _categoriasReceita
        : _categoriasGasto;
  }

  @override
  void initState() {
    super.initState();

    // Carregar dados do lançamento
    _tipoSelecionado = widget.lancamento['tipo'] ?? 'gasto';
    _categoriaSelecionada = widget.lancamento['categoria'] ?? 'Outros';
    _dataSelecionada = DateTime.parse(widget.lancamento['data']);

    _descricaoController.text = widget.lancamento['descricao'] ?? '';
    _valorController.text =
        widget.lancamento['valor'].toStringAsFixed(2).replaceAll('.', ',');
    _observacaoController.text = widget.lancamento['observacao'] ?? '';
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // 🔥 VALIDAÇÃO DO VALOR
  bool _validarValor(String valorStr) {
    if (valorStr.isEmpty) {
      _mostrarErro('Digite um valor');
      return false;
    }

    valorStr = valorStr.trim().replaceAll(',', '.');

    if (valorStr == '+' || valorStr == '-' || valorStr == '.') {
      _mostrarErro('Valor inválido');
      return false;
    }

    final valor = double.tryParse(valorStr);

    if (valor == null) {
      _mostrarErro('Digite um número válido');
      return false;
    }

    if (valor <= 0) {
      _mostrarErro('O valor deve ser maior que zero');
      return false;
    }

    return true;
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validarValor(_valorController.text)) return;

    final valorBruto = _valorController.text.trim().replaceAll(',', '.');
    final valor = double.parse(valorBruto);

    final lancamentoAtualizado = {
      'id': widget.lancamento['id'],
      'descricao': _descricaoController.text,
      'tipo': _tipoSelecionado,
      'categoria': _categoriaSelecionada,
      'valor': valor,
      'data': _dataSelecionada.toIso8601String(),
      'observacao': _observacaoController.text.isNotEmpty
          ? _observacaoController.text
          : null,
    };

    try {
      final db = DBHelper();
      await db.updateLancamento(lancamentoAtualizado);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lançamento atualizado!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao atualizar: $e');
    }
  }

  Future<void> _deletar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Deseja realmente excluir este lançamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final db = DBHelper();
        await db.deleteLancamento(widget.lancamento['id']);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lançamento excluído!'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        _mostrarErro('Erro ao excluir: $e');
      }
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Lançamento'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deletar,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TIPO
              const Text('Tipo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildTipoButton(
                          'Gasto', Icons.arrow_downward, Colors.red, 'gasto')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildTipoButton('Receita', Icons.arrow_upward,
                          Colors.green, 'receita')),
                ],
              ),

              const SizedBox(height: 20),

              // DESCRIÇÃO
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite uma descrição';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // VALOR
              TextFormField(
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[,.]?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Ex: 10,50',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite um valor';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // CATEGORIA
              DropdownButtonFormField<String>(
                initialValue: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categoriasAtuais.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _categoriaSelecionada = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // DATA
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_dataSelecionada.day.toString().padLeft(2, '0')}/'
                        '${_dataSelecionada.month.toString().padLeft(2, '0')}/'
                        '${_dataSelecionada.year}',
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // OBSERVAÇÃO
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              // BOTÕES
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('SALVAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoButton(
      String texto, IconData icone, Color cor, String tipo) {
    final isSelecionado = _tipoSelecionado == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoSelecionado = tipo;
          _categoriaSelecionada = _categoriasAtuais.first;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelecionado ? cor.withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isSelecionado ? cor : Colors.grey.shade300,
            width: isSelecionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: isSelecionado ? cor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(
                color: isSelecionado ? cor : Colors.grey.shade700,
                fontWeight: isSelecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
