import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'StatMyTeam'**
  String get appTitle;

  /// No description provided for @bootFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not start StatMyTeam'**
  String get bootFailedTitle;

  /// No description provided for @bootFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading. Check your connection and try again.'**
  String get bootFailedBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadingLiveData.
  ///
  /// In en, this message translates to:
  /// **'Loading live league data…'**
  String get loadingLiveData;

  /// No description provided for @errorWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorWidgetTitle;

  /// No description provided for @errorWidgetBody.
  ///
  /// In en, this message translates to:
  /// **'This part of the screen could not be shown.'**
  String get errorWidgetBody;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your change. Try again.'**
  String get saveFailed;

  /// No description provided for @noValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get noValue;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get navTeams;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @listTwo.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String listTwo(String first, String second);

  /// No description provided for @listMany.
  ///
  /// In en, this message translates to:
  /// **'{items}, and {last}'**
  String listMany(String items, String last);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @sportName.
  ///
  /// In en, this message translates to:
  /// **'{sport, select, basketball{Basketball} football{Football} baseball{Baseball} hockey{Hockey} soccer{Soccer} other{{sport}}}'**
  String sportName(String sport);

  /// No description provided for @sportMenuName.
  ///
  /// In en, this message translates to:
  /// **'{sport, select, basketball{Basketball} football{American Football} baseball{Baseball} hockey{Hockey} soccer{Soccer} other{{sport}}}'**
  String sportMenuName(String sport);

  /// No description provided for @sportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{sport, select, football{NFL and college teams} basketball{NBA clubs} soccer{MLS clubs} other{}}'**
  String sportSubtitle(String sport);

  /// No description provided for @leagueLevel.
  ///
  /// In en, this message translates to:
  /// **'{league, select, nfl{Pro} ncaa{College} nba{Pro} mls{Pro} ufl{Spring pro} cfl{Canadian pro} highSchool{High school} other{{league}}}'**
  String leagueLevel(String league);

  /// No description provided for @playerStatus.
  ///
  /// In en, this message translates to:
  /// **'{status, select, active{Active} questionable{Questionable} out{Out} injuredReserve{Injured reserve} other{{status}}}'**
  String playerStatus(String status);

  /// No description provided for @playerStatusShort.
  ///
  /// In en, this message translates to:
  /// **'{status, select, active{ACT} questionable{Q} out{OUT} injuredReserve{IR} other{{status}}}'**
  String playerStatusShort(String status);

  /// No description provided for @depthRole.
  ///
  /// In en, this message translates to:
  /// **'{role, select, starter{Starter} rotation{Rotation} backup{Backup} other{{role}}}'**
  String depthRole(String role);

  /// No description provided for @positionGroupName.
  ///
  /// In en, this message translates to:
  /// **'{group, select, quarterback{Quarterbacks} runningBack{Running backs} receiver{Receivers} offensiveLine{Offensive line} frontSeven{Front seven} secondary{Secondary} specialTeams{Special teams} other{{group}}}'**
  String positionGroupName(String group);

  /// No description provided for @positionGroupShort.
  ///
  /// In en, this message translates to:
  /// **'{group, select, quarterback{QB} runningBack{RB} receiver{WR / TE} offensiveLine{OL} frontSeven{Front 7} secondary{DB} specialTeams{K} other{{group}}}'**
  String positionGroupShort(String group);

  /// No description provided for @positionName.
  ///
  /// In en, this message translates to:
  /// **'{code, select, QB{Quarterback} RB{Running back} FB{Fullback} WR{Wide receiver} TE{Tight end} OL{Offensive lineman} DE{Defensive end} DT{Defensive tackle} DL{Defensive lineman} LB{Linebacker} CB{Cornerback} S{Safety} DB{Defensive back} K{Kicker} P{Punter} LS{Long snapper} PG{Point guard} SG{Shooting guard} SF{Small forward} PF{Power forward} C{Center} G{Guard} F{Forward} GK{Goalkeeper} DEF{Defender} MID{Midfielder} FWD{Forward} other{{code}}}'**
  String positionName(String code);

  /// No description provided for @statLabel.
  ///
  /// In en, this message translates to:
  /// **'{key, select, pointsPerGame{Points / game} pointsAllowedPerGame{Points allowed / game} yardsPerGame{Yards / game} passYardsPerGame{Pass yards / game} rushYardsPerGame{Rush yards / game} yardsAllowedPerGame{Yards allowed / game} turnoverDifferential{Turnover differential} sacks{Sacks} thirdDownConversion{3rd-down conversion} redZoneTdRate{Red-zone TD rate} gamesPlayed{Games played} completionPct{Completion %} passYards{Pass yards} passTd{Pass TD} interceptionsThrown{Interceptions thrown} passerRating{Passer rating} carries{Carries} rushYards{Rush yards} yardsPerCarry{Yards / carry} rushTd{Rush TD} fumblesLost{Fumbles lost} targets{Targets} receptions{Receptions} receivingYards{Receiving yards} yardsPerCatch{Yards / catch} receivingTd{Receiving TD} tackles{Tackles} tacklesForLoss{Tackles for loss} qbHits{QB hits} interceptions{Interceptions} passesDefended{Passes defended} forcedFumbles{Forced fumbles} fieldGoalsMade{Field goals made} fieldGoalsAttempted{Field goals attempted} fieldGoalPct{Field goal %} longestFg{Longest FG} extraPointPct{Extra point %} reboundsPerGame{Rebounds / game} assistsPerGame{Assists / game} stealsPerGame{Steals / game} blocksPerGame{Blocks / game} threePointPct{Three-point %} goalsPerGame{Goals / game} goalsAllowedPerGame{Goals allowed / game} possession{Possession} shotsPerGame{Shots / game} shotsOnTargetPerGame{Shots on target / game} expectedGoals{Expected goals} expectedGoalsAgainst{Expected goals against} cleanSheetRate{Clean sheet rate} points{Points} rebounds{Rebounds} assists{Assists} steals{Steals} blocks{Blocks} turnovers{Turnovers} saves{Saves} goalsAllowed{Goals allowed} cleanSheets{Clean sheets} savePct{Save %} clearances{Clearances} passPct{Pass %} goals{Goals} keyPasses{Key passes} shots{Shots} shotsOnTarget{Shots on target} recentScored{Points scored / game} recentAllowed{Points allowed / game} recentMargin{Scoring margin / game} other{{key}}}'**
  String statLabel(String key);

  /// No description provided for @scoringRateAbbrev.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, goals{GPG} other{PPG}}'**
  String scoringRateAbbrev(String kind);

  /// No description provided for @loadFailure.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, timeout{The live feed took too long to respond.} network{Could not reach the live feed. Check your connection.} server{The live feed is having problems right now.} other{The live feed returned incomplete data.}}'**
  String loadFailure(String kind);

  /// No description provided for @feedGap.
  ///
  /// In en, this message translates to:
  /// **'{part, select, teamStats{{failed} of {total} team stat lines did not load.} rosters{{failed} of {total} rosters did not load.} schedules{{failed} of {total} schedules did not load.} other{{failed} of {total} items did not load.}}'**
  String feedGap(String part, int failed, int total);

  /// No description provided for @feedProblemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Live data problems'**
  String get feedProblemsTitle;

  /// No description provided for @feedShowingSample.
  ///
  /// In en, this message translates to:
  /// **'{league}: showing sample data'**
  String feedShowingSample(String league);

  /// No description provided for @feedLiveIncomplete.
  ///
  /// In en, this message translates to:
  /// **'{league}: live, incomplete'**
  String feedLiveIncomplete(String league);

  /// No description provided for @feedBannerHint.
  ///
  /// In en, this message translates to:
  /// **'Shows which live data failed to load'**
  String get feedBannerHint;

  /// No description provided for @feedBannerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Live {leagues} feed unavailable — showing sample data.} other{Live {leagues} feeds unavailable — showing sample data.}}'**
  String feedBannerUnavailable(int count, String leagues);

  /// No description provided for @feedBannerMissing.
  ///
  /// In en, this message translates to:
  /// **'Some {leagues} data is missing.'**
  String feedBannerMissing(String leagues);

  /// No description provided for @featuredSaved.
  ///
  /// In en, this message translates to:
  /// **'Your saved matchup'**
  String get featuredSaved;

  /// No description provided for @featuredTop.
  ///
  /// In en, this message translates to:
  /// **'Top of the {league}'**
  String featuredTop(String league);

  /// No description provided for @newHeadToHead.
  ///
  /// In en, this message translates to:
  /// **'New head-to-head'**
  String get newHeadToHead;

  /// No description provided for @openThemeSettings.
  ///
  /// In en, this message translates to:
  /// **'Open theme settings'**
  String get openThemeSettings;

  /// No description provided for @searchTeamsPlayers.
  ///
  /// In en, this message translates to:
  /// **'Search teams and players'**
  String get searchTeamsPlayers;

  /// No description provided for @headToHeadTitle.
  ///
  /// In en, this message translates to:
  /// **'Head-to-Head'**
  String get headToHeadTitle;

  /// No description provided for @headToHeadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare two teams and see who is projected to win'**
  String get headToHeadSubtitle;

  /// No description provided for @teamStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Stats'**
  String get teamStatsTitle;

  /// No description provided for @teamStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Season numbers, form, roster, and injuries'**
  String get teamStatsSubtitle;

  /// No description provided for @upcomingGamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming games'**
  String get upcomingGamesTitle;

  /// No description provided for @upcomingGamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a scheduled game to compare both teams instantly'**
  String get upcomingGamesSubtitle;

  /// No description provided for @favoriteTeams.
  ///
  /// In en, this message translates to:
  /// **'Favorite teams'**
  String get favoriteTeams;

  /// No description provided for @favoriteTeamsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Star a team on its profile to pin it here'**
  String get favoriteTeamsEmptyHint;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet. Open any team and tap the star.'**
  String get noFavorites;

  /// No description provided for @savedMatchups.
  ///
  /// In en, this message translates to:
  /// **'Saved matchups'**
  String get savedMatchups;

  /// No description provided for @savedMatchupsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a head-to-head to see it here'**
  String get savedMatchupsEmptyHint;

  /// No description provided for @noSavedMatchups.
  ///
  /// In en, this message translates to:
  /// **'No saved matchups yet. Open a matchup and tap the bookmark.'**
  String get noSavedMatchups;

  /// No description provided for @dataSourceSample.
  ///
  /// In en, this message translates to:
  /// **'Sample league data: teams and players are fictional while testing.'**
  String get dataSourceSample;

  /// No description provided for @dataSourceAllLive.
  ///
  /// In en, this message translates to:
  /// **'Teams, rosters, games, and stats load live from ESPN.'**
  String get dataSourceAllLive;

  /// No description provided for @dataSourceMixed.
  ///
  /// In en, this message translates to:
  /// **'{live} data loads live from ESPN. {count, plural, =1{{sample} shows sample data.} other{{sample} show sample data.}}'**
  String dataSourceMixed(String live, String sample, int count);

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @pinnedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pinned'**
  String pinnedCount(int count);

  /// No description provided for @bookmarkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bookmarked'**
  String bookmarkedCount(int count);

  /// No description provided for @recordWinRate.
  ///
  /// In en, this message translates to:
  /// **'{record} · {percent}% win rate'**
  String recordWinRate(String record, int percent);

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get removeFavorite;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add favorite'**
  String get addFavorite;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Browse live and sample team stats. Sign-in is demo-only.'**
  String get loginTagline;

  /// No description provided for @loginDemoBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode: email, Google, and Apple do not verify accounts or store passwords. Use Continue as guest for the same access.'**
  String get loginDemoBanner;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String passwordTooShort(int min);

  /// No description provided for @signInDemo.
  ///
  /// In en, this message translates to:
  /// **'Sign in (demo)'**
  String get signInDemo;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @guestSnack.
  ///
  /// In en, this message translates to:
  /// **'Continuing in demo mode (no account).'**
  String get guestSnack;

  /// No description provided for @demoSignInSnack.
  ///
  /// In en, this message translates to:
  /// **'Demo sign-in only — credentials are not verified.'**
  String get demoSignInSnack;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System follows your device setting'**
  String get appearanceSubtitle;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, light{Light} dark{Dark} other{System}}'**
  String themeMode(String mode);

  /// No description provided for @themeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{mode} theme'**
  String themeSemantics(String mode);

  /// No description provided for @themeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the theme. Try again.'**
  String get themeSaveFailed;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @liveData.
  ///
  /// In en, this message translates to:
  /// **'Live data'**
  String get liveData;

  /// No description provided for @sampleData.
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get sampleData;

  /// No description provided for @settingsSampleOnly.
  ///
  /// In en, this message translates to:
  /// **'Teams and players are fictional while testing.'**
  String get settingsSampleOnly;

  /// No description provided for @settingsAllLive.
  ///
  /// In en, this message translates to:
  /// **'Teams, rosters, games, and player stats load from ESPN.'**
  String get settingsAllLive;

  /// No description provided for @settingsMixed.
  ///
  /// In en, this message translates to:
  /// **'{live} load from ESPN. {count, plural, =1{{sample} could not load and uses sample data.} other{{sample} could not load and use sample data.}}'**
  String settingsMixed(String live, String sample, int count);

  /// No description provided for @selectSport.
  ///
  /// In en, this message translates to:
  /// **'Select a sport'**
  String get selectSport;

  /// No description provided for @chooseSportMatchup.
  ///
  /// In en, this message translates to:
  /// **'Choose a sport to compare two teams.'**
  String get chooseSportMatchup;

  /// No description provided for @chooseSportBrowse.
  ///
  /// In en, this message translates to:
  /// **'Choose a sport to browse team stats.'**
  String get chooseSportBrowse;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @noTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'No teams available'**
  String get noTeamsTitle;

  /// No description provided for @noTeamsBody.
  ///
  /// In en, this message translates to:
  /// **'Team data could not be loaded. Please try again later.'**
  String get noTeamsBody;

  /// No description provided for @sportMatchupTitle.
  ///
  /// In en, this message translates to:
  /// **'{sport} matchup'**
  String sportMatchupTitle(String sport);

  /// No description provided for @sportTeamsTitle.
  ///
  /// In en, this message translates to:
  /// **'{sport} teams'**
  String sportTeamsTitle(String sport);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @compareTeams.
  ///
  /// In en, this message translates to:
  /// **'Compare teams'**
  String get compareTeams;

  /// No description provided for @showHiddenTeams.
  ///
  /// In en, this message translates to:
  /// **'Show hidden teams'**
  String get showHiddenTeams;

  /// No description provided for @showHiddenTeamsHint.
  ///
  /// In en, this message translates to:
  /// **'Use the eye button beside a team to hide or restore it.'**
  String get showHiddenTeamsHint;

  /// No description provided for @teamASlot.
  ///
  /// In en, this message translates to:
  /// **'Team A'**
  String get teamASlot;

  /// No description provided for @teamBSlot.
  ///
  /// In en, this message translates to:
  /// **'Team B'**
  String get teamBSlot;

  /// No description provided for @slotA.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get slotA;

  /// No description provided for @slotB.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get slotB;

  /// No description provided for @versusShort.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get versusShort;

  /// No description provided for @selectionNone.
  ///
  /// In en, this message translates to:
  /// **'0 of 2 teams selected — choose Team A.'**
  String get selectionNone;

  /// No description provided for @selectionReady.
  ///
  /// In en, this message translates to:
  /// **'2 of 2 teams selected — ready to compare.'**
  String get selectionReady;

  /// No description provided for @selectionNeedA.
  ///
  /// In en, this message translates to:
  /// **'1 of 2 teams selected — choose Team A.'**
  String get selectionNeedA;

  /// No description provided for @selectionNeedB.
  ///
  /// In en, this message translates to:
  /// **'1 of 2 teams selected — choose Team B.'**
  String get selectionNeedB;

  /// No description provided for @matchupInstructions.
  ///
  /// In en, this message translates to:
  /// **'Tap two {league} teams. Tap a selected team again to remove it.'**
  String matchupInstructions(String league);

  /// No description provided for @singleInstructions.
  ///
  /// In en, this message translates to:
  /// **'Choose a {league} team to see its season.'**
  String singleInstructions(String league);

  /// No description provided for @noVisibleTeams.
  ///
  /// In en, this message translates to:
  /// **'No visible teams'**
  String get noVisibleTeams;

  /// No description provided for @noVisibleTeamsHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on Show hidden teams or select another league.'**
  String get noVisibleTeamsHint;

  /// No description provided for @conferenceTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Conference'**
  String conferenceTitle(String name);

  /// No description provided for @independentTeams.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get independentTeams;

  /// No description provided for @hiddenSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save hidden teams. Try again.'**
  String get hiddenSaveFailed;

  /// No description provided for @removeTeam.
  ///
  /// In en, this message translates to:
  /// **'Remove {team}'**
  String removeTeam(String team);

  /// No description provided for @pickATeam.
  ///
  /// In en, this message translates to:
  /// **'Pick a team'**
  String get pickATeam;

  /// No description provided for @teamRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{record} · {scored} {rate} · {allowed} allowed'**
  String teamRowSubtitle(
    String record,
    String scored,
    String rate,
    String allowed,
  );

  /// No description provided for @restoreTeam.
  ///
  /// In en, this message translates to:
  /// **'Restore {team}'**
  String restoreTeam(String team);

  /// No description provided for @hideTeam.
  ///
  /// In en, this message translates to:
  /// **'Hide {team}'**
  String hideTeam(String team);

  /// No description provided for @matchupTitle.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b}'**
  String matchupTitle(String a, String b);

  /// No description provided for @removeSavedMatchup.
  ///
  /// In en, this message translates to:
  /// **'Remove saved matchup'**
  String get removeSavedMatchup;

  /// No description provided for @saveMatchup.
  ///
  /// In en, this message translates to:
  /// **'Save matchup'**
  String get saveMatchup;

  /// No description provided for @gamePreview.
  ///
  /// In en, this message translates to:
  /// **'Game preview'**
  String get gamePreview;

  /// No description provided for @projected.
  ///
  /// In en, this message translates to:
  /// **'Projected'**
  String get projected;

  /// No description provided for @winProbability.
  ///
  /// In en, this message translates to:
  /// **'Win probability'**
  String get winProbability;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// No description provided for @marginEven.
  ///
  /// In en, this message translates to:
  /// **'Even'**
  String get marginEven;

  /// No description provided for @marginBy.
  ///
  /// In en, this message translates to:
  /// **'{team} by {points}'**
  String marginBy(String team, String points);

  /// No description provided for @combined.
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get combined;

  /// No description provided for @venueAt.
  ///
  /// In en, this message translates to:
  /// **'@ {team}'**
  String venueAt(String team);

  /// No description provided for @venueNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get venueNeutral;

  /// No description provided for @comparePlayers.
  ///
  /// In en, this message translates to:
  /// **'Compare players'**
  String get comparePlayers;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @outlookTitle.
  ///
  /// In en, this message translates to:
  /// **'{team} outlook'**
  String outlookTitle(String team);

  /// No description provided for @outlookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How {team} grades against the {league}'**
  String outlookSubtitle(String team, String league);

  /// No description provided for @outlookSubtitleNoLeague.
  ///
  /// In en, this message translates to:
  /// **'How {team} grades against the league'**
  String outlookSubtitleNoLeague(String team);

  /// No description provided for @projectionDrivers.
  ///
  /// In en, this message translates to:
  /// **'What drives the projection'**
  String get projectionDrivers;

  /// No description provided for @projectionDriversSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Season form, scoring margin, venue, and who is out'**
  String get projectionDriversSubtitle;

  /// No description provided for @recentComparison.
  ///
  /// In en, this message translates to:
  /// **'Recent-game comparison'**
  String get recentComparison;

  /// No description provided for @recentComparisonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Average over up to {count} completed games per team'**
  String recentComparisonSubtitle(int count);

  /// No description provided for @recentForm.
  ///
  /// In en, this message translates to:
  /// **'Recent form'**
  String get recentForm;

  /// No description provided for @recentFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last {count}, newest first'**
  String recentFormSubtitle(int count);

  /// No description provided for @headToHeadSection.
  ///
  /// In en, this message translates to:
  /// **'Head-to-head'**
  String get headToHeadSection;

  /// No description provided for @noRecentMeetingsLong.
  ///
  /// In en, this message translates to:
  /// **'These teams have not met in the last two seasons.'**
  String get noRecentMeetingsLong;

  /// No description provided for @injuryReport.
  ///
  /// In en, this message translates to:
  /// **'Injury report'**
  String get injuryReport;

  /// No description provided for @noPlayersListed.
  ///
  /// In en, this message translates to:
  /// **'No players listed'**
  String get noPlayersListed;

  /// No description provided for @factorEven.
  ///
  /// In en, this message translates to:
  /// **'EVEN'**
  String get factorEven;

  /// No description provided for @noCompletedGames.
  ///
  /// In en, this message translates to:
  /// **'No completed games available for these teams.'**
  String get noCompletedGames;

  /// No description provided for @recentGamesCount.
  ///
  /// In en, this message translates to:
  /// **'{a}: {countA, plural, =1{1 game} other{{countA} games}} · {b}: {countB, plural, =1{1 game} other{{countB} games}}'**
  String recentGamesCount(String a, int countA, String b, int countB);

  /// No description provided for @factorTitle.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, record{Record} scoringMargin{Scoring margin} offense{Offense} defense{Defense} turnovers{Turnovers} shooting{Shooting} rebounding{Rebounding} chanceCreation{Chance creation} chancePrevention{Chance prevention} venue{Venue} availability{Availability} headToHead{Head-to-head} other{{kind}}}'**
  String factorTitle(String kind);

  /// No description provided for @factorRecord.
  ///
  /// In en, this message translates to:
  /// **'{a} {recordA} vs {b} {recordB}'**
  String factorRecord(String a, String recordA, String b, String recordB);

  /// No description provided for @factorScoringMargin.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} {unit, select, goals{goals} other{points}} per game'**
  String factorScoringMargin(String a, String b, String unit);

  /// No description provided for @factorShooting.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} field goal percentage'**
  String factorShooting(String a, String b);

  /// No description provided for @factorRebounding.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} rebounds per game'**
  String factorRebounding(String a, String b);

  /// No description provided for @factorChanceCreation.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} expected goals per game'**
  String factorChanceCreation(String a, String b);

  /// No description provided for @factorChancePrevention.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} expected goals against per game'**
  String factorChancePrevention(String a, String b);

  /// No description provided for @scoreLine.
  ///
  /// In en, this message translates to:
  /// **'{a} : {b}'**
  String scoreLine(String a, String b);

  /// No description provided for @factorOffense.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} yards per game'**
  String factorOffense(String a, String b);

  /// No description provided for @factorDefense.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} yards allowed per game'**
  String factorDefense(String a, String b);

  /// No description provided for @factorTurnovers.
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} turnover differential'**
  String factorTurnovers(String a, String b);

  /// No description provided for @factorVenueNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral site, no home-field edge'**
  String get factorVenueNeutral;

  /// No description provided for @factorVenueHome.
  ///
  /// In en, this message translates to:
  /// **'{city} home field, worth about {percent}%'**
  String factorVenueHome(String city, int percent);

  /// No description provided for @factorTeamHealthy.
  ///
  /// In en, this message translates to:
  /// **'{team} healthy'**
  String factorTeamHealthy(String team);

  /// No description provided for @factorTeamMissing.
  ///
  /// In en, this message translates to:
  /// **'{team}: {players}'**
  String factorTeamMissing(String team, String players);

  /// No description provided for @missingPlayer.
  ///
  /// In en, this message translates to:
  /// **'{position} {name} ({status})'**
  String missingPlayer(String position, String name, String status);

  /// No description provided for @factorNoMeetings.
  ///
  /// In en, this message translates to:
  /// **'No recent meetings'**
  String get factorNoMeetings;

  /// No description provided for @factorHeadToHead.
  ///
  /// In en, this message translates to:
  /// **'{a} {winsA}–{winsB} {b} in the last {count, plural, =1{meeting} other{{count} meetings}} (context only, not weighted)'**
  String factorHeadToHead(String a, int winsA, int winsB, String b, int count);

  /// No description provided for @spreadPickEm.
  ///
  /// In en, this message translates to:
  /// **'Pick\'em'**
  String get spreadPickEm;

  /// No description provided for @spreadLine.
  ///
  /// In en, this message translates to:
  /// **'{team} -{points}'**
  String spreadLine(String team, String points);

  /// No description provided for @strengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get strengths;

  /// No description provided for @weaknesses.
  ///
  /// In en, this message translates to:
  /// **'Weaknesses'**
  String get weaknesses;

  /// No description provided for @traitStrength.
  ///
  /// In en, this message translates to:
  /// **'{key, select, ppg{Explosive offense} papg{Stingy defense} ypg{Moves the chains} passYpg{Aerial attack} rushYpg{Physical run game} yapg{Stout defense} toDiff{Wins the turnover battle} sacks{Gets after the passer} thirdPct{Converts on schedule} redZonePct{Finishes drives} rpg{Dominates the glass} apg{Unselfish ball movement} spg{Creates turnovers} bpg{Protects the rim} fgPct{Efficient shooting} threePct{Lights out from three} possession{Controls the ball} shotsPg{Creates chances} sogPg{Gets shots on target} xg{Creates high-quality chances} xga{Limits quality chances against} cleanSheetPct{Keeps clean sheets} other{{key}}}'**
  String traitStrength(String key);

  /// No description provided for @traitWeakness.
  ///
  /// In en, this message translates to:
  /// **'{key, select, ppg{Struggles to score} papg{Leaks points} ypg{Stalled offense} passYpg{Limited passing game} rushYpg{Can\'t run the ball} yapg{Gives up yards} toDiff{Gives the ball away} sacks{Rarely pressures the QB} thirdPct{Stalls on third down} redZonePct{Settles for field goals} rpg{Loses the rebound battle} apg{Isolation-heavy offense} spg{Passive on the ball} bpg{Gives up easy looks} fgPct{Cold from the field} threePct{Struggles from deep} possession{Chases the game} shotsPg{Rarely tests the keeper} sogPg{Wayward finishing} xg{Low expected goals} xga{Concedes dangerous looks} cleanSheetPct{Rarely shuts teams out} other{{key}}}'**
  String traitWeakness(String key);

  /// No description provided for @traitAboveAverage.
  ///
  /// In en, this message translates to:
  /// **'Above average {stat}'**
  String traitAboveAverage(String stat);

  /// No description provided for @traitBelowAverage.
  ///
  /// In en, this message translates to:
  /// **'Below average {stat}'**
  String traitBelowAverage(String stat);

  /// No description provided for @traitDetail.
  ///
  /// In en, this message translates to:
  /// **'{value} · {rank} of {total} in {league}'**
  String traitDetail(String value, String rank, int total, String league);

  /// No description provided for @traitDetailNoLeague.
  ///
  /// In en, this message translates to:
  /// **'{value} · {rank} of {total} in the league'**
  String traitDetailNoLeague(String value, String rank, int total);

  /// No description provided for @outlookNotGraded.
  ///
  /// In en, this message translates to:
  /// **'Not enough league data yet to grade {team} against peers.'**
  String outlookNotGraded(String team);

  /// No description provided for @outlookMiddle.
  ///
  /// In en, this message translates to:
  /// **'{team} grades out as a middle-of-the-pack {league} club this season — no stat stands far above or below the league.'**
  String outlookMiddle(String team, String league);

  /// No description provided for @outlookMiddleNoLeague.
  ///
  /// In en, this message translates to:
  /// **'{team} grades out as a middle-of-the-pack club this season — no stat stands far above or below the league.'**
  String outlookMiddleNoLeague(String team);

  /// No description provided for @outlookStrongestOne.
  ///
  /// In en, this message translates to:
  /// **'{team} is strongest in {first}.'**
  String outlookStrongestOne(String team, String first);

  /// No description provided for @outlookStrongestTwo.
  ///
  /// In en, this message translates to:
  /// **'{team} is strongest in {first} and {second}.'**
  String outlookStrongestTwo(String team, String first, String second);

  /// No description provided for @outlookNoEdge.
  ///
  /// In en, this message translates to:
  /// **'{team} does not have a clear statistical edge this season.'**
  String outlookNoEdge(String team);

  /// No description provided for @outlookConcern.
  ///
  /// In en, this message translates to:
  /// **'The main concern is {weakness} ({value}).'**
  String outlookConcern(String weakness, String value);

  /// No description provided for @seasonLabel.
  ///
  /// In en, this message translates to:
  /// **'{season} season'**
  String seasonLabel(String season);

  /// No description provided for @statRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get statRecord;

  /// No description provided for @statWinPct.
  ///
  /// In en, this message translates to:
  /// **'Win %'**
  String get statWinPct;

  /// No description provided for @statPointDiff.
  ///
  /// In en, this message translates to:
  /// **'Pt diff / g'**
  String get statPointDiff;

  /// No description provided for @lastNGames.
  ///
  /// In en, this message translates to:
  /// **'Last {count}'**
  String lastNGames(int count);

  /// No description provided for @compareAgainstAnother.
  ///
  /// In en, this message translates to:
  /// **'Compare against another team'**
  String get compareAgainstAnother;

  /// No description provided for @strengthsWeaknesses.
  ///
  /// In en, this message translates to:
  /// **'Strengths & weaknesses'**
  String get strengthsWeaknesses;

  /// No description provided for @rankedAgainstLeague.
  ///
  /// In en, this message translates to:
  /// **'Ranked against the rest of the league'**
  String get rankedAgainstLeague;

  /// No description provided for @seasonStats.
  ///
  /// In en, this message translates to:
  /// **'Season stats'**
  String get seasonStats;

  /// No description provided for @scoringTrend.
  ///
  /// In en, this message translates to:
  /// **'Scoring trend'**
  String get scoringTrend;

  /// No description provided for @scoringTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Points scored in recent games'**
  String get scoringTrendSubtitle;

  /// No description provided for @recentResults.
  ///
  /// In en, this message translates to:
  /// **'Recent results'**
  String get recentResults;

  /// No description provided for @noRecentResults.
  ///
  /// In en, this message translates to:
  /// **'No completed games yet.'**
  String get noRecentResults;

  /// No description provided for @everyoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'Everyone is available'**
  String get everyoneAvailable;

  /// No description provided for @playersListed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player listed} other{{count} players listed}}'**
  String playersListed(int count);

  /// No description provided for @roster.
  ///
  /// In en, this message translates to:
  /// **'Roster'**
  String get roster;

  /// No description provided for @rosterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap a player for details'**
  String get rosterSubtitle;

  /// No description provided for @statProfile.
  ///
  /// In en, this message translates to:
  /// **'Stat profile'**
  String get statProfile;

  /// No description provided for @statProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Selected season totals'**
  String get statProfileSubtitle;

  /// No description provided for @bioTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get bioTeam;

  /// No description provided for @bioAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get bioAge;

  /// No description provided for @bioHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get bioHeight;

  /// No description provided for @bioWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bioWeight;

  /// No description provided for @bioClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get bioClass;

  /// No description provided for @bioExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get bioExperience;

  /// No description provided for @bioCollege.
  ///
  /// In en, this message translates to:
  /// **'College'**
  String get bioCollege;

  /// No description provided for @weightLbs.
  ///
  /// In en, this message translates to:
  /// **'{weight} lb'**
  String weightLbs(int weight);

  /// No description provided for @rookie.
  ///
  /// In en, this message translates to:
  /// **'Rookie'**
  String get rookie;

  /// No description provided for @yearsPro.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 yr} other{{count} yrs}}'**
  String yearsPro(int count);

  /// No description provided for @playerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Player details are unavailable.'**
  String get playerUnavailable;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @differentPositions.
  ///
  /// In en, this message translates to:
  /// **'Different positions: stats that only apply to one player show a dash for the other.'**
  String get differentPositions;

  /// No description provided for @noPlayerAtPosition.
  ///
  /// In en, this message translates to:
  /// **'One of these teams has no player listed at this position.'**
  String get noPlayerAtPosition;

  /// No description provided for @pickerItem.
  ///
  /// In en, this message translates to:
  /// **'{position} {initial}. {last}'**
  String pickerItem(String position, String initial, String last);

  /// No description provided for @pickerItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{position} {initial}. {last} ({status})'**
  String pickerItemUnavailable(
    String position,
    String initial,
    String last,
    String status,
  );

  /// No description provided for @noSharedStats.
  ///
  /// In en, this message translates to:
  /// **'No shared stats to compare'**
  String get noSharedStats;

  /// No description provided for @deadEven.
  ///
  /// In en, this message translates to:
  /// **'Dead even: {a}–{b} in shared stats'**
  String deadEven(int a, int b);

  /// No description provided for @leadsCategories.
  ///
  /// In en, this message translates to:
  /// **'{name} leads {wins} of {total} categories'**
  String leadsCategories(String name, int wins, int total);

  /// No description provided for @openPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String openPlayer(String name);

  /// No description provided for @upcomingIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a scheduled game to compare both teams.'**
  String get upcomingIntro;

  /// No description provided for @sportSection.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get sportSection;

  /// No description provided for @leagueSection.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get leagueSection;

  /// No description provided for @allLeagues.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLeagues;

  /// No description provided for @noUpcomingGames.
  ///
  /// In en, this message translates to:
  /// **'No upcoming {sport} games are available right now.'**
  String noUpcomingGames(String sport);

  /// No description provided for @gameAtShort.
  ///
  /// In en, this message translates to:
  /// **'{away} @ {home}'**
  String gameAtShort(String away, String home);

  /// No description provided for @gameAtLong.
  ///
  /// In en, this message translates to:
  /// **'{away} at {home}'**
  String gameAtLong(String away, String home);

  /// No description provided for @gameWhen.
  ///
  /// In en, this message translates to:
  /// **'{date} · {time}'**
  String gameWhen(String date, String time);

  /// No description provided for @gameWhenVenue.
  ///
  /// In en, this message translates to:
  /// **'{date} · {time} · {venue}'**
  String gameWhenVenue(String date, String time, String venue);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search teams or players'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a team or player name'**
  String get searchPrompt;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String noMatches(String query);

  /// No description provided for @teamsSection.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teamsSection;

  /// No description provided for @playersSection.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersSection;

  /// No description provided for @jerseyNumber.
  ///
  /// In en, this message translates to:
  /// **'#{number}'**
  String jerseyNumber(int number);

  /// No description provided for @savedMatchupLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved matchup'**
  String get savedMatchupLabel;

  /// No description provided for @winLabel.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get winLabel;

  /// No description provided for @gamePreviewHero.
  ///
  /// In en, this message translates to:
  /// **'Game\npreview'**
  String get gamePreviewHero;

  /// No description provided for @favoriteToWinNeutral.
  ///
  /// In en, this message translates to:
  /// **'{favorite} to win · neutral site'**
  String favoriteToWinNeutral(String favorite);

  /// No description provided for @favoriteChance.
  ///
  /// In en, this message translates to:
  /// **'{team} {percent}%'**
  String favoriteChance(String team, int percent);

  /// No description provided for @versusLower.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get versusLower;

  /// No description provided for @winProbabilitySemantics.
  ///
  /// In en, this message translates to:
  /// **'{teamA} {pctA} percent, {teamB} {pctB} percent'**
  String winProbabilitySemantics(
    String teamA,
    int pctA,
    String teamB,
    int pctB,
  );

  /// No description provided for @noGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No games yet'**
  String get noGamesYet;

  /// No description provided for @formResult.
  ///
  /// In en, this message translates to:
  /// **'{result, select, win{W} loss{L} tie{T} other{–}}'**
  String formResult(String result);

  /// No description provided for @formResultSemantics.
  ///
  /// In en, this message translates to:
  /// **'{result, select, win{Win} loss{Loss} tie{Tie} other{No result}}'**
  String formResultSemantics(String result);

  /// No description provided for @resultVs.
  ///
  /// In en, this message translates to:
  /// **'vs {team}'**
  String resultVs(String team);

  /// No description provided for @resultAt.
  ///
  /// In en, this message translates to:
  /// **'@ {team}'**
  String resultAt(String team);

  /// No description provided for @resultScore.
  ///
  /// In en, this message translates to:
  /// **'{result} {mine}–{theirs}'**
  String resultScore(String result, String mine, String theirs);

  /// No description provided for @noRecentScores.
  ///
  /// In en, this message translates to:
  /// **'No recent scores to chart'**
  String get noRecentScores;

  /// No description provided for @noChartableStats.
  ///
  /// In en, this message translates to:
  /// **'No chartable season stats yet'**
  String get noChartableStats;

  /// No description provided for @couldNotLoadSeasonStats.
  ///
  /// In en, this message translates to:
  /// **'Could not load season stats.'**
  String get couldNotLoadSeasonStats;

  /// No description provided for @loadingSeasonStats.
  ///
  /// In en, this message translates to:
  /// **'Loading season stats…'**
  String get loadingSeasonStats;

  /// No description provided for @dotSeparator.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get dotSeparator;

  /// No description provided for @sentenceJoin.
  ///
  /// In en, this message translates to:
  /// **'{first} {second}'**
  String sentenceJoin(String first, String second);

  /// No description provided for @chartRecentScores.
  ///
  /// In en, this message translates to:
  /// **'Points scored in the last {count, plural, =1{game} other{{count} games}}, oldest first: {scores}'**
  String chartRecentScores(int count, String scores);

  /// No description provided for @chartStatValue.
  ///
  /// In en, this message translates to:
  /// **'{stat}: {value}'**
  String chartStatValue(String stat, String value);

  /// No description provided for @chartPlayerStats.
  ///
  /// In en, this message translates to:
  /// **'Season totals. {stats}'**
  String chartPlayerStats(String stats);

  /// No description provided for @moreTeams.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more team — refine your search} other{{count} more teams — refine your search}}'**
  String moreTeams(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
