// lib/screens/backup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/backup_service_plus.dart';
import '../utils/date_helper.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../widgets/gradient_button.dart';
import '../widgets/modern_card.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupServicePlus _backupService = BackupServicePlus();
  List<File> backups = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarBackups();
  }

  Future<void> _carregarBackups() async {
    setState(() => carregando = true);
    backups = await _backupService.listarBackups();
    setState(() => carregando = false);
  }

  // CORRIGIDO: Usar data do nome do arquivo quando possível
  String _formatarData(File file) {
    final nome = file.path.split('\\').last;

    // Tentar extrair data do nome do arquivo (mais preciso)
    final dataDoNome = DateHelper.dataDoNomeArquivo(nome);
    if (dataDoNome != null) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dataDoNome);
    }

    // Fallback: usar data de modificação (convertendo UTC para Brasília)
    final stat = file.statSync();
    return DateHelper.formatarDataBrasil(stat.modified, comHora: true);
  }

  String _formatarTamanho(File file) {
    final bytes = file.statSync().size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup e Restauração'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarBackups,
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GradientButton(
                    text: 'FAZER BACKUP AGORA',
                    icon: Icons.backup,
                    onPressed: () async {
                      final caminho =
                          await _backupService.salvarBackupEmArquivo();
                      if (caminho != null && context.mounted) {
                        await _carregarBackups();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Backup realizado com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ),
                Expanded(
                  child: backups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum backup encontrado',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clique em "FAZER BACKUP AGORA" para começar',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: backups.length,
                          itemBuilder: (context, index) {
                            final backup = backups[index];
                            final nome = backup.path.split('\\').last;

                            return ModernCard(
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.backup,
                                      color: AppColors.primaryPurple),
                                ),
                                title: Text(
                                  nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // AGORA MOSTRA A DATA CORRETA (BRASÍLIA)!
                                    Text('📅 ${_formatarData(backup)}'),
                                    Text('💾 ${_formatarTamanho(backup)}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.restore,
                                          color: Colors.green),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title:
                                                const Text('Restaurar Backup'),
                                            content: Text(
                                                'Deseja restaurar o backup $nome? Os dados atuais serão substituídos.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  final sucesso =
                                                      await _backupService
                                                          .restaurarBackup(
                                                              backup.path,
                                                              limparAntes:
                                                                  true);
                                                  if (sucesso &&
                                                      context.mounted) {
                                                    await _carregarBackups();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            '✅ Backup restaurado!'),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                ),
                                                child: const Text('Restaurar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Excluir Backup'),
                                            content: Text(
                                                'Deseja excluir o backup $nome?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await backup.delete();
                                                  if (context.mounted) {
                                                    Navigator.pop(context);
                                                    await _carregarBackups();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            '🗑️ Backup excluído'),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
