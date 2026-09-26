import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const kBg = Color(0xFF121212);
const kCard = Color(0xFF1E1E1E);
const kAccent = Color(0xFF4FC3F7);

class Ads {
  static const bool useReal = kReleaseMode;
  static String get banner => useReal
      ? 'ca-app-pub-4394160099384807/6218227825'
      : 'ca-app-pub-3940256099942544/6300978111';
  static String get native => useReal
      ? 'ca-app-pub-4394160099384807/8165648598'
      : 'ca-app-pub-3940256099942544/2247696110';
  static String get interstitial => useReal
      ? 'ca-app-pub-4394160099384807/1787942503'
      : 'ca-app-pub-3940256099942544/1033173712';
  static String get rewarded => useReal
      ? 'ca-app-pub-4394160099384807/5387296225'
      : 'ca-app-pub-3940256099942544/5224354917';
}

class Article {
  final String id, title, desc, body, category;
  final DateTime date;
  final String? link;
  final String? linkLabel;
  const Article(this.id, this.title, this.desc, this.body, this.category, this.date, {this.link, this.linkLabel});
}

const categories = ['AI', 'Software', 'Security', 'Mobile', 'Dev Tools'];

String fmtDate(DateTime d) {
  const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'];
  return '${m[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
}

final articles = <Article>[
  Article('1', '5 AI prompts that save you an hour a day', 'Simple prompts for summaries, emails and daily planning.',
      'Start with a clear role, give the context, and say exactly what format you want back. Ask for a summary, then ask for the three most important actions. Always check facts before you share the result.', 'AI', DateTime(2026, 9, 22)),
  Article('2', 'Bitwarden: a free, open-source password manager', 'Software directory: store and autofill strong passwords on every device.',
      'Bitwarden stores your logins in an encrypted vault, generates strong passwords and fills them into apps and websites. It has a free tier and works on phones, browsers and desktops.', 'Software', DateTime(2026, 9, 20),
      link: 'https://play.google.com/store/apps/details?id=com.x8bit.bitwarden', linkLabel: 'Download Bitwarden'),
  Article('3', 'Turn on two-step verification everywhere', 'The single best upgrade for your account security.',
      'Use an authenticator app instead of SMS where possible. Save your backup codes somewhere offline. Start with email, banking and social accounts.', 'Security', DateTime(2026, 9, 18)),
  Article('4', 'Speed up your Android phone in 5 minutes', 'Clear cache, remove unused apps and update your system.',
      'Uninstall apps you have not opened in months, clear the cache of heavy apps, and keep at least 10 percent of storage free. Restart the phone once a week.', 'Mobile', DateTime(2026, 9, 15)),
  Article('5', 'Visual Studio Code: a lightweight code editor', 'Software directory: a free editor with thousands of extensions.',
      'Visual Studio Code supports many languages, has built-in Git tools and a large extension library. It runs on Windows, macOS and Linux.', 'Dev Tools', DateTime(2026, 9, 12),
      link: 'https://code.visualstudio.com/', linkLabel: 'Download VS Code'),
  Article('6', 'How to fact-check AI answers', 'Use AI as a starting point, not the final word.',
      'Ask the assistant for sources, open them yourself, and compare at least two independent references before you rely on a number, date or quote.', 'AI', DateTime(2026, 9, 9)),
  Article('7', 'Obsidian: notes stored as plain files', 'Software directory: link your notes into a personal knowledge base.',
      'Obsidian keeps notes as Markdown files on your device and lets you link them together. It is popular for study notes, research and journaling.', 'Software', DateTime(2026, 9, 6)),
  Article('8', 'Git basics every beginner should know', 'Commit, branch and push without the confusion.',
      'A commit is a saved snapshot. A branch lets you try changes safely. Push sends your commits to a remote copy such as GitHub.', 'Dev Tools', DateTime(2026, 9, 3)),
];

class InterstitialManager {
  static InterstitialAd? _ad;
  static bool _loading = false;
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  static const cooldown = Duration(seconds: 15);

  static void load() {
    if (_loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: Ads.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) { _ad = ad; _loading = false; },
        onAdFailedToLoad: (_) { _ad = null; _loading = false; },
      ),
    );
  }

  static void showThen(VoidCallback next) {
    final ad = _ad;
    if (ad == null || DateTime.now().difference(_last) < cooldown) {
      load();
      next();
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) { a.dispose(); _last = DateTime.now(); load(); next(); },
      onAdFailedToShowFullScreenContent: (a, e) { a.dispose(); load(); next(); },
    );
    ad.show();
  }
}

class RewardedManager {
  static RewardedAd? _ad;
  static bool _loading = false;

  static void load() {
    if (_loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: Ads.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { _ad = ad; _loading = false; },
        onAdFailedToLoad: (_) { _ad = null; _loading = false; },
      ),
    );
  }

  static void show({required VoidCallback onEarned, required VoidCallback onUnavailable}) {
    final ad = _ad;
    if (ad == null) {
      load();
      onUnavailable();
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) { a.dispose(); load(); },
      onAdFailedToShowFullScreenContent: (a, e) { a.dispose(); load(); onUnavailable(); },
    );
    ad.show(onUserEarnedReward: (_, __) => onEarned());
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});
  @override
  State<BannerAdWidget> createState() => _BannerState();
}

class _BannerState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: Ads.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) { if (mounted) setState(() => _ok = true); },
        onAdFailedToLoad: (ad, e) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() { _ad?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => !_ok
      ? const SizedBox.shrink()
      : Container(
          color: kBg,
          alignment: Alignment.center,
          height: 50,
          child: SizedBox(width: 320, child: AdWidget(ad: _ad!)),
        );
}

class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});
  @override
  State<NativeAdCard> createState() => _NativeState();
}

class _NativeState extends State<NativeAdCard> with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _ok = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _ad = NativeAd(
      adUnitId: Ads.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) { if (mounted) setState(() => _ok = true); },
        onAdFailedToLoad: (ad, e) { ad.dispose(); _ad = null; },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: kCard,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black, backgroundColor: kAccent, style: NativeTemplateFontStyle.bold, size: 14),
        primaryTextStyle: NativeTemplateTextStyle(textColor: Colors.white, size: 14),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: Colors.white70, size: 12),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: Colors.white54, size: 12),
      ),
    )..load();
  }

  @override
  void dispose() { _ad?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_ok || _ad == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320, minHeight: 250, maxHeight: 330),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  InterstitialManager.load();
  RewardedManager.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(NerdTipsApp(prefs: prefs));
}

const kAppVersion = '1.0.0';
const kPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.nerdtips.nerd_tips';

class NerdTipsApp extends StatefulWidget {
  final SharedPreferences prefs;
  const NerdTipsApp({super.key, required this.prefs});
  @override
  State<NerdTipsApp> createState() => _NerdTipsAppState();
}

class _NerdTipsAppState extends State<NerdTipsApp> {
  late bool darkMode = widget.prefs.getBool('darkMode') ?? true;
  late double textScale = widget.prefs.getDouble('textScale') ?? 1.0;

  void setDarkMode(bool v) {
    setState(() => darkMode = v);
    widget.prefs.setBool('darkMode', v);
  }

  void setTextScale(double v) {
    setState(() => textScale = v);
    widget.prefs.setDouble('textScale', v);
  }

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(primary: Color(0xFF0288D1), surface: Colors.white),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFFF2F2F2)),
    );
    final dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.dark(primary: kAccent, surface: kCard),
      cardColor: kCard,
      appBarTheme: const AppBarTheme(backgroundColor: kBg, elevation: 0),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kCard,
        indicatorColor: kAccent.withOpacity(0.25),
      ),
    );
    return MaterialApp(
      title: 'Nerd Tips',
      debugShowCheckedModeBanner: false,
      theme: darkMode ? dark : light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Shell(
        prefs: widget.prefs,
        darkMode: darkMode,
        textScale: textScale,
        onDarkModeChanged: setDarkMode,
        onTextScaleChanged: setTextScale,
      ),
    );
  }
}

class Shell extends StatefulWidget {
  final SharedPreferences prefs;
  final bool darkMode;
  final double textScale;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<double> onTextScaleChanged;
  const Shell({super.key, required this.prefs, required this.darkMode, required this.textScale,
    required this.onDarkModeChanged, required this.onTextScaleChanged});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  String query = '';
  late final Set<String> favs = (widget.prefs.getStringList('favs') ?? []).toSet();

  void toggle(Article a) {
    setState(() { if (!favs.remove(a.id)) favs.add(a.id); });
    widget.prefs.setStringList('favs', favs.toList());
  }

  void open(Article a) => InterstitialManager.showThen(() {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => ArticleScreen(article: a, isFav: favs.contains(a.id), onToggle: () => toggle(a))));
      });

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final recent = ([...articles]..sort((a, b) => b.date.compareTo(a.date)))
        .where((a) => a.title.toLowerCase().contains(q) || a.desc.toLowerCase().contains(q))
        .toList();
    final pages = <Widget>[
      FeedList(items: recent, favs: favs, onOpen: open, onFav: toggle),
      CategoryPage(favs: favs, onOpen: open, onFav: toggle),
      FeedList(items: articles.where((a) => favs.contains(a.id)).toList(),
          favs: favs, onOpen: open, onFav: toggle, empty: 'No favorites yet'),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          if (tab == 0) SearchHeader(
            onChanged: (v) => setState(() => query = v),
            onSettings: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SettingsScreen(
                      prefs: widget.prefs,
                      darkMode: widget.darkMode,
                      textScale: widget.textScale,
                      onDarkModeChanged: widget.onDarkModeChanged,
                      onTextScaleChanged: widget.onTextScaleChanged,
                      onCacheCleared: () => setState(() {}),
                    ))),
          ),
          Expanded(child: pages[tab]),
          const BannerAdWidget(),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Recent'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Category'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorite'),
        ],
      ),
    );
  }
}

class SearchHeader extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onSettings;
  const SearchHeader({super.key, required this.onChanged, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(28)),
        child: Row(children: [
          Icon(Icons.search, color: cs.onSurface.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search Nerd Tips',
                hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                border: InputBorder.none,
              ),
            ),
          ),
          InkWell(
            onTap: onSettings,
            borderRadius: BorderRadius.circular(20),
            child: const CircleAvatar(radius: 16, backgroundColor: kAccent,
                child: Icon(Icons.settings, color: Colors.black, size: 18)),
          ),
        ]),
      ),
    );
  }
}

class FeedList extends StatelessWidget {
  final List<Article> items;
  final Set<String> favs;
  final void Function(Article) onOpen, onFav;
  final String empty;
  const FeedList({super.key, required this.items, required this.favs,
    required this.onOpen, required this.onFav, this.empty = 'Nothing found'});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(empty, style: const TextStyle(color: Colors.white54)));
    }
    final n = items.length;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: n + n ~/ 2,
      itemBuilder: (_, i) {
        final adsBefore = (i + 1) ~/ 3;
        if (i % 3 == 2) return const NativeAdCard();
        final a = items[i - adsBefore];
        return ArticleCard(a: a, fav: favs.contains(a.id), onTap: () => onOpen(a), onFav: () => onFav(a));
      },
    );
  }
}

class ArticleCard extends StatelessWidget {
  final Article a;
  final bool fav;
  final VoidCallback onTap, onFav;
  const ArticleCard({super.key, required this.a, required this.fav, required this.onTap, required this.onFav});

  @override
  Widget build(BuildContext context) => Card(
        color: kCard,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.category.toUpperCase(),
                  style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(a.desc, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.schedule, size: 16, color: Colors.white54),
                const SizedBox(width: 6),
                Text(fmtDate(a.date), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const Spacer(),
                IconButton(
                  onPressed: onFav,
                  icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? kAccent : Colors.white54),
                ),
              ]),
            ]),
          ),
        ),
      );
}

class CategoryPage extends StatelessWidget {
  final Set<String> favs;
  final void Function(Article) onOpen, onFav;
  const CategoryPage({super.key, required this.favs, required this.onOpen, required this.onFav});

  @override
  Widget build(BuildContext context) => ListView(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Categories', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        for (final c in categories)
          Card(
            color: kCard,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.folder_outlined, color: kAccent),
              title: Text(c, style: const TextStyle(color: Colors.white)),
              trailing: Text('${articles.where((a) => a.category == c).length}',
                  style: const TextStyle(color: Colors.white54)),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CategoryScreen(cat: c, favs: favs, onOpen: onOpen, onFav: onFav))),
            ),
          ),
      ]);
}

class CategoryScreen extends StatefulWidget {
  final String cat;
  final Set<String> favs;
  final void Function(Article) onOpen, onFav;
  const CategoryScreen({super.key, required this.cat, required this.favs, required this.onOpen, required this.onFav});
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.cat)),
        body: FeedList(
          items: articles.where((a) => a.category == widget.cat).toList(),
          favs: widget.favs,
          onOpen: widget.onOpen,
          onFav: (a) { widget.onFav(a); setState(() {}); },
        ),
        bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      );
}

class ArticleScreen extends StatefulWidget {
  final Article article;
  final bool isFav;
  final VoidCallback onToggle;
  const ArticleScreen({super.key, required this.article, required this.isFav, required this.onToggle});
  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late bool fav = widget.isFav;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? kAccent : Colors.white70),
          onPressed: () { widget.onToggle(); setState(() => fav = !fav); },
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(a.category.toUpperCase(),
            style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(a.title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(fmtDate(a.date), style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        Text(a.desc, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        Text(a.body, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
        if (a.link != null) ...[
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(a.link!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              a.linkLabel ?? 'Open link',
              style: const TextStyle(color: kAccent, fontSize: 16, decoration: TextDecoration.underline, decorationColor: kAccent),
            ),
          ),
        ],
      ]),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
    );
  }
}

const kPrivacyPolicy = '''
Nerd Tips is built by you (the developer) as a free app.

This page explains what information the app collects when you use it.

Information Collection and Use
Nerd Tips does not require an account and does not collect personal information such as your name or email. Your favorites and app preferences (dark mode, text size) are stored only on your own device.

Advertising
This app uses Google AdMob to show ads. AdMob may collect device identifiers (such as the advertising ID) to show relevant ads and measure performance. You can review Google's practices here:
https://policies.google.com/technologies/ads

Children's Privacy
This app is not directed at children under 13. We do not knowingly collect personal information from children.

Changes to This Policy
This policy may be updated occasionally. Continued use of the app after changes means you accept the updated policy.

Contact
If you have questions about this policy, contact: estifanosmesfin8@gmail.com
''';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final bool darkMode;
  final double textScale;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<double> onTextScaleChanged;
  final VoidCallback onCacheCleared;
  const SettingsScreen({super.key, required this.prefs, required this.darkMode, required this.textScale,
    required this.onDarkModeChanged, required this.onTextScaleChanged, required this.onCacheCleared});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _clearCache() {
    widget.prefs.remove('favs');
    widget.onCacheCleared();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache and favorites cleared')));
  }

  void _rateApp() async {
    final uri = Uri.parse(kPlayStoreUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _shareApp() async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent('Check out Nerd Tips: $kPlayStoreUrl')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _watchRewarded() {
    RewardedManager.show(
      onEarned: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanks for supporting Nerd Tips!')));
      },
      onUnavailable: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No ad available right now — try again in a moment')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const _SectionHeader('General'),
        SwitchListTile(
          title: const Text('Dark mode'),
          subtitle: const Text('Better eyesight and power saving'),
          value: widget.darkMode,
          onChanged: widget.onDarkModeChanged,
        ),
        ListTile(
          title: const Text('Text size'),
          subtitle: Slider(
            value: widget.textScale,
            min: 0.85,
            max: 1.3,
            divisions: 3,
            label: widget.textScale.toStringAsFixed(2),
            onChanged: widget.onTextScaleChanged,
          ),
        ),
        const Divider(),
        const _SectionHeader('Cache'),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Clear cache & favorites'),
          onTap: _clearCache,
        ),
        const Divider(),
        const _SectionHeader('Privacy'),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
        ),
        const Divider(),
        const _SectionHeader('About'),
        const ListTile(leading: Icon(Icons.info_outline), title: Text('Version'), trailing: Text(kAppVersion)),
        ListTile(leading: const Icon(Icons.star_border), title: const Text('Rate this app'), onTap: _rateApp),
        ListTile(leading: const Icon(Icons.share_outlined), title: const Text('Share this app'), onTap: _shareApp),
        const Divider(),
        const _SectionHeader('Support'),
        ListTile(
          leading: const Icon(Icons.favorite_outline, color: kAccent),
          title: const Text('Support the developer'),
          subtitle: const Text('Watch a short ad — costs you nothing extra'),
          onTap: _watchRewarded,
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kAccent)),
      );
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacy policy')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(kPrivacyPolicy, style: const TextStyle(fontSize: 15, height: 1.5)),
        ]),
      );
}
