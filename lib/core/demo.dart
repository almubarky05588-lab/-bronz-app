/// وضع التصوير التلقائي لصور App Store (يُفعَّل وقت البناء فقط بـ --dart-define=SCREENSHOTS=true).
/// في هذا الوضع: لا نوافذ إذن ولا بوب اب، والتطبيق يتنقّل بين الشاشات بنفسه عشان تتصوّر.
const kScreenshots = bool.fromEnvironment('SCREENSHOTS');
