/// The level a team plays at. Teams are browsed and matched up within a
/// league; cross-league projections are not meaningful.
enum League {
  nfl('NFL'),
  ncaa('NCAA'),
  nba('NBA'),
  mls('MLS'),
  ufl('UFL'),
  cfl('CFL'),
  highSchool('HS');

  const League(this.label);

  /// Short name shown on tabs and badges, e.g. `NCAA`. These are proper
  /// nouns and are not translated; the plain-language level is localized
  /// (`leagueLevel`).
  final String label;

  /// College and high-school players list a class year, not years pro.
  bool get isAmateur => this == League.ncaa || this == League.highSchool;
}
