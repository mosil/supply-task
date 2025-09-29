import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/task_type.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/task_type_provider.dart';
import '../widgets/shared/confirmation_dialog.dart';

class CreateEditTaskPage extends StatefulWidget {
  final String? taskId;

  const CreateEditTaskPage({super.key, this.taskId});

  bool get isEditing => taskId != null;

  @override
  State<CreateEditTaskPage> createState() => _CreateEditTaskPageState();
}

class _CreateEditTaskPageState extends State<CreateEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  Task? _initialTask;
  String? _selectedTaskTypeId;
  bool _isCustomType = false;
  bool _isDirty = false;

  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _customTypeFocusNode = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    void setDirty() => setState(() => _isDirty = true);
    _nameController.addListener(setDirty);
    _contentController.addListener(setDirty);
    _addressController.addListener(setDirty);
    _contactInfoController.addListener(setDirty);
    _contactPhoneController.addListener(setDirty);
    _customTypeController.addListener(setDirty);

    // Use a post-frame callback to access providers safely in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final taskTypeProvider = context.read<TaskTypeProvider>();

      if (widget.isEditing) {
        setState(() => _isLoading = true);
        final task = context.read<TaskProvider>().getTaskById(widget.taskId!);
        if (task != null) {
          _initialTask = task;
          _nameController.text = task.name;
          _contentController.text = task.content;
          _addressController.text = task.address;
          _contactInfoController.text = task.contactInfo;
          _contactPhoneController.text = task.contactPhone;
          _selectedTaskTypeId = task.typeId;
        }
        setState(() => _isLoading = false);
      } else {
        final user = context.read<AuthProvider>().user;
        if (user != null) {
          _contactInfoController.text = user.contactInfo;
          _contactPhoneController.text = user.phoneNumber;
        }
      }

      // Reset dirty flag after initial setup
      setState(() => _isDirty = false);
    });
  }

  Future<void> _onWillPop() async {
    if (!_isDirty) {
      if (mounted) {
        context.go(widget.isEditing ? '/task/${widget.taskId}' : '/');
      }
      return;
    }

    final bool shouldPop = await showConfirmationDialog(
          context: context,
          title: '確認捨棄變更',
          content: const Text('您確定要離開嗎？所有未儲存的變更將會遺失。'),
          confirmButtonText: '確定捨棄',
          onConfirm: () {},
        ) ??
        false;

    if (shouldPop && mounted) {
      context.go(widget.isEditing ? '/task/${widget.taskId}' : '/');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _addressController.dispose();
    _contactInfoController.dispose();
    _contactPhoneController.dispose();
    _customTypeController.dispose();
    _customTypeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTask({required bool isDraft}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final taskProvider = context.read<TaskProvider>();
    final authProvider = context.read<AuthProvider>();
    final taskTypeProvider = context.read<TaskTypeProvider>();
    final currentUser = authProvider.user!;

    try {
      String finalTypeId;
      if (_isCustomType) {
        finalTypeId = await taskTypeProvider.getOrCreateTaskTypeId(_customTypeController.text);
      } else {
        finalTypeId = _selectedTaskTypeId!;
      }

      final TaskStatus newStatus = isDraft ? TaskStatus.draft : TaskStatus.published;

      if (widget.isEditing) {
        final originalTask = _initialTask!;
        final updatedTask = Task(
          id: originalTask.id,
          name: _nameController.text,
          content: _contentController.text,
          address: _addressController.text,
          typeId: finalTypeId,
          status: newStatus,
          publisherId: originalTask.publisherId,
          contactInfo: _contactInfoController.text,
          contactPhone: _contactPhoneController.text,
          publishedAt: originalTask.publishedAt,
          editedAt: DateTime.now(),
          claimantId: originalTask.claimantId,
          claimedAt: originalTask.claimedAt,
          completedAt: originalTask.completedAt,
          statusChangedAt: originalTask.status != newStatus ? DateTime.now() : originalTask.statusChangedAt,
        );
        await taskProvider.updateTask(updatedTask);
        if (mounted) context.go('/task/${updatedTask.id}');
      } else {
        final newTask = Task(
          id: '', // Firestore will generate
          name: _nameController.text,
          content: _contentController.text,
          address: _addressController.text,
          typeId: finalTypeId,
          status: newStatus,
          publisherId: currentUser.uid,
          contactInfo: _contactInfoController.text,
          contactPhone: _contactPhoneController.text,
          publishedAt: DateTime.now(),
          claimantId: null,
        );
        final docRef = await taskProvider.addTask(newTask);
        if (mounted) context.go('/task/${docRef.id}');
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存任務失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteTask() {
    showConfirmationDialog(
      context: context,
      title: '確認刪除任務',
      content: const Text('您確定要刪除這個任務嗎？此操作無法復原。'),
      confirmButtonText: '確定刪除',
      onConfirm: () async {
        await context.read<TaskProvider>().deleteTask(widget.taskId!);
        if (mounted) context.go('/');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskTypeProvider = context.watch<TaskTypeProvider>();

    return PopScope(
      canPop: false, // Always intercept pop attempts
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? '編輯任務' : '發布任務'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onWillPop),
          actions: [
            if (widget.isEditing)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: '刪除任務',
                onPressed: _deleteTask,
              ),
          ],
        ),
        body: _isLoading || taskTypeProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '任務名稱', hintText: '請輸入任務名稱', border: OutlineInputBorder()),
                      maxLength: 30,
                      validator: (value) => (value?.isEmpty ?? true) ? '任務名稱為必填' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '任務內容',
                        hintText: '請輸入本次任務的需求',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      maxLength: 500,
                      validator: (value) => (value?.isEmpty ?? true) ? '任務內容為必填' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: '地點',
                        hintText: '請輸入本次任務的地點',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: '任務性質', border: OutlineInputBorder()),
                      value: _selectedTaskTypeId,
                      hint: const Text('請選擇'),
                      items: [
                        ...taskTypeProvider.taskTypes.map((TaskType type) {
                          return DropdownMenuItem<String>(
                            value: type.id,
                            child: Text(type.name),
                          );
                        }),
                        const DropdownMenuItem<String>(
                          value: 'other',
                          child: Text('其他...'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _isDirty = true;
                          if (value == 'other') {
                            _isCustomType = true;
                            _selectedTaskTypeId = null;
                            _customTypeFocusNode.requestFocus();
                          } else {
                            _isCustomType = false;
                            _selectedTaskTypeId = value;
                          }
                        });
                      },
                      validator: (value) {
                        if (!_isCustomType && value == null) {
                          return '請選擇任務性質';
                        }
                        return null;
                      },
                    ),
                    if (_isCustomType)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          controller: _customTypeController,
                          focusNode: _customTypeFocusNode,
                          decoration: const InputDecoration(
                            labelText: '自訂任務性質',
                            hintText: '請輸入新的任務性質',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 10,
                          validator: (value) => (_isCustomType && (value?.isEmpty ?? true)) ? '此欄位為必填' : null,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text('聯絡資訊', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactInfoController,
                      decoration: const InputDecoration(
                        labelText: '聯絡資訊',
                        hintText: '請輸入聯絡電話外的資訊',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(labelText: '聯絡電話', hintText: '請輸入聯絡電話'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]+'))],
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: Padding(padding: const EdgeInsets.all(16.0), child: _buildBottomButtons()),
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (widget.isEditing) {
      // We are in edit mode
      if (_initialTask?.status == TaskStatus.draft) {
        // Editing a draft
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton(child: const Text('更新草稿'), onPressed: () => _saveTask(isDraft: true)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(child: const Text('發布'), onPressed: () => _saveTask(isDraft: false)),
            ),
          ],
        );
      } else {
        // Editing a published/other status task
        return ElevatedButton(child: const Text('更新任務'), onPressed: () => _saveTask(isDraft: false));
      }
    } else {
      // We are creating a new task
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: OutlinedButton(child: const Text('儲存草稿'), onPressed: () => _saveTask(isDraft: true)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(child: const Text('發布'), onPressed: () => _saveTask(isDraft: false)),
          ),
        ],
      );
    }
  }
}
