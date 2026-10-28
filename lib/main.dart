import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// ============================================================
// THEME CONSTANTS
// ============================================================

const _brand = Color(0xFF5146D8);
const _brand2 = Color(0xFF7857E8);
const _ink = Color(0xFF20243A);
const _ink2 = Color(0xFF3A3F55);
const _muted = Color(0xFF777E8E);
const _line = Color(0xFFECEEF5);
const _bg = Color(0xFFF6F7FB);
const _gradient = [_brand, _brand2];

const Map<String, IconData> _sectorIcons = {
  'IT': Icons.computer,
  'Healthcare': Icons.local_hospital_outlined,
  'Finance': Icons.account_balance_outlined,
  'Education': Icons.school_outlined,
  'Engineering': Icons.engineering_outlined,
  'Marketing': Icons.campaign_outlined,
};

const Map<String, Color> _sectorColors = {
  'IT': Color(0xFF6366F1),
  'Healthcare': Color(0xFF10B981),
  'Finance': Color(0xFFF59E0B),
  'Education': Color(0xFF3B82F6),
  'Engineering': Color(0xFFEF4444),
  'Marketing': Color(0xFFEC4899),
};

final List<Color> _avatarPalette = [
  Colors.deepPurple,
  Colors.teal,
  Colors.orange.shade700,
  Colors.pink.shade400,
  Colors.blue.shade600,
  Colors.green.shade600,
];

Color _avatarColor(String name) {
  final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
  return _avatarPalette[hash % _avatarPalette.length];
}

String _initial(String s) => s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();

Color _statusColor(String status) {
  switch (status) {
    case 'Shortlisted':
      return const Color(0xFF16A34A);
    case 'Reviewed':
      return const Color(0xFF2563EB);
    default:
      return const Color(0xFFE69A25);
  }
}

String _fmtDate(dynamic ts) {
  if (ts is! Timestamp) return 'Just now';
  final d = ts.toDate();
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

// ============================================================
// MODELS + STORES
// ============================================================

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String sector;
  final String description;
  final String salary;
  final double maxLpa; // used only for sorting

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.sector,
    required this.description,
    required this.salary,
    required this.maxLpa,
  });

  bool get isRemote => location.toLowerCase() == 'remote';
}

class JobStore {
  JobStore._();
  static final JobStore instance = JobStore._();

  final List<Job> _jobs = const [
    Job(
      id: 'j1',
      title: 'Flutter Developer',
      company: 'TechNova Pvt Ltd',
      location: 'Bangalore',
      sector: 'IT',
      description:
          'Build cross-platform mobile apps using Flutter and Dart. 2+ years experience required.',
      salary: '\u20B98\u201314 LPA',
      maxLpa: 14,
    ),
    Job(
      id: 'j2',
      title: 'Backend Engineer',
      company: 'CloudBase Solutions',
      location: 'Remote',
      sector: 'IT',
      description:
          'Design and maintain REST APIs using Node.js and MongoDB. Strong problem-solving skills needed.',
      salary: '\u20B910\u201318 LPA',
      maxLpa: 18,
    ),
    Job(
      id: 'j3',
      title: 'Data Analyst',
      company: 'Insightify',
      location: 'Hyderabad',
      sector: 'IT',
      description:
          'Analyze large datasets and build dashboards. Proficiency in Python and SQL required.',
      salary: '\u20B96\u201310 LPA',
      maxLpa: 10,
    ),
    Job(
      id: 'j4',
      title: 'Staff Nurse',
      company: 'Apollo Hospitals',
      location: 'Chennai',
      sector: 'Healthcare',
      description:
          'Provide patient care in ICU/general ward. B.Sc Nursing or GNM required.',
      salary: '\u20B93\u20135 LPA',
      maxLpa: 5,
    ),
    Job(
      id: 'j5',
      title: 'Medical Lab Technician',
      company: 'PathCare Labs',
      location: 'Delhi',
      sector: 'Healthcare',
      description:
          'Perform diagnostic tests and maintain lab equipment. DMLT/B.Sc MLT required.',
      salary: '\u20B92.5\u20134 LPA',
      maxLpa: 4,
    ),
    Job(
      id: 'j6',
      title: 'Financial Analyst',
      company: 'WealthBridge',
      location: 'Mumbai',
      sector: 'Finance',
      description:
          'Prepare financial reports, budgeting, and forecasting. CA/MBA Finance preferred.',
      salary: '\u20B97\u201312 LPA',
      maxLpa: 12,
    ),
    Job(
      id: 'j7',
      title: 'Relationship Manager',
      company: 'HDFC Bank',
      location: 'Pune',
      sector: 'Finance',
      description:
          'Manage client portfolios and acquire new business. Strong communication skills needed.',
      salary: '\u20B95\u20138 LPA',
      maxLpa: 8,
    ),
    Job(
      id: 'j8',
      title: 'Primary School Teacher',
      company: 'DPS Group',
      location: 'Noida',
      sector: 'Education',
      description:
          'Teach grades 1\u20135. B.Ed degree required. Prior teaching experience preferred.',
      salary: '\u20B93\u20135 LPA',
      maxLpa: 5,
    ),
    Job(
      id: 'j9',
      title: 'Online Tutor',
      company: 'Vedantu',
      location: 'Remote',
      sector: 'Education',
      description:
          'Conduct live online sessions for K-12 students. Subject expertise required.',
      salary: '\u20B92\u20136 LPA',
      maxLpa: 6,
    ),
    Job(
      id: 'j10',
      title: 'Civil Site Engineer',
      company: 'L&T Construction',
      location: 'Mumbai',
      sector: 'Engineering',
      description:
          'Supervise construction sites and ensure quality standards. B.E Civil required.',
      salary: '\u20B95\u20139 LPA',
      maxLpa: 9,
    ),
    Job(
      id: 'j11',
      title: 'Mechanical Design Engineer',
      company: 'Tata Motors',
      location: 'Pune',
      sector: 'Engineering',
      description:
          'Design and prototype mechanical components using CAD tools. B.E Mechanical required.',
      salary: '\u20B96\u201311 LPA',
      maxLpa: 11,
    ),
    Job(
      id: 'j12',
      title: 'Digital Marketing Executive',
      company: 'BrandBoost',
      location: 'Bangalore',
      sector: 'Marketing',
      description:
          'Run SEO, SEM, and social media campaigns. Google Ads certification a plus.',
      salary: '\u20B94\u20137 LPA',
      maxLpa: 7,
    ),
    Job(
      id: 'j13',
      title: 'Content Writer',
      company: 'Writify',
      location: 'Remote',
      sector: 'Marketing',
      description:
          'Write blogs, articles, and web copy. Strong English writing skills required.',
      salary: '\u20B93\u20135 LPA',
      maxLpa: 5,
    ),
  ];

  List<Job> get all => List.unmodifiable(_jobs);

  List<String> get sectors => _jobs.map((j) => j.sector).toSet().toList()..sort();

  List<Job> bysector(String sector) =>
      _jobs.where((j) => j.sector == sector).toList();
}

/// Saved jobs live in memory only (no Firestore involved).
class SavedJobsStore {
  SavedJobsStore._();
  static final SavedJobsStore instance = SavedJobsStore._();

  final ValueNotifier<Set<String>> ids = ValueNotifier<Set<String>>({});

  void toggle(String id) {
    final s = {...ids.value};
    if (!s.remove(id)) s.add(id);
    ids.value = s;
  }

  void add(String id) => ids.value = {...ids.value, id};
}

/// One shared listener on the existing FirestoreService.watchMyApplications()
/// stream. Every screen reads from here, so job cards no longer make one
/// Firestore request each.
class ApplicationsStore {
  ApplicationsStore._();
  static final ApplicationsStore instance = ApplicationsStore._();

  final ValueNotifier<List<Map<String, dynamic>>> apps =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<bool> loaded = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  void start() {
    _sub?.cancel();
    apps.value = [];
    loaded.value = false;
    error.value = null;
    _sub = FirestoreService.watchMyApplications().listen(
      (list) {
        final sorted = [...list];
        sorted.sort((a, b) {
          final ta = a['appliedAt'];
          final tb = b['appliedAt'];
          if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
          if (ta is Timestamp) return 1; // pending server timestamp = newest
          if (tb is Timestamp) return -1;
          return 0;
        });
        error.value = null;
        apps.value = sorted;
        loaded.value = true;
      },
      onError: (Object e) {
        error.value = e.toString();
        loaded.value = true;
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  bool hasApplied(String jobId) => apps.value.any((a) => a['jobId'] == jobId);
}

// ============================================================
// HELPERS
// ============================================================

bool _isValidEmail(String email) {
  final re = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}$');
  return re.hasMatch(email.trim());
}

void _snackOn(
  ScaffoldMessengerState m,
  String message, {
  bool error = false,
  SnackBarAction? action,
}) {
  m
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : const Color(0xFF15803D),
        behavior: SnackBarBehavior.floating,
        action: action,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

void _showSnack(BuildContext context, String message, {bool error = false}) =>
    _snackOn(ScaffoldMessenger.of(context), message, error: error);

InputDecoration _dec(String label, IconData icon,
    {Widget? suffix, String? helper, String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
  );
}

// ============================================================
// REUSABLE WIDGETS
// ============================================================

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFFDF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class InteractiveButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const InteractiveButton(
      {super.key, required this.onPressed, required this.child});

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.97 : (_hovering ? 1.02 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: _hovering && widget.onPressed != null
                  ? [
                      BoxShadow(
                        color: _brand.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: widget.onPressed,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _SurfaceCard(
      {required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Pill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  final String company;
  final double size;
  const _CompanyLogo({required this.company, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(company);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(_initial(company),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.42)),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;
  const _BrandMark({this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _gradient),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.work_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _muted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: _muted)),
        Expanded(
            child: Text(value.isEmpty ? '\u2014' : value,
                style: const TextStyle(color: _ink2))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader(
      {required this.title,
      required this.subtitle,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: _muted)),
        ]),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ]);
  }
}

/// Scrollable page body that is centered and capped in width.
class _PageScroll extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const _PageScroll({required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = math.max(0.0, math.min(c.maxWidth - 40, maxWidth));
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: w, child: child),
        ),
      );
    });
  }
}

class _FadeIn extends StatelessWidget {
  final int index;
  final Widget child;
  const _FadeIn({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index % 8) * 50),
      curve: Curves.easeOut,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

class RingProgress extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final Color color;
  final Widget? center;
  const RingProgress(
      {super.key,
      required this.value,
      this.size = 130,
      this.color = _brand,
      this.center});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, color),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  _RingPainter(this.value, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: 0.12);
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (value <= 0) return;
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, prog);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}

class BookmarkButton extends StatelessWidget {
  final String jobId;
  const BookmarkButton({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: SavedJobsStore.instance.ids,
      builder: (_, saved, __) {
        final on = saved.contains(jobId);
        return IconButton(
          tooltip: on ? 'Remove from saved' : 'Save job',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            SavedJobsStore.instance.toggle(jobId);
            _showSnack(context, on ? 'Removed from saved jobs' : 'Job saved');
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              on ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              key: ValueKey(on),
              color: on ? _brand : _muted,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// APP ROOT
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brand,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _bg,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _brand, width: 1.6),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: _ink,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: _brand.withValues(alpha: 0.12),
          labelTextStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignupPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

// ============================================================
// AUTH SHELL (login + signup share this layout)
// ============================================================

class AuthShell extends StatelessWidget {
  final Widget child;
  const AuthShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: LayoutBuilder(builder: (context, box) {
          final form = SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          );
          if (box.maxWidth < 900) return form;
          return Row(children: [
            const Expanded(flex: 5, child: _BrandPanel()),
            Expanded(flex: 4, child: form),
          ]);
        }),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final jobs = JobStore.instance.all.length;
    final sectors = JobStore.instance.sectors.length;
    return Container(
      padding: const EdgeInsets.all(56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.work_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('CareerConnect',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 48),
          const Text('Find the work that fits your life.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1.15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const Text(
              'Browse roles across IT, healthcare, finance, education and more. Apply in under a minute and track every application in one place.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
          const SizedBox(height: 36),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _BrandStat(value: '$jobs', label: 'Open roles'),
            _BrandStat(value: '$sectors', label: 'Sectors'),
            const _BrandStat(value: '1 min', label: 'To apply'),
          ]),
        ],
      ),
    );
  }
}

class _BrandStat extends StatelessWidget {
  final String value;
  final String label;
  const _BrandStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _AuthHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: _gradient),
          boxShadow: [
            BoxShadow(
              color: _brand.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: 30, color: Colors.white),
      ),
      const SizedBox(height: 20),
      Text(title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: _ink)),
      const SizedBox(height: 6),
      Text(subtitle,
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: _muted)),
      const SizedBox(height: 28),
    ]);
  }
}

Widget _loadingOr(bool loading, String label) {
  return loading
      ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : Text(label,
          style: const TextStyle(
              fontSize: 15,
              letterSpacing: 1,
              color: Colors.white,
              fontWeight: FontWeight.w600));
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (credential.user == null) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'Login failed.');
      }
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      String message;
      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          message = 'Invalid email or password.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }
      _showSnack(context, message, error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(context, 'Login failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AuthHeader(
              icon: Icons.lock_outline_rounded,
              title: 'Welcome back',
              subtitle: 'Sign in to your account',
            ),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _dec('Email', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required.';
                if (!_isValidEmail(v)) return 'Enter a valid email.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: _dec(
                'Password',
                Icons.lock_outline,
                suffix: IconButton(
                  tooltip:
                      _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required.' : null,
            ),
            const SizedBox(height: 28),
            InteractiveButton(
              onPressed: _loading ? null : _login,
              child: _loadingOr(_loading, 'LOGIN'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Sign Up',
                      style: TextStyle(
                          color: _brand, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SIGNUP PAGE
// ============================================================

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Account created, but user information is unavailable.');
      }

      await user.updateDisplayName(_nameCtrl.text.trim());

      // Save the user's profile in Cloud Firestore after Auth succeeds.
      await FirestoreService.saveUserProfile(
        uid: user.uid,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(context, 'Account created! Welcome aboard.');
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account with that email already exists.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Please choose a stronger password.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Registration failed. Please try again.';
      }
      _showSnack(context, message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(context, 'Something went wrong. Please try again.',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AuthHeader(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Create account',
              subtitle: 'Fill in the details below',
            ),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _dec('Full Name', Icons.person_outline),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required.';
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _dec('Email', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required.';
                if (!_isValidEmail(v)) return 'Enter a valid email.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: _dec('Phone Number', Icons.phone_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required.';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                  return 'Enter a valid 10-digit phone number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: _dec(
                'Password',
                Icons.lock_outline,
                helper: 'Min 6 chars, include a letter and a number.',
                suffix: IconButton(
                  tooltip:
                      _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required.';
                if (v.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(v)) {
                  return 'Password must contain at least one letter.';
                }
                if (!RegExp(r'[0-9]').hasMatch(v)) {
                  return 'Password must contain at least one number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signup(),
              decoration: _dec(
                'Confirm Password',
                Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password.';
                if (v != _passwordCtrl.text) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 28),
            InteractiveButton(
              onPressed: _loading ? null : _signup,
              child: _loadingOr(_loading, 'SIGN UP'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Log In',
                      style: TextStyle(
                          color: _brand, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE (shell: sidebar on wide screens, drawer + nav bar on narrow)
// ============================================================

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

const _navItems = [
  _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
  _NavItem(Icons.work_outline, Icons.work, 'Browse Jobs'),
  _NavItem(Icons.assignment_outlined, Icons.assignment, 'My Applications'),
  _NavItem(Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Saved Jobs'),
  _NavItem(Icons.person_outline, Icons.person, 'My Profile'),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  late Map<String, String> _user;

  @override
  void initState() {
    super.initState();
    final fu = FirebaseAuth.instance.currentUser;
    _user = {
      'name': fu?.displayName ?? 'User',
      'email': fu?.email ?? '',
      'phone': '',
    };
    ApplicationsStore.instance.start();
    _loadProfile();
  }

  @override
  void dispose() {
    ApplicationsStore.instance.stop();
    super.dispose();
  }

  /// Reads the profile document the signup flow already saves
  /// (users/{uid}), which the existing Firestore rules allow.
  Future<void> _loadProfile() async {
    try {
      final p = await FirestoreService.getCurrentUserProfile();
      if (!mounted || p == null) return;
      final name = ((p['name'] as String?) ?? '').trim();
      final phone = ((p['phone'] as String?) ?? '').trim();
      setState(() {
        _user = {
          ..._user,
          if (name.isNotEmpty) 'name': name,
          'phone': phone,
        };
      });
    } catch (_) {
      // Profile is optional for the UI; keep the Auth values.
    }
  }

  void _go(int i) => setState(() => _index = i);

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to see your applications.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ApplicationsStore.instance.stop();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _page() {
    switch (_index) {
      case 0:
        return HomeTab(user: _user, onNavigate: _go);
      case 1:
        return const JobsTab();
      case 2:
        return MyApplicationsTab(onNavigate: _go);
      case 3:
        return SavedTab(onNavigate: _go);
      default:
        return ProfileTab(user: _user, onLogout: _logout);
    }
  }

  Widget _userHeader({required bool onDark}) {
    final name = _user['name'] ?? 'User';
    return Row(children: [
      CircleAvatar(
        radius: 22,
        backgroundColor:
            onDark ? Colors.white.withValues(alpha: 0.2) : _avatarColor(name),
        child: Text(_initial(name),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: onDark ? Colors.white : _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          Text(_user['email'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: onDark ? Colors.white70 : _muted, fontSize: 12)),
        ]),
      ),
    ]);
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration:
                  const BoxDecoration(gradient: LinearGradient(colors: _gradient)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _userHeader(onDark: true),
                  const SizedBox(height: 14),
                  const Text('CAREER CONNECT',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  _NavList(
                    selected: _index,
                    onSelect: (i) {
                      Navigator.pop(context);
                      _go(i);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log out'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 252,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 16, 20),
              child: Row(children: [
                _BrandMark(size: 36),
                SizedBox(width: 10),
                Text('CareerConnect',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 16, 8),
              child: Text('MAIN MENU',
                  style: TextStyle(
                      color: Color(0xFF9298A7),
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  _NavList(selected: _index, onSelect: _go),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: _gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Boost your profile',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          const SizedBox(height: 6),
                          const Text(
                              'A complete profile helps you stand out when you apply.',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 34,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _brand,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              onPressed: () => _go(4),
                              child: const Text('View profile',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(children: [
                Expanded(child: _userHeader(onDark: false)),
                IconButton(
                  tooltip: 'Log out',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 20, color: _muted),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wideTopBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(children: [
        Text(_navItems[_index].label,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, color: _ink)),
        const Spacer(),
        _UserMenu(
            user: _user, onProfile: () => _go(4), onLogout: _logout),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1000;

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(_index), child: _page()),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: wide ? null : _buildDrawer(),
      appBar: wide
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: _index == 0
                  ? const Row(mainAxisSize: MainAxisSize.min, children: [
                      _BrandMark(size: 30),
                      SizedBox(width: 10),
                      Text('CareerConnect',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 19)),
                    ])
                  : Text(_navItems[_index].label,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
              actions: [
                _UserMenu(
                    user: _user, onProfile: () => _go(4), onLogout: _logout),
                const SizedBox(width: 6),
              ],
            ),
      body: wide
          ? Row(children: [
              _buildSidebar(),
              const VerticalDivider(width: 1, thickness: 1, color: _line),
              Expanded(
                child: Column(children: [
                  _wideTopBar(),
                  Expanded(child: body),
                ]),
              ),
            ])
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _go,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.work_outline),
                  selectedIcon: Icon(Icons.work),
                  label: 'Jobs',
                ),
                NavigationDestination(
                  icon: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: ApplicationsStore.instance.apps,
                    builder: (_, apps, __) => Badge(
                      isLabelVisible: apps.isNotEmpty,
                      label: Text('${apps.length}'),
                      child: const Icon(Icons.assignment_outlined),
                    ),
                  ),
                  selectedIcon: const Icon(Icons.assignment),
                  label: 'Applied',
                ),
                NavigationDestination(
                  icon: ValueListenableBuilder<Set<String>>(
                    valueListenable: SavedJobsStore.instance.ids,
                    builder: (_, saved, __) => Badge(
                      isLabelVisible: saved.isNotEmpty,
                      label: Text('${saved.length}'),
                      child: const Icon(Icons.bookmark_border_rounded),
                    ),
                  ),
                  selectedIcon: const Icon(Icons.bookmark_rounded),
                  label: 'Saved',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}

class _NavList extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _NavList({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (int i = 0; i < _navItems.length; i++)
        _NavTile(
          item: _navItems[i],
          index: i,
          selected: selected == i,
          onTap: () => onSelect(i),
        ),
    ]);
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile(
      {required this.item,
      required this.index,
      required this.selected,
      required this.onTap});

  Widget _count(int n) {
    if (n == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? _brand : _brand.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$n',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _brand)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget trailing = const SizedBox.shrink();
    if (index == 2) {
      trailing = ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: ApplicationsStore.instance.apps,
        builder: (_, apps, __) => _count(apps.length),
      );
    } else if (index == 3) {
      trailing = ValueListenableBuilder<Set<String>>(
        valueListenable: SavedJobsStore.instance.ids,
        builder: (_, s, __) => _count(s.length),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? _brand.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(selected ? item.activeIcon : item.icon,
                  size: 21, color: selected ? _brand : _muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? _brand : _ink2)),
              ),
              trailing,
            ]),
          ),
        ),
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  final Map<String, String> user;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  const _UserMenu(
      {required this.user, required this.onProfile, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'User';
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) => v == 'profile' ? onProfile() : onLogout(),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: _ink)),
            Text(user['email'] ?? '',
                style: const TextStyle(fontSize: 12, color: _muted)),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(children: [
            Icon(Icons.person_outline, size: 18),
            SizedBox(width: 10),
            Text('My profile'),
          ]),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(children: [
            Icon(Icons.logout, size: 18, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Log out'),
          ]),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: _avatarColor(name),
          child: Text(_initial(name),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ),
    );
  }
}

// ============================================================
// HOME TAB
// ============================================================

class HomeTab extends StatelessWidget {
  final Map<String, String> user;
  final ValueChanged<int> onNavigate;
  const HomeTab({super.key, required this.user, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final jobs = JobStore.instance.all;
    final sectors = JobStore.instance.sectors;
    final fullName = (user['name'] ?? '').trim();
    final first = fullName.isEmpty ? 'there' : fullName.split(' ').first;

    return _PageScroll(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back, $first!',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 4),
        const Text('Your career journey starts here. Track and manage your applications.',
            style: TextStyle(fontSize: 14, color: _muted)),
        const SizedBox(height: 16),
        TextField(
          readOnly: true,
          onTap: () => onNavigate(1),
          decoration: const InputDecoration(
            hintText: 'Search jobs by title, company or city...',
            prefixIcon: Icon(Icons.search_rounded, size: 21),
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(children: [
              Positioned(right: -30, top: -30, child: _circle(150, 0.08)),
              Positioned(right: 70, bottom: -60, child: _circle(130, 0.06)),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your next chapter starts here',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                          'Explore ${jobs.length} open roles across ${sectors.length} sectors and apply in under a minute.',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14, height: 1.4)),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _brand,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => onNavigate(1),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Browse jobs',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        _MetricsGrid(onNavigate: onNavigate),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, c) {
          final status = _LatestApplicationsCard(onNavigate: onNavigate);
          final strength = _ProfileStrengthCard(user: user);
          if (c.maxWidth < 860) {
            return Column(children: [
              status,
              const SizedBox(height: 16),
              strength,
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: status),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: strength),
          ]);
        }),
        const SizedBox(height: 28),
        const _SectionHeader(
            title: 'Browse by category', subtitle: 'Explore opportunities by field'),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sectors.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 76,
            ),
            itemBuilder: (context, i) {
              final s = sectors[i];
              return _SectorTile(
                sector: s,
                icon: _sectorIcons[s] ?? Icons.work_outline,
                color: _sectorColors[s] ?? _brand,
                count: JobStore.instance.bysector(s).length,
              );
            },
          );
        }),
        const SizedBox(height: 28),
        _SectionHeader(
          title: 'Recommended for you',
          subtitle: 'Roles you have not applied to yet',
          actionLabel: 'View all',
          onAction: () => onNavigate(1),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: ApplicationsStore.instance.apps,
          builder: (_, apps, __) {
            final applied = apps.map((a) => a['jobId']).toSet();
            final rec = jobs.where((j) => !applied.contains(j.id)).take(3).toList();
            if (rec.isEmpty) {
              return const _SurfaceCard(
                  child: Text('You have applied to every open role. Nice work!',
                      style: TextStyle(color: _muted)));
            }
            return _JobGrid(jobs: rec);
          },
        ),
      ]),
    );
  }

  static Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

class _MetricsGrid extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _MetricsGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ApplicationsStore.instance.apps,
      builder: (_, apps, __) => ValueListenableBuilder<Set<String>>(
        valueListenable: SavedJobsStore.instance.ids,
        builder: (_, saved, __) {
          int count(String s) =>
              apps.where((a) => (a['status'] ?? 'Pending') == s).length;
          final cards = [
            _MetricCard(
              icon: Icons.send_rounded,
              label: 'Applications sent',
              value: '${apps.length}',
              color: _brand,
              filled: true,
              onTap: () => onNavigate(2),
            ),
            _MetricCard(
              icon: Icons.hourglass_top_rounded,
              label: 'Pending review',
              value: '${count('Pending')}',
              color: const Color(0xFFE69A25),
              onTap: () => onNavigate(2),
            ),
            _MetricCard(
              icon: Icons.star_rounded,
              label: 'Shortlisted',
              value: '${count('Shortlisted')}',
              color: const Color(0xFF16A34A),
              onTap: () => onNavigate(2),
            ),
            _MetricCard(
              icon: Icons.bookmark_rounded,
              label: 'Saved jobs',
              value: '${saved.length}',
              color: const Color(0xFFEC4899),
              onTap: () => onNavigate(3),
            ),
          ];
          return LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 800 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 98,
              ),
              itemBuilder: (_, i) => cards[i],
            );
          });
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : _ink;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: filled ? const LinearGradient(colors: _gradient) : null,
          color: filled ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: filled ? null : Border.all(color: _line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: filled ? Colors.white : color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 24,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: fg)),
                    const SizedBox(height: 3),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: filled ? Colors.white70 : _muted)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LatestApplicationsCard extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _LatestApplicationsCard({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(
          title: 'Latest applications',
          subtitle: 'Where you stand right now',
          actionLabel: 'See all',
          onAction: () => onNavigate(2),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: ApplicationsStore.instance.loaded,
          builder: (_, loaded, __) =>
              ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: ApplicationsStore.instance.apps,
            builder: (_, apps, __) {
              if (!loaded) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (apps.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.assignment_outlined,
                          size: 44, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text('No applications yet',
                          style: TextStyle(
                              color: _ink, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Apply to a role and it will show up here.',
                          style: TextStyle(color: _muted, fontSize: 12)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                          onPressed: () => onNavigate(1),
                          child: const Text('Browse jobs')),
                    ]),
                  ),
                );
              }
              return Column(children: [
                for (final a in apps.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(children: [
                      _CompanyLogo(company: (a['company'] ?? '') as String, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text((a['jobTitle'] ?? 'Job') as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _ink)),
                              Text(
                                  '${a['company'] ?? ''} \u2022 ${_fmtDate(a['appliedAt'])}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: _muted)),
                            ]),
                      ),
                      const SizedBox(width: 8),
                      _Pill(
                        label: (a['status'] ?? 'Pending') as String,
                        color: _statusColor((a['status'] ?? 'Pending') as String),
                      ),
                    ]),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _ProfileStrengthCard extends StatelessWidget {
  final Map<String, String> user;
  const _ProfileStrengthCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ApplicationsStore.instance.apps,
      builder: (_, apps, __) => ValueListenableBuilder<Set<String>>(
        valueListenable: SavedJobsStore.instance.ids,
        builder: (_, saved, __) {
          final name = (user['name'] ?? '').trim();
          final items = <MapEntry<String, bool>>[
            MapEntry('Name added', name.isNotEmpty && name != 'User'),
            MapEntry('Email added', (user['email'] ?? '').trim().isNotEmpty),
            MapEntry('Phone number added', (user['phone'] ?? '').trim().isNotEmpty),
            MapEntry('Applied to a job', apps.isNotEmpty),
            MapEntry('Saved a job', saved.isNotEmpty),
          ];
          final done = items.where((e) => e.value).length;
          final pct = (done * 100 / items.length).round();
          return _SurfaceCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                      title: 'Profile strength',
                      subtitle: 'Finish these steps to stand out'),
                  const SizedBox(height: 16),
                  Center(
                    child: RingProgress(
                      value: pct / 100,
                      size: 136,
                      center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$pct%',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: _ink)),
                            const Text('complete',
                                style: TextStyle(fontSize: 11, color: _muted)),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final e in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Icon(
                            e.value
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: e.value ? const Color(0xFF16A34A) : _muted),
                        const SizedBox(width: 10),
                        Text(e.key,
                            style: TextStyle(
                                fontSize: 13,
                                color: e.value ? _ink2 : _muted)),
                      ]),
                    ),
                ]),
          );
        },
      ),
    );
  }
}

class _SectorTile extends StatelessWidget {
  final String sector;
  final IconData icon;
  final Color color;
  final int count;
  const _SectorTile(
      {required this.sector,
      required this.icon,
      required this.color,
      required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobListPage(sector: sector)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sector,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink2)),
                  const SizedBox(height: 2),
                  Text('$count ${count == 1 ? 'job' : 'jobs'}',
                      style: const TextStyle(fontSize: 11, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// JOB CARD + GRID
// ============================================================

class _JobGrid extends StatelessWidget {
  final List<Job> jobs;
  const _JobGrid({required this.jobs});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
      if (cols == 1) {
        return Column(children: [
          for (int i = 0; i < jobs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FadeIn(
                key: ValueKey(jobs[i].id),
                index: i,
                child: JobCard(job: jobs[i]),
              ),
            ),
        ]);
      }
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: jobs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 272,
        ),
        itemBuilder: (_, i) => _FadeIn(
          key: ValueKey(jobs[i].id),
          index: i,
          child: JobCard(job: jobs[i]),
        ),
      );
    });
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final color = _sectorColors[job.sector] ?? _brand;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _CompanyLogo(company: job.company),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _ink)),
                      const SizedBox(height: 2),
                      Text(job.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: _muted)),
                    ]),
              ),
              BookmarkButton(jobId: job.id),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _Pill(
                  label: job.sector,
                  color: color,
                  icon: _sectorIcons[job.sector] ?? Icons.work_outline),
              if (job.isRemote) ...[
                const SizedBox(width: 6),
                const _Pill(
                    label: 'Remote',
                    color: Color(0xFF0D9488),
                    icon: Icons.public_rounded),
              ],
            ]),
            const SizedBox(height: 8),
            Text(job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.4)),
          ]),
          Column(children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.location_on_outlined, size: 15, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _ink2)),
                ),
                Text(job.salary,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: const BorderSide(color: Color(0xFFD9D6FF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                    onPressed: () => _showJobDetail(context, job),
                    child: const Text('Details'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _ApplyButton(job: job)),
            ]),
          ]),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final Job job;
  const _ApplyButton({required this.job});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ApplicationsStore.instance.apps,
      builder: (_, apps, __) {
        final applied = apps.any((a) => a['jobId'] == job.id);
        if (applied) {
          return Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded,
                  size: 16, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text('Applied',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700)),
            ]),
          );
        }
        return SizedBox(
          height: 40,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
            ),
            onPressed: () => _showApplySheet(context, job),
            child: const Text('Apply now'),
          ),
        );
      },
    );
  }
}

// ---------- job detail sheet ----------

void _showJobDetail(BuildContext context, Job job) {
  final color = _sectorColors[job.sector] ?? _brand;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 680),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(children: [
                _CompanyLogo(company: job.company, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                        Text(job.company,
                            style: const TextStyle(color: _muted)),
                      ]),
                ),
                BookmarkButton(jobId: job.id),
              ]),
              const SizedBox(height: 20),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Pill(
                    label: job.location,
                    color: color,
                    icon: Icons.location_on_outlined),
                _Pill(label: job.salary, color: color, icon: Icons.payments_outlined),
                _Pill(
                    label: job.sector,
                    color: color,
                    icon: _sectorIcons[job.sector] ?? Icons.category_outlined),
                if (job.isRemote)
                  const _Pill(
                      label: 'Remote friendly',
                      color: Color(0xFF0D9488),
                      icon: Icons.public_rounded),
              ]),
              const SizedBox(height: 22),
              const Text('About the role',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
              const SizedBox(height: 8),
              Text(job.description,
                  style: const TextStyle(color: _ink2, height: 1.55)),
              const SizedBox(height: 28),
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: ApplicationsStore.instance.apps,
                builder: (_, apps, __) {
                  final applied = apps.any((a) => a['jobId'] == job.id);
                  if (applied) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 8),
                          Text('You have already applied',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                  return InteractiveButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showApplySheet(context, job);
                    },
                    child: const Text('Apply now',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------- apply sheet ----------

void _showApplySheet(BuildContext context, Job job) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ApplyForm(job: job),
  );
}

class _ApplyForm extends StatefulWidget {
  final Job job;
  const _ApplyForm({required this.job});

  @override
  State<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<_ApplyForm> {
  final _formKey = GlobalKey<FormState>();
  final _qualCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _qualCtrl.dispose();
    _expCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await FirestoreService.saveJobApplication(
        jobId: widget.job.id,
        jobTitle: widget.job.title,
        company: widget.job.company,
        sector: widget.job.sector,
        qualification: _qualCtrl.text.trim(),
        experience: _expCtrl.text.trim(),
        skills: _skillCtrl.text.trim(),
      );
      if (mounted) nav.pop();
      _snackOn(messenger, 'Application submitted for ${widget.job.title}!');
    } catch (e) {
      _snackOn(
        messenger,
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(children: [
                _CompanyLogo(company: widget.job.company, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apply for ${widget.job.title}',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                        Text(widget.job.company,
                            style: const TextStyle(color: _muted)),
                      ]),
                ),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                controller: _qualCtrl,
                textInputAction: TextInputAction.next,
                decoration: _dec('Highest Qualification', Icons.school_outlined,
                    hint: 'e.g. B.Tech Computer Science'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Qualification is required.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _expCtrl,
                textInputAction: TextInputAction.next,
                decoration: _dec('Years of Experience', Icons.work_history_outlined,
                    hint: 'e.g. 2 years, Fresher'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Experience is required.'
                    : null,
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final e in const ['Fresher', '1-2 years', '3-5 years', '5+ years'])
                  ActionChip(
                    label: Text(e, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _brand.withValues(alpha: 0.06),
                    side: BorderSide(color: _brand.withValues(alpha: 0.15)),
                    onPressed: () => setState(() => _expCtrl.text = e),
                  ),
              ]),
              const SizedBox(height: 14),
              TextFormField(
                controller: _skillCtrl,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: _dec('Key Skills', Icons.star_outline,
                    hint: 'e.g. Flutter, Dart, REST APIs'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Skills are required.'
                    : null,
              ),
              const SizedBox(height: 24),
              InteractiveButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit application',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// JOBS TAB (search, sector chips, remote filter, sort)
// ============================================================

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  String _sector = 'All';
  String _query = '';
  bool _remoteOnly = false;
  String _sort = 'Featured';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Job> _filtered() {
    final base = _sector == 'All'
        ? JobStore.instance.all
        : JobStore.instance.bysector(_sector);
    final q = _query.trim().toLowerCase();
    final list = base.where((j) {
      if (_remoteOnly && !j.isRemote) return false;
      if (q.isEmpty) return true;
      return j.title.toLowerCase().contains(q) ||
          j.company.toLowerCase().contains(q) ||
          j.location.toLowerCase().contains(q) ||
          j.sector.toLowerCase().contains(q);
    }).toList();
    if (_sort == 'Salary: high to low') {
      list.sort((a, b) => b.maxLpa.compareTo(a.maxLpa));
    } else if (_sort == 'Company: A to Z') {
      list.sort((a, b) => a.company.compareTo(b.company));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sectors = ['All', ...JobStore.instance.sectors];
    final jobs = _filtered();

    return _PageScroll(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Find your next role',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 4),
        const Text('Search opportunities across all sectors.',
            style: TextStyle(fontSize: 13.5, color: _muted)),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search title, company, location...',
            prefixIcon: const Icon(Icons.search_rounded, size: 21),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sectors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = sectors[i];
              final sel = s == _sector;
              return ChoiceChip(
                label: Text(s),
                selected: sel,
                showCheckmark: false,
                avatar: s == 'All'
                    ? null
                    : Icon(_sectorIcons[s] ?? Icons.work_outline,
                        size: 16, color: sel ? _brand : _muted),
                onSelected: (_) => setState(() => _sector = s),
                selectedColor: const Color(0xFFE8E6FF),
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: sel ? const Color(0xFFB9B2FF) : const Color(0xFFE5E7EF)),
                labelStyle: TextStyle(
                    fontSize: 12.5,
                    color: sel ? _brand : const Color(0xFF666D7D),
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          FilterChip(
            label: const Text('Remote only'),
            selected: _remoteOnly,
            onSelected: (v) => setState(() => _remoteOnly = v),
            selectedColor: const Color(0xFFCCFBF1),
            backgroundColor: Colors.white,
            checkmarkColor: const Color(0xFF0D9488),
            side: const BorderSide(color: Color(0xFFE5E7EF)),
            labelStyle: const TextStyle(fontSize: 12.5),
          ),
          const Spacer(),
          Text('${jobs.length} ${jobs.length == 1 ? 'position' : 'positions'}',
              style: const TextStyle(fontSize: 12, color: _muted)),
          PopupMenuButton<String>(
            tooltip: 'Sort jobs',
            icon: const Icon(Icons.sort_rounded, color: _muted),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              for (final s in const [
                'Featured',
                'Salary: high to low',
                'Company: A to Z'
              ])
                CheckedPopupMenuItem<String>(
                    value: s, checked: _sort == s, child: Text(s)),
            ],
          ),
        ]),
        const SizedBox(height: 10),
        if (jobs.isEmpty)
          _SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
            child: Column(children: [
              Icon(Icons.search_off_rounded, size: 50, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              const Text('No jobs match your filters',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
              const SizedBox(height: 4),
              const Text('Try a different keyword or clear the filters.',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _query = '';
                    _sector = 'All';
                    _remoteOnly = false;
                  });
                },
                child: const Text('Clear filters'),
              ),
            ]),
          )
        else
          _JobGrid(jobs: jobs),
      ]),
    );
  }
}

/// Opened from the category tiles on the dashboard.
class JobListPage extends StatelessWidget {
  final String sector;
  const JobListPage({super.key, required this.sector});

  @override
  Widget build(BuildContext context) {
    final jobs = JobStore.instance.bysector(sector);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('$sector jobs',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _PageScroll(child: _JobGrid(jobs: jobs)),
    );
  }
}

// ============================================================
// MY APPLICATIONS TAB
// ============================================================

class MyApplicationsTab extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const MyApplicationsTab({super.key, required this.onNavigate});

  @override
  State<MyApplicationsTab> createState() => _MyApplicationsTabState();
}

class _MyApplicationsTabState extends State<MyApplicationsTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = ApplicationsStore.instance;
    return ValueListenableBuilder<String?>(
      valueListenable: store.error,
      builder: (_, err, __) => ValueListenableBuilder<bool>(
        valueListenable: store.loaded,
        builder: (_, loaded, __) => ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: store.apps,
          builder: (_, apps, __) {
            if (err != null && apps.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 54, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    const Text('Could not load applications',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 6),
                    Text(err,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                    const SizedBox(height: 14),
                    FilledButton(
                        onPressed: store.start, child: const Text('Try again')),
                  ]),
                ),
              );
            }
            if (!loaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (apps.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 14),
                  const Text('No applications yet',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 6),
                  const Text('Find a role you like and apply in under a minute.',
                      style: TextStyle(color: _muted)),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: () => widget.onNavigate(1),
                      child: const Text('Browse jobs')),
                ]),
              );
            }

            int count(String s) =>
                apps.where((a) => (a['status'] ?? 'Pending') == s).length;
            final shown = _filter == 'All'
                ? apps
                : apps.where((a) => (a['status'] ?? 'Pending') == _filter).toList();
            final labels = {
              'All': apps.length,
              'Pending': count('Pending'),
              'Reviewed': count('Reviewed'),
              'Shortlisted': count('Shortlisted'),
            };

            return _PageScroll(
              maxWidth: 860,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My applications',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _ink)),
                    const SizedBox(height: 4),
                    Text(
                        '${apps.length} submitted \u2022 ${count('Shortlisted')} shortlisted',
                        style: const TextStyle(fontSize: 13.5, color: _muted)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final e in labels.entries)
                        ChoiceChip(
                          label: Text('${e.key} (${e.value})'),
                          selected: _filter == e.key,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _filter = e.key),
                          selectedColor: const Color(0xFFE8E6FF),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                              color: _filter == e.key
                                  ? const Color(0xFFB9B2FF)
                                  : const Color(0xFFE5E7EF)),
                          labelStyle: TextStyle(
                              fontSize: 12.5,
                              color: _filter == e.key ? _brand : _muted,
                              fontWeight: _filter == e.key
                                  ? FontWeight.w700
                                  : FontWeight.w500),
                        ),
                    ]),
                    const SizedBox(height: 14),
                    if (shown.isEmpty)
                      const _SurfaceCard(
                          child: Center(
                              child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Nothing here yet for this status.',
                            style: TextStyle(color: _muted)),
                      )))
                    else
                      for (int i = 0; i < shown.length; i++)
                        _FadeIn(
                          key: ValueKey(shown[i]['id'] ?? shown[i]['jobId']),
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ApplicationTile(app: shown[i]),
                          ),
                        ),
                  ]),
            );
          },
        ),
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final Map<String, dynamic> app;
  const _ApplicationTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final status = (app['status'] ?? 'Pending') as String;
    final company = (app['company'] ?? '') as String;
    final sector = (app['sector'] ?? '') as String;
    final sColor = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: _CompanyLogo(company: company, size: 44),
          title: Text((app['jobTitle'] ?? 'Job') as String,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('$company \u2022 ${_fmtDate(app['appliedAt'])}',
                    style: const TextStyle(fontSize: 12, color: _muted)),
                _Pill(label: status, color: sColor),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 14),
            _StatusStepper(status: status),
            const SizedBox(height: 16),
            _DetailRow(
                icon: Icons.category_outlined, label: 'Sector', value: sector),
            const SizedBox(height: 8),
            _DetailRow(
                icon: Icons.school_outlined,
                label: 'Qualification',
                value: (app['qualification'] ?? '') as String),
            const SizedBox(height: 8),
            _DetailRow(
                icon: Icons.work_history_outlined,
                label: 'Experience',
                value: (app['experience'] ?? '') as String),
            const SizedBox(height: 8),
            _DetailRow(
                icon: Icons.star_outline,
                label: 'Skills',
                value: (app['skills'] ?? '') as String),
          ],
        ),
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final String status;
  const _StatusStepper({required this.status});

  static const _steps = ['Pending', 'Reviewed', 'Shortlisted'];

  @override
  Widget build(BuildContext context) {
    final cur = math.max(0, _steps.indexOf(status));
    final children = <Widget>[];
    for (int i = 0; i < _steps.length; i++) {
      final active = i <= cur;
      final color = active ? _statusColor(_steps[cur]) : const Color(0xFFD5D8E2);
      children.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : Colors.white,
            border: Border.all(color: color, width: 2),
          ),
          child: active
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 6),
        Text(_steps[i],
            style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _ink2 : _muted)),
      ]));
      if (i < _steps.length - 1) {
        children.add(Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: i < cur ? _statusColor(_steps[cur]) : const Color(0xFFE3E5EE),
          ),
        ));
      }
    }
    return Row(children: children);
  }
}

// ============================================================
// SAVED TAB (replaces the old Users tab)
// ============================================================

class SavedTab extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const SavedTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: SavedJobsStore.instance.ids,
      builder: (_, saved, __) {
        final jobs =
            JobStore.instance.all.where((j) => saved.contains(j.id)).toList();
        if (jobs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.bookmark_border_rounded,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 14),
              const Text('No saved jobs yet',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 6),
              const Text('Tap the bookmark on any job to keep it here.',
                  style: TextStyle(color: _muted)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => onNavigate(1),
                  child: const Text('Browse jobs')),
            ]),
          );
        }
        return LayoutBuilder(builder: (context, c) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: jobs.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saved jobs',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: _ink)),
                          const SizedBox(height: 4),
                          Text(
                              '${jobs.length} saved \u2022 swipe left to remove',
                              style: const TextStyle(
                                  fontSize: 13.5, color: _muted)),
                        ]);
                  }
                  final job = jobs[i - 1];
                  return Dismissible(
                    key: ValueKey('saved_${job.id}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      SavedJobsStore.instance.toggle(job.id);
                      _snackOn(
                        ScaffoldMessenger.of(context),
                        'Removed ${job.title}',
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: Colors.white,
                          onPressed: () => SavedJobsStore.instance.add(job.id),
                        ),
                      );
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 22),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    child: JobCard(job: job),
                  );
                },
              ),
            ),
          );
        });
      },
    );
  }
}

// ============================================================
// PROFILE TAB
// ============================================================

class ProfileTab extends StatelessWidget {
  final Map<String, String> user;
  final VoidCallback onLogout;
  const ProfileTab({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final name = (user['name'] ?? 'User').trim();
    final email = user['email'] ?? '';
    final phone = (user['phone'] ?? '').trim();

    return _PageScroll(
      maxWidth: 940,
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: _avatarColor(name),
                  child: Text(_initial(name),
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 14),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: Colors.white70)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: ApplicationsStore.instance.apps,
          builder: (_, apps, __) => ValueListenableBuilder<Set<String>>(
            valueListenable: SavedJobsStore.instance.ids,
            builder: (_, saved, __) {
              final short =
                  apps.where((a) => a['status'] == 'Shortlisted').length;
              return Row(children: [
                Expanded(
                    child: _ProfileStat(
                        label: 'Applications',
                        value: '${apps.length}',
                        color: _brand)),
                const SizedBox(width: 12),
                Expanded(
                    child: _ProfileStat(
                        label: 'Shortlisted',
                        value: '$short',
                        color: const Color(0xFF16A34A))),
                const SizedBox(width: 12),
                Expanded(
                    child: _ProfileStat(
                        label: 'Saved',
                        value: '${saved.length}',
                        color: const Color(0xFFEC4899))),
              ]);
            },
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final details = _SurfaceCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                      title: 'Account details',
                      subtitle: 'Information from your sign-up'),
                  const SizedBox(height: 14),
                  _DetailRow(
                      icon: Icons.person_outline, label: 'Name', value: name),
                  const SizedBox(height: 12),
                  _DetailRow(
                      icon: Icons.email_outlined, label: 'Email', value: email),
                  const SizedBox(height: 12),
                  _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: phone.isEmpty ? 'Not added' : phone),
                ]),
          );
          final strength = _ProfileStrengthCard(user: user);
          if (c.maxWidth < 700) {
            return Column(children: [
              details,
              const SizedBox(height: 16),
              strength,
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: details),
            const SizedBox(width: 16),
            Expanded(child: strength),
          ]);
        }),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: Colors.red.shade600,
            side: BorderSide(color: Colors.red.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ProfileStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
      ]),
    );
  }
}