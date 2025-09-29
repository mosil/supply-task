import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
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
  String? _selectedTaskType;
  bool _isCustomType = false;
  bool _isDirty = false;

  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _customTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers to track changes
    void setDirty(_) => setState(() => _isDirty = true);
    _nameController.addListener(() => setDirty(null));
    _contentController.addListener(() => setDirty(null));
    _addressController.addListener(() => setDirty(null));
    _contactNameController.addListener(() => setDirty(null));
    _contactInfoController.addListener(() => setDirty(null));
    _contactPhoneController.addListener(() => setDirty(null));
    _customTypeController.addListener(() => setDirty(null));

    if (widget.isEditing) {
      // Edit mode: Pre-fill form with task data
      final task = context.read<TaskProvider>().getTaskById(widget.taskId!);
      if (task != null) {
        _nameController.text = task.name;
        _contentController.text = task.content;
        _addressController.text = task.address;
        _contactNameController.text = task.publisherName;

        const defaultTypes = ['勞力任務', '補給品需求', '發放資源'];
        if (defaultTypes.contains(task.type)) {
          _selectedTaskType = task.type;
        } else {
          _selectedTaskType = '其他';
          _isCustomType = true;
          _customTypeController.text = task.type;
        }
        // Reset dirty flag after initial setup
        WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isDirty = false));
      }
    } else {
      // Create mode: Auto-fill with user's profile data
      final UserProfile? user = context.read<AuthProvider>().user;
      if (user != null) {
        _contactNameController.text = user.displayName;
        _contactInfoController.text = user.contactInfo;
        _contactPhoneController.text = user.phoneNumber;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isDirty = false));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactInfoController.dispose();
    _contactPhoneController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final taskType = _isCustomType ? _customTypeController.text : _selectedTaskType!;
      if (widget.isEditing) {
        final originalTask = context.read<TaskProvider>().getTaskById(widget.taskId!)!;
        final updatedTask = Task(
          id: originalTask.id,
          name: _nameController.text,
          content: _contentController.text,
          address: _addressController.text,
          type: taskType,
          status: originalTask.status,
          publisherName: _contactNameController.text,
          publishedAt: originalTask.publishedAt,
          editedAt: DateTime.now(),
          claimantName: originalTask.claimantName,
          claimedAt: originalTask.claimedAt,
          completedAt: originalTask.completedAt,
          statusChangedAt: originalTask.statusChangedAt,
        );
        context.read<TaskProvider>().updateTask(updatedTask);
        setState(() => _isDirty = false);
        context.go('/task/${updatedTask.id}');
      } else {
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          content: _contentController.text,
          address: _addressController.text,
          type: taskType,
          status: TaskStatus.published,
          publisherName: _contactNameController.text,
          publishedAt: DateTime.now(),
        );
        context.read<TaskProvider>().addTask(newTask);
        setState(() => _isDirty = false);
        context.go('/task/${newTask.id}');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true; // Allow pop if no changes

    final shouldPop = await showConfirmationDialog(
      context: context,
      title: '確認捨棄變更',
      content: const Text('您確定要離開嗎？所有未儲存的變更將會遺失。'),
      confirmButtonText: '確定捨棄',
      onConfirm: () {}, // onConfirm is handled by the dialog's return value
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? '編輯任務' : '發布任務'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (widget.isEditing) {
                  context.go('/task/${widget.taskId}');
                } else {
                  context.go('/');
                }
              }
            },
          ),
          actions: [
            if (widget.isEditing)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: '刪除任務',
                onPressed: () {
                  showConfirmationDialog(
                    context: context,
                    title: '確認刪除任務',
                    content: const Text('您確定要刪除這個任務嗎？此操作無法復原。'),
                    confirmButtonText: '確定刪除',
                    onConfirm: () {
                      // TODO: Implement delete logic
                      context.go('/');
                    },
                  );
                },
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '任務名稱',
                  hintText: '請輸入任務名稱',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: '任務性質',
                  border: OutlineInputBorder(),
                ),
                value: _selectedTaskType,
                items: ['勞力任務', '補給品需求', '發放資源', '其他']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTaskType = value;
                    _isCustomType = value == '其他';
                    _isDirty = true;
                  });
                },
                validator: (value) => (value == null) ? '請選擇任務性質' : null,
              ),
              if (_isCustomType)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _customTypeController,
                    decoration: const InputDecoration(
                      labelText: '自訂任務性質',
                      hintText: '請輸入新的任務性質',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 10,
                    validator: (value) =>
                        (_isCustomType && (value?.isEmpty ?? true)) ? '此欄位為必填' : null,
                  ),
                ),
              const SizedBox(height: 24),
              Text('聯絡資訊', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactNameController,
                decoration: const InputDecoration(
                  labelText: '聯絡人',
                  hintText: '請輸入本次任務的聯絡人',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.isEmpty ?? true) ? '聯絡人為必填' : null,
              ),
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
                decoration: const InputDecoration(
                  labelText: '聯絡電話',
                  hintText: '請輸入聯絡電話',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: const Text('儲存草稿'),
                  onPressed: () {
                    // TODO: Implement save draft
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  child: Text(widget.isEditing ? '更新' : '發布'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      showConfirmationDialog(
                        context: context,
                        title: widget.isEditing ? '確認更新' : '確認發布',
                        content: Text('您確定要${widget.isEditing ? '更新' : '發布'}這個任務嗎？'),
                        confirmButtonText: widget.isEditing ? '確定更新' : '確定發布',
                        onConfirm: _submitForm,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
