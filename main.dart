import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kBg = Color(0xFF121212);
const kCard = Color(0xFF1E1E1E);
const kAccent = Color(0xFF4FC3F7);

/// Release builds use your real AdMob IDs. Debug builds use Google's test IDs
/// so you never generate invalid traffic on your own account while developing.
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
}

// ---------------------------------------------------------------- data
class Article {
  final String id, title, desc, body, category;
  final DateTime date;
  const Article(this.id, this.title, this.desc, this.body, this.category, this.date);
}

const categories = ['AI', 'Software', 'Security', 'Mobile', 'Dev Tools'];

String fmtDate(DateTime d) {
  const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'];
  return '${m[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
}

// Replace or extend with your own original articles and software entries.
final articles = <Article>[
  Article('1', '5 AI prompts that save you an hour a day', 'Simple prompts for summaries, emails and daily planning.',
      'Start with a clear role, give the context, and say exactly what format you want back. Ask for a summary, then ask for the three most important actions. Always check facts before you share the result.', 'AI', DateTime(2026, 9, 22)),
  Article('2', 'Bitwarden: a free, open-source password manager', 'Software directory: store and autofill strong passwords on every device.',
      'Bitwarden stores your logins in an encrypted vault, generates strong passwords and fills them into apps and websites. It has a free tier and works on phones, browsers and desktops.', 'Software', DateTime(2026, 9, 20)),
  Article('3', 'Turn on two-step verification everywhere', 'The single best upgrade for your account security.',
      'Use an authenticator app instead of SMS where possible. Save your backup codes somewhere offline. Start with email, banking and social accounts.', 'Security', DateTime(2026, 9, 18)),
  Article('4', 'Speed up your Android phone in 5 minutes', 'Clear cache, remove unused apps and update your system.',
      'Uninstall apps you have not opened in months, clear the cache of heavy apps, and keep at least 10 percent of storage free. Restart the phone once a week.', 'Mobile', DateTime(2026, 9, 15)),
  Article('5', 'Visual Studio Code: a lightweight code editor', 'Software directory: a free editor with thousands of extensions.',
      'Visual Studio Code supports many languages, has built-in Git tools and a large extension library. It runs on Windows, macOS and Linux.', 'Dev Tools', DateTime(2026, 9, 12)),
  Article('6', 'How to fact-check AI answers', 'Use AI as a starting point, not the final word.',
      'Ask the assistant for sources, open them yourself, and compare at least two independent references before you rely on a number, date or quote.', 'AI', DateTime(2026, 9, 9)),
  Article('7', 'Obsidian: notes stored as plain files', 'Software directory: link your notes into a personal knowledge base.',
      'Obsidian keeps notes as Markdown files on your device and lets you link them together. It is popular for study notes, research and journaling.', 'Software', DateTime(2026, 9, 6)),
  Article('8', 'Git basics every beginner should know', 'Commit, branch and push without the confusion.',
      'A commit is a saved snapshot. A branch lets you try changes safely. Push sends your commits to a remote copy such as GitHub.', 'Dev Tools', DateTime(2026, 9, 3)),
];

// ---------------------------------------------------------------- ads
class InterstitialManager {
  static InterstitialAd? _ad;
  static bool _loading = false;
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  /// Minimum gap between interstitials. Set to Duration.zero to show on every tap.
  static const cooldown = Duration(seconds: 45);

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

  /// Shows the interstitial (if ready and cooldown passed), then runs [next].
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
        templateType: TemplateType.small,
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
          constraints: const BoxConstraints(minWidth: 320, minHeight: 90, maxHeight: 120),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  InterstitialManager.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(NerdTipsApp(prefs: prefs));
}

class NerdTipsApp extends StatelessWidget {
  final SharedPreferences prefs;
  const NerdTipsApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nerd Tips',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
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
        ),
        home: Shell(prefs: prefs),
      );
}

class Shell extends StatefulWidget {
  final SharedPreferences prefs;
  const Shell({super.key, required this.prefs});
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
          if (tab == 0) SearchHeader(onChanged: (v) => setState(() => query = v)),
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
  const SearchHeader({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(28)),
          child: Row(children: [
            const Icon(Icons.search, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search Nerd Tips',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
            const CircleAvatar(radius: 16, backgroundColor: kAccent,
                child: Icon(Icons.bolt, color: Colors.black, size: 20)),
          ]),
        ),
      );
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
      itemCount: n + (n - 1) ~/ 4, // one native ad after every 4 cards
      itemBuilder: (_, i) {
        if (i % 5 == 4) return const NativeAdCard();
        final a = items[i - i ~/ 5];
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
      ]),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
    );
  }
}
