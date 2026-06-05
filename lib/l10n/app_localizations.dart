import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NoriGo'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get korean;

  /// No description provided for @koreanNative.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get koreanNative;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated.'**
  String get languageUpdated;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsPending.
  ///
  /// In en, this message translates to:
  /// **'Notifications will open when connected.'**
  String get notificationsPending;

  /// No description provided for @sectionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This section will be connected later.'**
  String get sectionComingSoon;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @my.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get my;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @logInInstead.
  ///
  /// In en, this message translates to:
  /// **'Log in instead'**
  String get logInInstead;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

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

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordTooShort;

  /// No description provided for @invalidEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidEmailPassword;

  /// No description provided for @unableToAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Unable to authenticate right now.'**
  String get unableToAuthenticate;

  /// No description provided for @passwordResetPending.
  ///
  /// In en, this message translates to:
  /// **'Password reset will be connected later.'**
  String get passwordResetPending;

  /// No description provided for @googleLoginPending.
  ///
  /// In en, this message translates to:
  /// **'Google login will be connected later.'**
  String get googleLoginPending;

  /// No description provided for @appleLoginPending.
  ///
  /// In en, this message translates to:
  /// **'Apple login will be connected later.'**
  String get appleLoginPending;

  /// No description provided for @authSucceededPending.
  ///
  /// In en, this message translates to:
  /// **'Auth succeeded. Trip basics route is not connected yet.'**
  String get authSucceededPending;

  /// No description provided for @authHeroCopy.
  ///
  /// In en, this message translates to:
  /// **'Crowd-free routes and\ncultural help in Korea.'**
  String get authHeroCopy;

  /// No description provided for @welcomeToNoriGo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nNoriGo'**
  String get welcomeToNoriGo;

  /// No description provided for @authInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Avoid crowds + understand culture in one app.'**
  String get authInfoTitle;

  /// No description provided for @authInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Smart routes, real-time insights, and local help made for travelers like you.'**
  String get authInfoBody;

  /// No description provided for @tripBasics.
  ///
  /// In en, this message translates to:
  /// **'Trip Basics'**
  String get tripBasics;

  /// No description provided for @tripBasicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your trip for smarter recommendations.'**
  String get tripBasicsSubtitle;

  /// No description provided for @interestsAlerts.
  ///
  /// In en, this message translates to:
  /// **'Interests & Alerts'**
  String get interestsAlerts;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @baseLocation.
  ///
  /// In en, this message translates to:
  /// **'Base location'**
  String get baseLocation;

  /// No description provided for @tripDays.
  ///
  /// In en, this message translates to:
  /// **'Trip days'**
  String get tripDays;

  /// No description provided for @tripLength.
  ///
  /// In en, this message translates to:
  /// **'Trip length'**
  String get tripLength;

  /// No description provided for @companionType.
  ///
  /// In en, this message translates to:
  /// **'Companion type'**
  String get companionType;

  /// No description provided for @crowdPreference.
  ///
  /// In en, this message translates to:
  /// **'Crowd preference'**
  String get crowdPreference;

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get finishSetup;

  /// No description provided for @preferredLanguageStep.
  ///
  /// In en, this message translates to:
  /// **'1. Preferred language'**
  String get preferredLanguageStep;

  /// No description provided for @destinationStep.
  ///
  /// In en, this message translates to:
  /// **'2. Destination'**
  String get destinationStep;

  /// No description provided for @firstVisitStep.
  ///
  /// In en, this message translates to:
  /// **'3. First visit?'**
  String get firstVisitStep;

  /// No description provided for @mainPurposeStep.
  ///
  /// In en, this message translates to:
  /// **'4. Main purpose'**
  String get mainPurposeStep;

  /// No description provided for @tripLengthStep.
  ///
  /// In en, this message translates to:
  /// **'5. Trip length'**
  String get tripLengthStep;

  /// No description provided for @needQueueHelpStep.
  ///
  /// In en, this message translates to:
  /// **'6. Need queue help?'**
  String get needQueueHelpStep;

  /// No description provided for @companionStep.
  ///
  /// In en, this message translates to:
  /// **'7. Who are you traveling with?'**
  String get companionStep;

  /// No description provided for @foodNeedsStep.
  ///
  /// In en, this message translates to:
  /// **'8. Food needs'**
  String get foodNeedsStep;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @southKorea.
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get southKorea;

  /// No description provided for @sightseeing.
  ///
  /// In en, this message translates to:
  /// **'Sightseeing'**
  String get sightseeing;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @cafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get cafe;

  /// No description provided for @culture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get culture;

  /// No description provided for @solo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get solo;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @couple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get couple;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @halal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get halal;

  /// No description provided for @vegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get vegetarian;

  /// No description provided for @allergy.
  ///
  /// In en, this message translates to:
  /// **'Allergy'**
  String get allergy;

  /// No description provided for @selectAtLeastOneInterest.
  ///
  /// In en, this message translates to:
  /// **'Select at least one interest.'**
  String get selectAtLeastOneInterest;

  /// No description provided for @permissionFlowPending.
  ///
  /// In en, this message translates to:
  /// **'Permission flow will be connected later.'**
  String get permissionFlowPending;

  /// No description provided for @setupCompletePending.
  ///
  /// In en, this message translates to:
  /// **'Setup complete. Itinerary screen will be added next.'**
  String get setupCompletePending;

  /// No description provided for @personalizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Personalize your experience.'**
  String get personalizeExperience;

  /// No description provided for @selectYourInterests.
  ///
  /// In en, this message translates to:
  /// **'Select your interests'**
  String get selectYourInterests;

  /// No description provided for @realTimeCrowdAlerts.
  ///
  /// In en, this message translates to:
  /// **'Real-time crowd alerts'**
  String get realTimeCrowdAlerts;

  /// No description provided for @aiRerouting.
  ///
  /// In en, this message translates to:
  /// **'AI rerouting'**
  String get aiRerouting;

  /// No description provided for @culturalScanGuide.
  ///
  /// In en, this message translates to:
  /// **'Cultural scan guide'**
  String get culturalScanGuide;

  /// No description provided for @audioGuide.
  ///
  /// In en, this message translates to:
  /// **'Audio guide'**
  String get audioGuide;

  /// No description provided for @waitTimeReservationHelp.
  ///
  /// In en, this message translates to:
  /// **'Wait-time & reservation help'**
  String get waitTimeReservationHelp;

  /// No description provided for @generateAiItinerary.
  ///
  /// In en, this message translates to:
  /// **'Generate AI Itinerary'**
  String get generateAiItinerary;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @ktoOpenApiEnnoia.
  ///
  /// In en, this message translates to:
  /// **'KTO OpenAPI + ennoia'**
  String get ktoOpenApiEnnoia;

  /// No description provided for @viewKtoData.
  ///
  /// In en, this message translates to:
  /// **'View KTO data'**
  String get viewKtoData;

  /// No description provided for @savedToSupabase.
  ///
  /// In en, this message translates to:
  /// **'Saved to Supabase'**
  String get savedToSupabase;

  /// No description provided for @creatingAiItinerary.
  ///
  /// In en, this message translates to:
  /// **'Creating your AI itinerary...'**
  String get creatingAiItinerary;

  /// No description provided for @myItineraries.
  ///
  /// In en, this message translates to:
  /// **'My itineraries'**
  String get myItineraries;

  /// No description provided for @planUpdated.
  ///
  /// In en, this message translates to:
  /// **'Plan updated'**
  String get planUpdated;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @aiItineraryPlanner.
  ///
  /// In en, this message translates to:
  /// **'AI Itinerary Planner'**
  String get aiItineraryPlanner;

  /// No description provided for @crowdAwareItinerary.
  ///
  /// In en, this message translates to:
  /// **'Crowd-aware itinerary'**
  String get crowdAwareItinerary;

  /// No description provided for @whyThisRoute.
  ///
  /// In en, this message translates to:
  /// **'Why this route?'**
  String get whyThisRoute;

  /// No description provided for @whyRouteExplanation.
  ///
  /// In en, this message translates to:
  /// **'This plan avoids peak crowd times, keeps travel distance short, and balances culture, food, shopping, and sunset views.'**
  String get whyRouteExplanation;

  /// No description provided for @whyRouteEnnoiaNote.
  ///
  /// In en, this message translates to:
  /// **'Later, this explanation will be generated by ennoia using KTO OpenAPI data.'**
  String get whyRouteEnnoiaNote;

  /// No description provided for @unableToSaveItinerary.
  ///
  /// In en, this message translates to:
  /// **'Unable to save itinerary.'**
  String get unableToSaveItinerary;

  /// No description provided for @unableToLoadItinerary.
  ///
  /// In en, this message translates to:
  /// **'Unable to load itinerary.'**
  String get unableToLoadItinerary;

  /// No description provided for @saveThisPlan.
  ///
  /// In en, this message translates to:
  /// **'Save this plan'**
  String get saveThisPlan;

  /// No description provided for @routeOverviewMap.
  ///
  /// In en, this message translates to:
  /// **'Route overview map'**
  String get routeOverviewMap;

  /// No description provided for @stayTime.
  ///
  /// In en, this message translates to:
  /// **'Stay time'**
  String get stayTime;

  /// No description provided for @ktoData.
  ///
  /// In en, this message translates to:
  /// **'KTO data'**
  String get ktoData;

  /// No description provided for @notPersisted.
  ///
  /// In en, this message translates to:
  /// **'Not persisted'**
  String get notPersisted;

  /// No description provided for @noSourceNote.
  ///
  /// In en, this message translates to:
  /// **'No source note provided.'**
  String get noSourceNote;

  /// No description provided for @noKtoContentId.
  ///
  /// In en, this message translates to:
  /// **'No KTO content ID'**
  String get noKtoContentId;

  /// No description provided for @crowdAlert.
  ///
  /// In en, this message translates to:
  /// **'Crowd Alert'**
  String get crowdAlert;

  /// No description provided for @unableToLoadCrowdAlert.
  ///
  /// In en, this message translates to:
  /// **'Unable to load crowd alert.'**
  String get unableToLoadCrowdAlert;

  /// No description provided for @generateRetripAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Generate Re-Trip alternatives'**
  String get generateRetripAlternatives;

  /// No description provided for @switchPlan.
  ///
  /// In en, this message translates to:
  /// **'Switch plan'**
  String get switchPlan;

  /// No description provided for @alternativePlaces.
  ///
  /// In en, this message translates to:
  /// **'Alternative places'**
  String get alternativePlaces;

  /// No description provided for @keepOriginal.
  ///
  /// In en, this message translates to:
  /// **'Keep original'**
  String get keepOriginal;

  /// No description provided for @retrip.
  ///
  /// In en, this message translates to:
  /// **'Re-Trip'**
  String get retrip;

  /// No description provided for @scanCulture.
  ///
  /// In en, this message translates to:
  /// **'Scan Culture'**
  String get scanCulture;

  /// No description provided for @understandingLocalContext.
  ///
  /// In en, this message translates to:
  /// **'Understanding the local context...'**
  String get understandingLocalContext;

  /// No description provided for @cultureDbEnnoia.
  ///
  /// In en, this message translates to:
  /// **'Culture DB + ennoia'**
  String get cultureDbEnnoia;

  /// No description provided for @cultureDb.
  ///
  /// In en, this message translates to:
  /// **'Culture DB'**
  String get cultureDb;

  /// No description provided for @travelBehaviorOnly.
  ///
  /// In en, this message translates to:
  /// **'Travel behavior only'**
  String get travelBehaviorOnly;

  /// No description provided for @demoFallback.
  ///
  /// In en, this message translates to:
  /// **'Demo fallback'**
  String get demoFallback;

  /// No description provided for @readyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan'**
  String get readyToScan;

  /// No description provided for @localGuide.
  ///
  /// In en, this message translates to:
  /// **'Local guide'**
  String get localGuide;

  /// No description provided for @iFoundThisSituation.
  ///
  /// In en, this message translates to:
  /// **'I found this situation'**
  String get iFoundThisSituation;

  /// No description provided for @iFoundRestaurantCallBell.
  ///
  /// In en, this message translates to:
  /// **'I found a restaurant call bell'**
  String get iFoundRestaurantCallBell;

  /// No description provided for @maybeThisIs.
  ///
  /// In en, this message translates to:
  /// **'Maybe this is...'**
  String get maybeThisIs;

  /// No description provided for @callBellConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This may be a restaurant call bell. Is that right?'**
  String get callBellConfirmation;

  /// No description provided for @useThis.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get useThis;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @unsupportedTravelSituation.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t identify a supported travel situation. Please choose the closest situation.'**
  String get unsupportedTravelSituation;

  /// No description provided for @scanObjectNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t find the object'**
  String get scanObjectNotFoundTitle;

  /// No description provided for @scanObjectNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the object again in brighter light, keeping it near the center of the screen.'**
  String get scanObjectNotFoundBody;

  /// No description provided for @scanObjectNotFoundManualPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose the situation manually?'**
  String get scanObjectNotFoundManualPrompt;

  /// No description provided for @scanObjectNotFoundAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scanObjectNotFoundAction;

  /// No description provided for @scanObjectNotFoundManualAction.
  ///
  /// In en, this message translates to:
  /// **'Choose manually'**
  String get scanObjectNotFoundManualAction;

  /// No description provided for @noCameraDetected.
  ///
  /// In en, this message translates to:
  /// **'No camera detected. Showing guide preview.'**
  String get noCameraDetected;

  /// No description provided for @cameraPermissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Camera permission blocked. Showing guide preview.'**
  String get cameraPermissionBlocked;

  /// No description provided for @cameraPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera preview is unavailable here. NoriGo is showing a safe preview background.'**
  String get cameraPreviewUnavailable;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guide;

  /// No description provided for @flashNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Flash is not available on this device.'**
  String get flashNotAvailable;

  /// No description provided for @flashUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flash is unavailable on this device.'**
  String get flashUnavailable;

  /// No description provided for @flashOn.
  ///
  /// In en, this message translates to:
  /// **'Flash on'**
  String get flashOn;

  /// No description provided for @flashOff.
  ///
  /// In en, this message translates to:
  /// **'Flash off'**
  String get flashOff;

  /// No description provided for @runGuide.
  ///
  /// In en, this message translates to:
  /// **'Run Guide'**
  String get runGuide;

  /// No description provided for @refreshGuide.
  ///
  /// In en, this message translates to:
  /// **'Refresh Guide'**
  String get refreshGuide;

  /// No description provided for @meaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get meaning;

  /// No description provided for @etiquette.
  ///
  /// In en, this message translates to:
  /// **'Etiquette'**
  String get etiquette;

  /// No description provided for @story.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get story;

  /// No description provided for @scanContext.
  ///
  /// In en, this message translates to:
  /// **'Scan context'**
  String get scanContext;

  /// No description provided for @aiCultureGuide.
  ///
  /// In en, this message translates to:
  /// **'AI Culture Guide'**
  String get aiCultureGuide;

  /// No description provided for @noPhraseAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phrase is available yet.'**
  String get noPhraseAvailable;

  /// No description provided for @cultureGuideLocalFallback.
  ///
  /// In en, this message translates to:
  /// **'Culture Guide is not connected yet, so NoriGo is showing a local guide.'**
  String get cultureGuideLocalFallback;

  /// No description provided for @cultureGuideOfflineFallback.
  ///
  /// In en, this message translates to:
  /// **'NoriGo could not reach Culture Guide, so it is showing a local guide.'**
  String get cultureGuideOfflineFallback;

  /// No description provided for @savedPlans.
  ///
  /// In en, this message translates to:
  /// **'Saved plans'**
  String get savedPlans;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlaces;

  /// No description provided for @cultureScans.
  ///
  /// In en, this message translates to:
  /// **'Culture scans'**
  String get cultureScans;

  /// No description provided for @timeSaved.
  ///
  /// In en, this message translates to:
  /// **'Time saved'**
  String get timeSaved;

  /// No description provided for @savedCultureGuides.
  ///
  /// In en, this message translates to:
  /// **'Saved culture guides'**
  String get savedCultureGuides;

  /// No description provided for @waitTimeHelpHistory.
  ///
  /// In en, this message translates to:
  /// **'Wait-time help history'**
  String get waitTimeHelpHistory;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @languageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Language & notifications'**
  String get languageNotifications;

  /// No description provided for @privacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get privacyData;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get helpCenter;

  /// No description provided for @localExplorer.
  ///
  /// In en, this message translates to:
  /// **'Local Explorer'**
  String get localExplorer;

  /// No description provided for @keepExploring.
  ///
  /// In en, this message translates to:
  /// **'Keep exploring to level up!'**
  String get keepExploring;

  /// No description provided for @translationHistory.
  ///
  /// In en, this message translates to:
  /// **'Translation history'**
  String get translationHistory;

  /// No description provided for @translationHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Translation history will appear here.'**
  String get translationHistoryEmpty;

  /// No description provided for @privacyDataMessage.
  ///
  /// In en, this message translates to:
  /// **'Your travel data is saved to improve your itinerary experience.'**
  String get privacyDataMessage;

  /// No description provided for @helpCenterMessage.
  ///
  /// In en, this message translates to:
  /// **'NoriGo helps you avoid crowds, understand local culture, and adapt your trip.'**
  String get helpCenterMessage;

  /// No description provided for @noSavedItineraries.
  ///
  /// In en, this message translates to:
  /// **'No saved itineraries yet.'**
  String get noSavedItineraries;

  /// No description provided for @noSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet.'**
  String get noSavedPlaces;

  /// No description provided for @noSavedCultureGuides.
  ///
  /// In en, this message translates to:
  /// **'No saved culture guides yet.'**
  String get noSavedCultureGuides;

  /// No description provided for @noWaitTimeHistory.
  ///
  /// In en, this message translates to:
  /// **'No wait-time help history yet.'**
  String get noWaitTimeHistory;

  /// No description provided for @noInterestsSelected.
  ///
  /// In en, this message translates to:
  /// **'No interests selected yet.'**
  String get noInterestsSelected;

  /// No description provided for @foodNeeds.
  ///
  /// In en, this message translates to:
  /// **'Food needs'**
  String get foodNeeds;

  /// No description provided for @crowdAlertsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Crowd alerts and itinerary updates are enabled by default.'**
  String get crowdAlertsEnabled;

  /// No description provided for @savedItineraryStop.
  ///
  /// In en, this message translates to:
  /// **'Saved itinerary stop'**
  String get savedItineraryStop;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, Emma!'**
  String get homeGreeting;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Crowd-aware Korea, culture-aware context.'**
  String get homeTagline;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search routes, cafes, culture tips'**
  String get homeSearchHint;

  /// No description provided for @aiRouteCheck.
  ///
  /// In en, this message translates to:
  /// **'AI route check'**
  String get aiRouteCheck;

  /// No description provided for @crowdFreeRouteNow.
  ///
  /// In en, this message translates to:
  /// **'Crowd-free route now'**
  String get crowdFreeRouteNow;

  /// No description provided for @reviewAlert.
  ///
  /// In en, this message translates to:
  /// **'Review alert'**
  String get reviewAlert;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @crowdMap.
  ///
  /// In en, this message translates to:
  /// **'Crowd map'**
  String get crowdMap;

  /// No description provided for @waitTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Wait-time help'**
  String get waitTimeHelp;

  /// No description provided for @liveTranslation.
  ///
  /// In en, this message translates to:
  /// **'Live translation'**
  String get liveTranslation;

  /// No description provided for @hiddenSpots.
  ///
  /// In en, this message translates to:
  /// **'Hidden spots'**
  String get hiddenSpots;

  /// No description provided for @goodToVisitNow.
  ///
  /// In en, this message translates to:
  /// **'Good to visit now'**
  String get goodToVisitNow;

  /// No description provided for @lowCrowdPicks.
  ///
  /// In en, this message translates to:
  /// **'Low-crowd picks close to your route'**
  String get lowCrowdPicks;

  /// No description provided for @todaysCultureTip.
  ///
  /// In en, this message translates to:
  /// **'Today\'s culture tip'**
  String get todaysCultureTip;

  /// No description provided for @discoverHiddenSpots.
  ///
  /// In en, this message translates to:
  /// **'Discover hidden spots'**
  String get discoverHiddenSpots;

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the wait, go local.'**
  String get discoverSubtitle;

  /// No description provided for @discoverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations, food, cafes, culture questions'**
  String get discoverSearchHint;

  /// No description provided for @aiPicks.
  ///
  /// In en, this message translates to:
  /// **'AI picks'**
  String get aiPicks;

  /// No description provided for @aiPicksForYou.
  ///
  /// In en, this message translates to:
  /// **'AI picks for you'**
  String get aiPicksForYou;

  /// No description provided for @placeSaved.
  ///
  /// In en, this message translates to:
  /// **'Place saved.'**
  String get placeSaved;

  /// No description provided for @addToItineraryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Add to itinerary coming soon.'**
  String get addToItineraryComingSoon;

  /// No description provided for @preferencesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Preferences are coming soon.'**
  String get preferencesComingSoon;

  /// No description provided for @discoverQuietCafe.
  ///
  /// In en, this message translates to:
  /// **'Quiet cafe'**
  String get discoverQuietCafe;

  /// No description provided for @discoverDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert'**
  String get discoverDessert;

  /// No description provided for @discoverLocalFood.
  ///
  /// In en, this message translates to:
  /// **'Local food'**
  String get discoverLocalFood;

  /// No description provided for @discoverPhotoSpot.
  ///
  /// In en, this message translates to:
  /// **'Photo spot'**
  String get discoverPhotoSpot;

  /// No description provided for @discoverCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get discoverCulture;

  /// No description provided for @mapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapLabel;

  /// No description provided for @listLabel.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listLabel;

  /// No description provided for @localFallbackMap.
  ///
  /// In en, this message translates to:
  /// **'Local fallback'**
  String get localFallbackMap;

  /// No description provided for @basedOnLocalDataLowCrowdInsights.
  ///
  /// In en, this message translates to:
  /// **'Based on local data and low-crowd insights'**
  String get basedOnLocalDataLowCrowdInsights;

  /// No description provided for @basedOnKtoLowCrowdInsights.
  ///
  /// In en, this message translates to:
  /// **'Based on KTO and low-crowd insights'**
  String get basedOnKtoLowCrowdInsights;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @personalizedRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendations'**
  String get personalizedRecommendations;

  /// No description provided for @personalizedRecommendationsBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you like and we\'ll find more hidden gems for you.'**
  String get personalizedRecommendationsBody;

  /// No description provided for @tellUsYourPreferences.
  ///
  /// In en, this message translates to:
  /// **'Tell us your preferences'**
  String get tellUsYourPreferences;

  /// No description provided for @savePlace.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get savePlace;

  /// No description provided for @savedPlace.
  ///
  /// In en, this message translates to:
  /// **'Saved place'**
  String get savedPlace;

  /// No description provided for @noHiddenSpotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hidden spots available yet.'**
  String get noHiddenSpotsAvailable;

  /// No description provided for @noHiddenSpotsMatched.
  ///
  /// In en, this message translates to:
  /// **'No hidden spots matched \"{query}\".'**
  String noHiddenSpotsMatched(String query);

  /// No description provided for @dataLocationConsent.
  ///
  /// In en, this message translates to:
  /// **'Data & Location Consent'**
  String get dataLocationConsent;

  /// No description provided for @dataUseConsent.
  ///
  /// In en, this message translates to:
  /// **'Data use consent'**
  String get dataUseConsent;

  /// No description provided for @dataUseConsentBody.
  ///
  /// In en, this message translates to:
  /// **'NoriGo uses your trip preferences, saved itineraries, culture scans, and Re-Trip history to improve recommendations.'**
  String get dataUseConsentBody;

  /// No description provided for @locationUseConsent.
  ///
  /// In en, this message translates to:
  /// **'Location use consent'**
  String get locationUseConsent;

  /// No description provided for @locationUseConsentBody.
  ///
  /// In en, this message translates to:
  /// **'NoriGo uses your current location to find nearby low-crowd spots and better alternatives.'**
  String get locationUseConsentBody;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @usingBaseLocationInstead.
  ///
  /// In en, this message translates to:
  /// **'Using base location instead'**
  String get usingBaseLocationInstead;

  /// No description provided for @consentSaved.
  ///
  /// In en, this message translates to:
  /// **'Consent saved.'**
  String get consentSaved;

  /// No description provided for @consentContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get consentContinue;

  /// No description provided for @noCalmPlaces.
  ///
  /// In en, this message translates to:
  /// **'No calm places found for this search. Try a broader category or clear the search.'**
  String get noCalmPlaces;

  /// No description provided for @mapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Map placeholder'**
  String get mapPlaceholder;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
