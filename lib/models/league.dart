/// The level a team plays at. Teams are browsed and matched up within a
/// league; cross-league projections are not meaningful.
enum League {
  nfl('NFL', 'Pro'),
  ncaa('NCAA', 'College'),
  nba('NBA', 'Pro'),
  mls('MLS', 'Pro'),
  ufl('UFL', 'Spring pro'),
  cfl('CFL', 'Canadian pro'),
  highSchool('HS', 'High school');

  const League(this.label, this.level);

  /// Short name shown on tabs and badges, e.g. `NCAA`.
  final String label;

  /// Plain-language level, e.g. `College`.
  final String level;

  /// College and high-school players list a class year, not years pro.
  bool get isAmateur => this == League.ncaa || this == League.highSchool;
}
