// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'StatMyTeam';

  @override
  String get bootFailedTitle => 'Could not start StatMyTeam';

  @override
  String get bootFailedBody =>
      'Something went wrong while loading. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get loadingLiveData => 'Loading live league data…';

  @override
  String get errorWidgetTitle => 'Something went wrong';

  @override
  String get errorWidgetBody => 'This part of the screen could not be shown.';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get clear => 'Clear';

  @override
  String get saveFailed => 'Could not save your change. Try again.';

  @override
  String get noValue => '—';

  @override
  String get navHome => 'Home';

  @override
  String get navTeams => 'Teams';

  @override
  String get navSaved => 'Saved';

  @override
  String get navSettings => 'Settings';

  @override
  String listTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String listMany(String items, String last) {
    return '$items, and $last';
  }

  @override
  String get listSeparator => ', ';

  @override
  String sportName(String sport) {
    String _temp0 = intl.Intl.selectLogic(sport, {
      'basketball': 'Basketball',
      'football': 'Football',
      'baseball': 'Baseball',
      'hockey': 'Hockey',
      'soccer': 'Soccer',
      'other': '$sport',
    });
    return '$_temp0';
  }

  @override
  String sportMenuName(String sport) {
    String _temp0 = intl.Intl.selectLogic(sport, {
      'basketball': 'Basketball',
      'football': 'American Football',
      'baseball': 'Baseball',
      'hockey': 'Hockey',
      'soccer': 'Soccer',
      'other': '$sport',
    });
    return '$_temp0';
  }

  @override
  String sportSubtitle(String sport) {
    String _temp0 = intl.Intl.selectLogic(sport, {
      'football': 'NFL and college teams',
      'basketball': 'NBA clubs',
      'soccer': 'MLS clubs',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String leagueLevel(String league) {
    String _temp0 = intl.Intl.selectLogic(league, {
      'nfl': 'Pro',
      'ncaa': 'College',
      'nba': 'Pro',
      'mls': 'Pro',
      'ufl': 'Spring pro',
      'cfl': 'Canadian pro',
      'highSchool': 'High school',
      'other': '$league',
    });
    return '$_temp0';
  }

  @override
  String playerStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'Active',
      'questionable': 'Questionable',
      'out': 'Out',
      'injuredReserve': 'Injured reserve',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String playerStatusShort(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'ACT',
      'questionable': 'Q',
      'out': 'OUT',
      'injuredReserve': 'IR',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String depthRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'starter': 'Starter',
      'rotation': 'Rotation',
      'backup': 'Backup',
      'other': '$role',
    });
    return '$_temp0';
  }

  @override
  String positionGroupName(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'quarterback': 'Quarterbacks',
      'runningBack': 'Running backs',
      'receiver': 'Receivers',
      'offensiveLine': 'Offensive line',
      'frontSeven': 'Front seven',
      'secondary': 'Secondary',
      'specialTeams': 'Special teams',
      'other': '$group',
    });
    return '$_temp0';
  }

  @override
  String positionGroupShort(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'quarterback': 'QB',
      'runningBack': 'RB',
      'receiver': 'WR / TE',
      'offensiveLine': 'OL',
      'frontSeven': 'Front 7',
      'secondary': 'DB',
      'specialTeams': 'K',
      'other': '$group',
    });
    return '$_temp0';
  }

  @override
  String positionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'QB': 'Quarterback',
      'RB': 'Running back',
      'FB': 'Fullback',
      'WR': 'Wide receiver',
      'TE': 'Tight end',
      'OL': 'Offensive lineman',
      'DE': 'Defensive end',
      'DT': 'Defensive tackle',
      'DL': 'Defensive lineman',
      'LB': 'Linebacker',
      'CB': 'Cornerback',
      'S': 'Safety',
      'DB': 'Defensive back',
      'K': 'Kicker',
      'P': 'Punter',
      'LS': 'Long snapper',
      'PG': 'Point guard',
      'SG': 'Shooting guard',
      'SF': 'Small forward',
      'PF': 'Power forward',
      'C': 'Center',
      'G': 'Guard',
      'F': 'Forward',
      'GK': 'Goalkeeper',
      'DEF': 'Defender',
      'MID': 'Midfielder',
      'FWD': 'Forward',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String statLabel(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'pointsPerGame': 'Points / game',
      'pointsAllowedPerGame': 'Points allowed / game',
      'yardsPerGame': 'Yards / game',
      'passYardsPerGame': 'Pass yards / game',
      'rushYardsPerGame': 'Rush yards / game',
      'yardsAllowedPerGame': 'Yards allowed / game',
      'turnoverDifferential': 'Turnover differential',
      'sacks': 'Sacks',
      'thirdDownConversion': '3rd-down conversion',
      'redZoneTdRate': 'Red-zone TD rate',
      'gamesPlayed': 'Games played',
      'completionPct': 'Completion %',
      'passYards': 'Pass yards',
      'passTd': 'Pass TD',
      'interceptionsThrown': 'Interceptions thrown',
      'passerRating': 'Passer rating',
      'carries': 'Carries',
      'rushYards': 'Rush yards',
      'yardsPerCarry': 'Yards / carry',
      'rushTd': 'Rush TD',
      'fumblesLost': 'Fumbles lost',
      'targets': 'Targets',
      'receptions': 'Receptions',
      'receivingYards': 'Receiving yards',
      'yardsPerCatch': 'Yards / catch',
      'receivingTd': 'Receiving TD',
      'tackles': 'Tackles',
      'tacklesForLoss': 'Tackles for loss',
      'qbHits': 'QB hits',
      'interceptions': 'Interceptions',
      'passesDefended': 'Passes defended',
      'forcedFumbles': 'Forced fumbles',
      'fieldGoalsMade': 'Field goals made',
      'fieldGoalsAttempted': 'Field goals attempted',
      'fieldGoalPct': 'Field goal %',
      'longestFg': 'Longest FG',
      'extraPointPct': 'Extra point %',
      'reboundsPerGame': 'Rebounds / game',
      'assistsPerGame': 'Assists / game',
      'stealsPerGame': 'Steals / game',
      'blocksPerGame': 'Blocks / game',
      'threePointPct': 'Three-point %',
      'goalsPerGame': 'Goals / game',
      'goalsAllowedPerGame': 'Goals allowed / game',
      'possession': 'Possession',
      'shotsPerGame': 'Shots / game',
      'shotsOnTargetPerGame': 'Shots on target / game',
      'expectedGoals': 'Expected goals',
      'expectedGoalsAgainst': 'Expected goals against',
      'cleanSheetRate': 'Clean sheet rate',
      'points': 'Points',
      'rebounds': 'Rebounds',
      'assists': 'Assists',
      'steals': 'Steals',
      'blocks': 'Blocks',
      'turnovers': 'Turnovers',
      'saves': 'Saves',
      'goalsAllowed': 'Goals allowed',
      'cleanSheets': 'Clean sheets',
      'savePct': 'Save %',
      'clearances': 'Clearances',
      'passPct': 'Pass %',
      'goals': 'Goals',
      'keyPasses': 'Key passes',
      'shots': 'Shots',
      'shotsOnTarget': 'Shots on target',
      'recentScored': 'Points scored / game',
      'recentAllowed': 'Points allowed / game',
      'recentMargin': 'Scoring margin / game',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String scoringRateAbbrev(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'goals': 'GPG',
      'other': 'PPG',
    });
    return '$_temp0';
  }

  @override
  String loadFailure(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'timeout': 'The live feed took too long to respond.',
      'network': 'Could not reach the live feed. Check your connection.',
      'server': 'The live feed is having problems right now.',
      'other': 'The live feed returned incomplete data.',
    });
    return '$_temp0';
  }

  @override
  String feedGap(String part, int failed, int total) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'teamStats': '$failed of $total team stat lines did not load.',
      'rosters': '$failed of $total rosters did not load.',
      'schedules': '$failed of $total schedules did not load.',
      'other': '$failed of $total items did not load.',
    });
    return '$_temp0';
  }

  @override
  String get feedProblemsTitle => 'Live data problems';

  @override
  String feedShowingSample(String league) {
    return '$league: showing sample data';
  }

  @override
  String feedLiveIncomplete(String league) {
    return '$league: live, incomplete';
  }

  @override
  String get feedBannerHint => 'Shows which live data failed to load';

  @override
  String feedBannerUnavailable(int count, String leagues) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Live $leagues feeds unavailable — showing sample data.',
      one: 'Live $leagues feed unavailable — showing sample data.',
    );
    return '$_temp0';
  }

  @override
  String feedBannerMissing(String leagues) {
    return 'Some $leagues data is missing.';
  }

  @override
  String get featuredSaved => 'Your saved matchup';

  @override
  String featuredTop(String league) {
    return 'Top of the $league';
  }

  @override
  String get newHeadToHead => 'New head-to-head';

  @override
  String get openThemeSettings => 'Open theme settings';

  @override
  String get searchTeamsPlayers => 'Search teams and players';

  @override
  String get headToHeadTitle => 'Head-to-Head';

  @override
  String get headToHeadSubtitle =>
      'Compare two teams and see who is projected to win';

  @override
  String get teamStatsTitle => 'Team Stats';

  @override
  String get teamStatsSubtitle => 'Season numbers, form, roster, and injuries';

  @override
  String get upcomingGamesTitle => 'Upcoming games';

  @override
  String get upcomingGamesSubtitle =>
      'Choose a scheduled game to compare both teams instantly';

  @override
  String get favoriteTeams => 'Favorite teams';

  @override
  String get favoriteTeamsEmptyHint =>
      'Star a team on its profile to pin it here';

  @override
  String get viewAll => 'View all';

  @override
  String get noFavorites => 'No favorites yet. Open any team and tap the star.';

  @override
  String get savedMatchups => 'Saved matchups';

  @override
  String get savedMatchupsEmptyHint => 'Bookmark a head-to-head to see it here';

  @override
  String get noSavedMatchups =>
      'No saved matchups yet. Open a matchup and tap the bookmark.';

  @override
  String get dataSourceSample =>
      'Sample league data: teams and players are fictional while testing.';

  @override
  String get dataSourceAllLive =>
      'Teams, rosters, games, and stats load live from ESPN.';

  @override
  String dataSourceMixed(String live, String sample, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$sample show sample data.',
      one: '$sample shows sample data.',
    );
    return '$live data loads live from ESPN. $_temp0';
  }

  @override
  String get savedTitle => 'Saved';

  @override
  String pinnedCount(int count) {
    return '$count pinned';
  }

  @override
  String bookmarkedCount(int count) {
    return '$count bookmarked';
  }

  @override
  String recordWinRate(String record, int percent) {
    return '$record · $percent% win rate';
  }

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String get addFavorite => 'Add favorite';

  @override
  String get loginTagline =>
      'Browse live and sample team stats. Sign-in is demo-only.';

  @override
  String get loginDemoBanner =>
      'Demo mode: email, Google, and Apple do not verify accounts or store passwords. Use Continue as guest for the same access.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String passwordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get signInDemo => 'Sign in (demo)';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get guestSnack => 'Continuing in demo mode (no account).';

  @override
  String get demoSignInSnack =>
      'Demo sign-in only — credentials are not verified.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSubtitle => 'System follows your device setting';

  @override
  String themeMode(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'light': 'Light',
      'dark': 'Dark',
      'other': 'System',
    });
    return '$_temp0';
  }

  @override
  String themeSemantics(String mode) {
    return '$mode theme';
  }

  @override
  String get themeSaveFailed => 'Could not save the theme. Try again.';

  @override
  String get dataSection => 'Data';

  @override
  String get liveData => 'Live data';

  @override
  String get sampleData => 'Sample data';

  @override
  String get settingsSampleOnly =>
      'Teams and players are fictional while testing.';

  @override
  String get settingsAllLive =>
      'Teams, rosters, games, and player stats load from ESPN.';

  @override
  String settingsMixed(String live, String sample, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$sample could not load and use sample data.',
      one: '$sample could not load and uses sample data.',
    );
    return '$live load from ESPN. $_temp0';
  }

  @override
  String get selectSport => 'Select a sport';

  @override
  String get chooseSportMatchup => 'Choose a sport to compare two teams.';

  @override
  String get chooseSportBrowse => 'Choose a sport to browse team stats.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get noTeamsTitle => 'No teams available';

  @override
  String get noTeamsBody =>
      'Team data could not be loaded. Please try again later.';

  @override
  String sportMatchupTitle(String sport) {
    return '$sport matchup';
  }

  @override
  String sportTeamsTitle(String sport) {
    return '$sport teams';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get compareTeams => 'Compare teams';

  @override
  String get showHiddenTeams => 'Show hidden teams';

  @override
  String get showHiddenTeamsHint =>
      'Use the eye button beside a team to hide or restore it.';

  @override
  String get teamASlot => 'Team A';

  @override
  String get teamBSlot => 'Team B';

  @override
  String get slotA => 'A';

  @override
  String get slotB => 'B';

  @override
  String get versusShort => 'VS';

  @override
  String get selectionNone => '0 of 2 teams selected — choose Team A.';

  @override
  String get selectionReady => '2 of 2 teams selected — ready to compare.';

  @override
  String get selectionNeedA => '1 of 2 teams selected — choose Team A.';

  @override
  String get selectionNeedB => '1 of 2 teams selected — choose Team B.';

  @override
  String matchupInstructions(String league) {
    return 'Tap two $league teams. Tap a selected team again to remove it.';
  }

  @override
  String singleInstructions(String league) {
    return 'Choose a $league team to see its season.';
  }

  @override
  String get noVisibleTeams => 'No visible teams';

  @override
  String get noVisibleTeamsHint =>
      'Turn on Show hidden teams or select another league.';

  @override
  String conferenceTitle(String name) {
    return '$name Conference';
  }

  @override
  String get independentTeams => 'Independent';

  @override
  String get hiddenSaveFailed => 'Could not save hidden teams. Try again.';

  @override
  String removeTeam(String team) {
    return 'Remove $team';
  }

  @override
  String get pickATeam => 'Pick a team';

  @override
  String teamRowSubtitle(
    String record,
    String scored,
    String rate,
    String allowed,
  ) {
    return '$record · $scored $rate · $allowed allowed';
  }

  @override
  String restoreTeam(String team) {
    return 'Restore $team';
  }

  @override
  String hideTeam(String team) {
    return 'Hide $team';
  }

  @override
  String matchupTitle(String a, String b) {
    return '$a vs $b';
  }

  @override
  String get removeSavedMatchup => 'Remove saved matchup';

  @override
  String get saveMatchup => 'Save matchup';

  @override
  String get gamePreview => 'Game preview';

  @override
  String get projected => 'Projected';

  @override
  String get winProbability => 'Win probability';

  @override
  String get margin => 'Margin';

  @override
  String get marginEven => 'Even';

  @override
  String marginBy(String team, String points) {
    return '$team by $points';
  }

  @override
  String get combined => 'Combined';

  @override
  String venueAt(String team) {
    return '@ $team';
  }

  @override
  String get venueNeutral => 'Neutral';

  @override
  String get comparePlayers => 'Compare players';

  @override
  String get performance => 'Performance';

  @override
  String outlookTitle(String team) {
    return '$team outlook';
  }

  @override
  String outlookSubtitle(String team, String league) {
    return 'How $team grades against the $league';
  }

  @override
  String outlookSubtitleNoLeague(String team) {
    return 'How $team grades against the league';
  }

  @override
  String get projectionDrivers => 'What drives the projection';

  @override
  String get projectionDriversSubtitle =>
      'Season form, scoring margin, venue, and who is out';

  @override
  String get recentComparison => 'Recent-game comparison';

  @override
  String recentComparisonSubtitle(int count) {
    return 'Average over up to $count completed games per team';
  }

  @override
  String get recentForm => 'Recent form';

  @override
  String recentFormSubtitle(int count) {
    return 'Last $count, newest first';
  }

  @override
  String get headToHeadSection => 'Head-to-head';

  @override
  String get noRecentMeetingsLong =>
      'These teams have not met in the last two seasons.';

  @override
  String get injuryReport => 'Injury report';

  @override
  String get noPlayersListed => 'No players listed';

  @override
  String get factorEven => 'EVEN';

  @override
  String get noCompletedGames =>
      'No completed games available for these teams.';

  @override
  String recentGamesCount(String a, int countA, String b, int countB) {
    String _temp0 = intl.Intl.pluralLogic(
      countA,
      locale: localeName,
      other: '$countA games',
      one: '1 game',
    );
    String _temp1 = intl.Intl.pluralLogic(
      countB,
      locale: localeName,
      other: '$countB games',
      one: '1 game',
    );
    return '$a: $_temp0 · $b: $_temp1';
  }

  @override
  String factorTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'record': 'Record',
      'scoringMargin': 'Scoring margin',
      'offense': 'Offense',
      'defense': 'Defense',
      'turnovers': 'Turnovers',
      'shooting': 'Shooting',
      'rebounding': 'Rebounding',
      'chanceCreation': 'Chance creation',
      'chancePrevention': 'Chance prevention',
      'venue': 'Venue',
      'availability': 'Availability',
      'headToHead': 'Head-to-head',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String factorRecord(String a, String recordA, String b, String recordB) {
    return '$a $recordA vs $b $recordB';
  }

  @override
  String factorScoringMargin(String a, String b, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'goals': 'goals',
      'other': 'points',
    });
    return '$a vs $b $_temp0 per game';
  }

  @override
  String factorShooting(String a, String b) {
    return '$a vs $b field goal percentage';
  }

  @override
  String factorRebounding(String a, String b) {
    return '$a vs $b rebounds per game';
  }

  @override
  String factorChanceCreation(String a, String b) {
    return '$a vs $b expected goals per game';
  }

  @override
  String factorChancePrevention(String a, String b) {
    return '$a vs $b expected goals against per game';
  }

  @override
  String scoreLine(String a, String b) {
    return '$a : $b';
  }

  @override
  String factorOffense(String a, String b) {
    return '$a vs $b yards per game';
  }

  @override
  String factorDefense(String a, String b) {
    return '$a vs $b yards allowed per game';
  }

  @override
  String factorTurnovers(String a, String b) {
    return '$a vs $b turnover differential';
  }

  @override
  String get factorVenueNeutral => 'Neutral site, no home-field edge';

  @override
  String factorVenueHome(String city, int percent) {
    return '$city home field, worth about $percent%';
  }

  @override
  String factorTeamHealthy(String team) {
    return '$team healthy';
  }

  @override
  String factorTeamMissing(String team, String players) {
    return '$team: $players';
  }

  @override
  String missingPlayer(String position, String name, String status) {
    return '$position $name ($status)';
  }

  @override
  String get factorNoMeetings => 'No recent meetings';

  @override
  String factorHeadToHead(String a, int winsA, int winsB, String b, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meetings',
      one: 'meeting',
    );
    return '$a $winsA–$winsB $b in the last $_temp0 (context only, not weighted)';
  }

  @override
  String get spreadPickEm => 'Pick\'em';

  @override
  String spreadLine(String team, String points) {
    return '$team -$points';
  }

  @override
  String get strengths => 'Strengths';

  @override
  String get weaknesses => 'Weaknesses';

  @override
  String traitStrength(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'ppg': 'Explosive offense',
      'papg': 'Stingy defense',
      'ypg': 'Moves the chains',
      'passYpg': 'Aerial attack',
      'rushYpg': 'Physical run game',
      'yapg': 'Stout defense',
      'toDiff': 'Wins the turnover battle',
      'sacks': 'Gets after the passer',
      'thirdPct': 'Converts on schedule',
      'redZonePct': 'Finishes drives',
      'rpg': 'Dominates the glass',
      'apg': 'Unselfish ball movement',
      'spg': 'Creates turnovers',
      'bpg': 'Protects the rim',
      'fgPct': 'Efficient shooting',
      'threePct': 'Lights out from three',
      'possession': 'Controls the ball',
      'shotsPg': 'Creates chances',
      'sogPg': 'Gets shots on target',
      'xg': 'Creates high-quality chances',
      'xga': 'Limits quality chances against',
      'cleanSheetPct': 'Keeps clean sheets',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String traitWeakness(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'ppg': 'Struggles to score',
      'papg': 'Leaks points',
      'ypg': 'Stalled offense',
      'passYpg': 'Limited passing game',
      'rushYpg': 'Can\'t run the ball',
      'yapg': 'Gives up yards',
      'toDiff': 'Gives the ball away',
      'sacks': 'Rarely pressures the QB',
      'thirdPct': 'Stalls on third down',
      'redZonePct': 'Settles for field goals',
      'rpg': 'Loses the rebound battle',
      'apg': 'Isolation-heavy offense',
      'spg': 'Passive on the ball',
      'bpg': 'Gives up easy looks',
      'fgPct': 'Cold from the field',
      'threePct': 'Struggles from deep',
      'possession': 'Chases the game',
      'shotsPg': 'Rarely tests the keeper',
      'sogPg': 'Wayward finishing',
      'xg': 'Low expected goals',
      'xga': 'Concedes dangerous looks',
      'cleanSheetPct': 'Rarely shuts teams out',
      'other': '$key',
    });
    return '$_temp0';
  }

  @override
  String traitAboveAverage(String stat) {
    return 'Above average $stat';
  }

  @override
  String traitBelowAverage(String stat) {
    return 'Below average $stat';
  }

  @override
  String traitDetail(String value, String rank, int total, String league) {
    return '$value · $rank of $total in $league';
  }

  @override
  String traitDetailNoLeague(String value, String rank, int total) {
    return '$value · $rank of $total in the league';
  }

  @override
  String outlookNotGraded(String team) {
    return 'Not enough league data yet to grade $team against peers.';
  }

  @override
  String outlookMiddle(String team, String league) {
    return '$team grades out as a middle-of-the-pack $league club this season — no stat stands far above or below the league.';
  }

  @override
  String outlookMiddleNoLeague(String team) {
    return '$team grades out as a middle-of-the-pack club this season — no stat stands far above or below the league.';
  }

  @override
  String outlookStrongestOne(String team, String first) {
    return '$team is strongest in $first.';
  }

  @override
  String outlookStrongestTwo(String team, String first, String second) {
    return '$team is strongest in $first and $second.';
  }

  @override
  String outlookNoEdge(String team) {
    return '$team does not have a clear statistical edge this season.';
  }

  @override
  String outlookConcern(String weakness, String value) {
    return 'The main concern is $weakness ($value).';
  }

  @override
  String seasonLabel(String season) {
    return '$season season';
  }

  @override
  String get statRecord => 'Record';

  @override
  String get statWinPct => 'Win %';

  @override
  String get statPointDiff => 'Pt diff / g';

  @override
  String lastNGames(int count) {
    return 'Last $count';
  }

  @override
  String get compareAgainstAnother => 'Compare against another team';

  @override
  String get strengthsWeaknesses => 'Strengths & weaknesses';

  @override
  String get rankedAgainstLeague => 'Ranked against the rest of the league';

  @override
  String get seasonStats => 'Season stats';

  @override
  String get scoringTrend => 'Scoring trend';

  @override
  String get scoringTrendSubtitle => 'Points scored in recent games';

  @override
  String get recentResults => 'Recent results';

  @override
  String get noRecentResults => 'No completed games yet.';

  @override
  String get everyoneAvailable => 'Everyone is available';

  @override
  String playersListed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players listed',
      one: '1 player listed',
    );
    return '$_temp0';
  }

  @override
  String get roster => 'Roster';

  @override
  String get rosterSubtitle => 'Tap a player for details';

  @override
  String get statProfile => 'Stat profile';

  @override
  String get statProfileSubtitle => 'Selected season totals';

  @override
  String get bioTeam => 'Team';

  @override
  String get bioAge => 'Age';

  @override
  String get bioHeight => 'Height';

  @override
  String get bioWeight => 'Weight';

  @override
  String get bioClass => 'Class';

  @override
  String get bioExperience => 'Experience';

  @override
  String get bioCollege => 'College';

  @override
  String weightLbs(int weight) {
    return '$weight lb';
  }

  @override
  String get rookie => 'Rookie';

  @override
  String yearsPro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yrs',
      one: '1 yr',
    );
    return '$_temp0';
  }

  @override
  String get playerUnavailable => 'Player details are unavailable.';

  @override
  String get position => 'Position';

  @override
  String get differentPositions =>
      'Different positions: stats that only apply to one player show a dash for the other.';

  @override
  String get noPlayerAtPosition =>
      'One of these teams has no player listed at this position.';

  @override
  String pickerItem(String position, String initial, String last) {
    return '$position $initial. $last';
  }

  @override
  String pickerItemUnavailable(
    String position,
    String initial,
    String last,
    String status,
  ) {
    return '$position $initial. $last ($status)';
  }

  @override
  String get noSharedStats => 'No shared stats to compare';

  @override
  String deadEven(int a, int b) {
    return 'Dead even: $a–$b in shared stats';
  }

  @override
  String leadsCategories(String name, int wins, int total) {
    return '$name leads $wins of $total categories';
  }

  @override
  String openPlayer(String name) {
    return 'Open $name';
  }

  @override
  String get upcomingIntro => 'Choose a scheduled game to compare both teams.';

  @override
  String get sportSection => 'Sport';

  @override
  String get leagueSection => 'League';

  @override
  String get allLeagues => 'All';

  @override
  String noUpcomingGames(String sport) {
    return 'No upcoming $sport games are available right now.';
  }

  @override
  String gameAtShort(String away, String home) {
    return '$away @ $home';
  }

  @override
  String gameAtLong(String away, String home) {
    return '$away at $home';
  }

  @override
  String gameWhen(String date, String time) {
    return '$date · $time';
  }

  @override
  String gameWhenVenue(String date, String time, String venue) {
    return '$date · $time · $venue';
  }

  @override
  String get searchHint => 'Search teams or players';

  @override
  String get searchPrompt => 'Type a team or player name';

  @override
  String noMatches(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String get teamsSection => 'Teams';

  @override
  String get playersSection => 'Players';

  @override
  String jerseyNumber(int number) {
    return '#$number';
  }

  @override
  String get savedMatchupLabel => 'Saved matchup';

  @override
  String get winLabel => 'Win';

  @override
  String get gamePreviewHero => 'Game\npreview';

  @override
  String favoriteToWinNeutral(String favorite) {
    return '$favorite to win · neutral site';
  }

  @override
  String favoriteChance(String team, int percent) {
    return '$team $percent%';
  }

  @override
  String get versusLower => 'vs';

  @override
  String winProbabilitySemantics(
    String teamA,
    int pctA,
    String teamB,
    int pctB,
  ) {
    return '$teamA $pctA percent, $teamB $pctB percent';
  }

  @override
  String get noGamesYet => 'No games yet';

  @override
  String formResult(String result) {
    String _temp0 = intl.Intl.selectLogic(result, {
      'win': 'W',
      'loss': 'L',
      'tie': 'T',
      'other': '–',
    });
    return '$_temp0';
  }

  @override
  String formResultSemantics(String result) {
    String _temp0 = intl.Intl.selectLogic(result, {
      'win': 'Win',
      'loss': 'Loss',
      'tie': 'Tie',
      'other': 'No result',
    });
    return '$_temp0';
  }

  @override
  String resultVs(String team) {
    return 'vs $team';
  }

  @override
  String resultAt(String team) {
    return '@ $team';
  }

  @override
  String resultScore(String result, String mine, String theirs) {
    return '$result $mine–$theirs';
  }

  @override
  String get noRecentScores => 'No recent scores to chart';

  @override
  String get noChartableStats => 'No chartable season stats yet';

  @override
  String get couldNotLoadSeasonStats => 'Could not load season stats.';

  @override
  String get loadingSeasonStats => 'Loading season stats…';

  @override
  String get dotSeparator => ' · ';

  @override
  String sentenceJoin(String first, String second) {
    return '$first $second';
  }

  @override
  String chartRecentScores(int count, String scores) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games',
      one: 'game',
    );
    return 'Points scored in the last $_temp0, oldest first: $scores';
  }

  @override
  String chartStatValue(String stat, String value) {
    return '$stat: $value';
  }

  @override
  String chartPlayerStats(String stats) {
    return 'Season totals. $stats';
  }

  @override
  String moreTeams(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more teams — refine your search',
      one: '1 more team — refine your search',
    );
    return '$_temp0';
  }
}
