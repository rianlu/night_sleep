import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/data/datasources/database_helper.dart';
import 'package:night_sleep/data/models/category_item.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategoryItem> _categories = [];
  bool _isLoading = true;
  String? _editingId;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.readAllCategories();
    if (mounted) {
      setState(() {
        categories.sort((a, b) {
          if (a.name == "默认") return -1;
          if (b.name == "默认") return 1;
          return a.sortOrder.compareTo(b.sortOrder);
        });
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveOrder() async {
    await DatabaseHelper.instance.updateCategoryOrder(_categories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProMaxColors.stitchFluidBg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ProMaxColors.stitchFluidPrimary))
          : _buildBody(),
      floatingActionButton: _buildAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ProMaxColors.stitchFluidBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "编辑分类",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "完成",
            style: TextStyle(color: ProMaxColors.stitchFluidPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
      shape: const Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            "长按拖动排序，点击铅笔编辑名称",
            style: TextStyle(color: ProMaxColors.stitchFluidTextMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            itemCount: _categories.length,
            onReorder: (oldIndex, newIndex) {
              final moving = _categories[oldIndex];
              if (moving.name == "默认") return;
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _categories.removeAt(oldIndex);
                _categories.insert(newIndex, item);
              });
              _saveOrder();
            },
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _buildCategoryRow(cat, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(CategoryItem category, int index) {
    bool isEditing = _editingId == category.id;
    final isDefault = category.name == "默认";

    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEditing ? ProMaxColors.stitchFluidPrimary.withValues(alpha: 0.1) : ProMaxColors.stitchFluidCoffeeDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditing ? ProMaxColors.stitchFluidPrimary : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (!isDefault)
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator_rounded, color: ProMaxColors.stitchFluidPrimary, size: 28),
              )
            else
              const Icon(Icons.lock_rounded, color: Colors.white24, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: _editController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "分类名称",
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      onSubmitted: (_) => _finishEditing(category),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "排序: ${index + 1}", // Could fetch track counts later
                          style: const TextStyle(color: ProMaxColors.stitchFluidTextMuted, fontSize: 11),
                        ),
                      ],
                    ),
            ),
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: ProMaxColors.stitchFluidPrimary),
                onPressed: () => _finishEditing(category),
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: ProMaxColors.stitchFluidPrimary, size: 20),
                    onPressed: isDefault ? null : () {
                      setState(() {
                        _editingId = category.id;
                        _editController.text = category.name;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: ProMaxColors.stitchFluidTextMuted, size: 20),
                    onPressed: isDefault ? null : () => _confirmDelete(category),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _finishEditing(CategoryItem category) async {
    if (category.name == "默认") return;
    final newName = _editController.text.trim();
    if (newName.isNotEmpty) {
      final updated = category.copyWith(name: newName);
      await DatabaseHelper.instance.updateCategory(updated);
      _loadCategories();
    }
    setState(() {
      _editingId = null;
      _editController.clear();
    });
  }

  void _confirmDelete(CategoryItem category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ProMaxColors.stitchFluidCoffeeDark,
        title: const Text("删除分类", style: TextStyle(color: Colors.white)),
        content: Text("确定要删除 \"${category.name}\" 吗？此操作不会删除其中的曲目。", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消", style: TextStyle(color: ProMaxColors.stitchFluidTextMuted)),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCategory(category.id);
              Navigator.pop(context);
              _loadCategories();
            },
            child: const Text("删除", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text("新建分类", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ProMaxColors.stitchFluidPrimary,
          foregroundColor: ProMaxColors.stitchFluidBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 8,
          shadowColor: ProMaxColors.stitchFluidPrimary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  void _showAddDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final controller = TextEditingController();
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF140F0D),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "新建分类",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "请输入分类名称",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: ProMaxColors.stitchCozyAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D241E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: const Text("取消", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () async {
                                final name = controller.text.trim();
                                if (name.isNotEmpty) {
                                  final newCat = CategoryItem(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: name,
                                    sortOrder: _categories.length,
                                  );
                                  await DatabaseHelper.instance.createCategory(newCat);
                                  _loadCategories();
                                }
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ProMaxColors.stitchCozyAccent,
                                foregroundColor: const Color(0xFF140F0D),
                                elevation: 8,
                                shadowColor: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: const Text("创建", style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
