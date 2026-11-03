import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet_type.dart';
import '../models/session_model.dart';
import '../models/triage_level.dart';
import '../services/session_service.dart';
import '../services/user_identity_service.dart';
import '../theme/app_colors.dart';
import '../widgets/triage_badge.dart';
import 'hybrid_triage_chat_screen.dart';
import 'new_checkup_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'red', 'yellow', 'green', 'dog', 'cat'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteSession(SessionModel session) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa ca khám', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text('Bạn có chắc chắn muốn xóa ca bệnh của bé ${session.petName} không? Ca này sẽ bị xóa khỏi lịch sử.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await SessionService.instance.deleteSession(session.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa ca khám của ${session.petName}.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<SessionModel> _filterSessions(List<SessionModel> sessions) {
    return sessions.where((s) {
      if (_selectedFilter == 'red' && s.triageLevel != TriageLevel.red) return false;
      if (_selectedFilter == 'yellow' && s.triageLevel != TriageLevel.yellow) return false;
      if (_selectedFilter == 'green' && s.triageLevel != TriageLevel.green) return false;
      if (_selectedFilter == 'dog' && s.petType != PetType.dog) return false;
      if (_selectedFilter == 'cat' && s.petType != PetType.cat) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = s.petName.toLowerCase().contains(query);
        final matchAssessment = s.preliminaryAssessment.toLowerCase().contains(query);
        final matchMsg = (s.lastMessage ?? '').toLowerCase().contains(query);
        return matchName || matchAssessment || matchMsg;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ Sơ Ca Bệnh'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor, size: 24),
            tooltip: 'Tạo ca khám mới',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewCheckupScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SessionModel>>(
        stream: SessionService.instance.streamUserSessions(UserIdentityService.currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          final allSessions = snapshot.data ?? [];
          final filteredSessions = _filterSessions(allSessions);

          final int redCount = allSessions.where((s) => s.triageLevel == TriageLevel.red).length;
          final int yellowCount = allSessions.where((s) => s.triageLevel == TriageLevel.yellow).length;
          final int greenCount = allSessions.where((s) => s.triageLevel == TriageLevel.green).length;

          return Column(
            children: [
              // 📊 1. CLINICAL DASHBOARD STATS (Thống kê nhanh)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    _buildStatCard('Tổng ca', allSessions.length.toString(), const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
                    const SizedBox(width: 8),
                    _buildStatCard('Cấp cứu', redCount.toString(), const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                    const SizedBox(width: 8),
                    _buildStatCard('Theo dõi', yellowCount.toString(), const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                    const SizedBox(width: 8),
                    _buildStatCard('Ổn định', greenCount.toString(), const Color(0xFF10B981), const Color(0xFFECFDF5)),
                  ],
                ),
              ),

              // 🔍 2. THANH TÌM KIẾM
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên thú cưng, triệu chứng...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),

              // 🏷️ 3. BỘ LỌC CHIP
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'all', allSessions.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('🔴 Mức Đỏ', 'red', redCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('🟡 Mức Vàng', 'yellow', yellowCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('🟢 Mức Xanh', 'green', greenCount),
                      const SizedBox(width: 8),
                      _buildFilterChip('🐕 Chó', 'dog', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('🐈 Mèo', 'cat', null),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 📄 4. DANH SÁCH CA KHÁM
              Expanded(
                child: filteredSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          return _buildSessionCard(session);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewCheckupScreen()),
          );
        },
        backgroundColor: primaryColor,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo Ca Mới',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.1),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int? count) {
    final isSelected = _selectedFilter == value;
    final primaryColor = AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(SessionModel session) {
    final level = session.triageLevel;
    final timeStr = DateFormat('dd/MM/yyyy • HH:mm').format(session.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HybridTriageChatScreen(session: session),
                ),
              );
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dải màu chỉ thị Triage dọc bên trái
                  Container(
                    width: 5,
                    color: level.primaryColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hàng 1: Avatar + Tên thú cưng + Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: level.backgroundColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: level.borderColor, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    session.petType.emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.petName,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TriageBadge(level: level, isCompact: true),
                              const SizedBox(width: 2),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  size: 19,
                                  color: Color(0xFF94A3B8),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (val) {
                                  if (val == 'delete') {
                                    _confirmDeleteSession(session);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Xóa ca khám này',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Hàng 2: Nhận định sơ bộ lâm sàng
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.medical_information_outlined,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    session.preliminaryAssessment,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Hàng 3: Footer thẻ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: session.status == 'active'
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  session.status == 'active' ? '● Đang tư vấn' : '● Đã theo dõi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: session.status == 'active'
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Chi tiết & Hỏi đáp',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: level.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15,
                                    color: level.primaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.splashBlueLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.splashBlue.withValues(alpha: 0.4), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có ca khám nào',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Khi thú cưng có biểu hiện lạ, hãy tạo ca khám mới để nhận đánh giá Triage & hướng dẫn sơ cứu từ AI Zoomies.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewCheckupScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Tạo Ca Khám Đầu Tiên',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
