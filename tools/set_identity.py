#!/usr/bin/env python3
"""Set PantryPal's app identity everywhere it lives, in one step.

  python3 tools/set_identity.py --bundle-id com.yourname.pantrypal --team ABCDE12345

Updates:
  ios/Flutter/Identity.xcconfig            bundle id, App Group, Apple team (all iOS targets read these)
  lib/services/home_widget_service.dart    App Group the app shares with the home-screen widget
  android/app/build.gradle.kts             applicationId (the Kotlin package stays app.pantrypal)

Apple requires bundle ids to be unique: if Xcode reports the id is unavailable, choose another.

Free Apple ID ("Personal Team")? App Groups need a paid developer account, so add --free-account:
the app builds and runs normally, but the home-screen widget can't show pantry data.
--paid-account turns App Groups back on.
"""
import argparse, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FILES = {
    'xcconfig': ROOT / 'ios/Flutter/Identity.xcconfig',
    'dart': ROOT / 'lib/services/home_widget_service.dart',
    'gradle': ROOT / 'android/app/build.gradle.kts',
}

def sub_once(text, pattern, repl, what):
    new, n = re.subn(pattern, repl, text, flags=re.M)
    if n != 1:
        sys.exit(f'error: expected exactly one {what}, found {n}. Was the file edited by hand?')
    return new

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--bundle-id', required=True, help='reverse-DNS id, e.g. com.yourname.pantrypal')
    ap.add_argument('--team', default=None, help='Apple Developer team ID (10 characters); omit to leave unchanged')
    ap.add_argument('--app-group', default=None, help='defaults to group.<bundle-id>')
    ap.add_argument('--android-id', default=None, help='Android applicationId; defaults to --bundle-id')
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument('--free-account', action='store_true', help='no App Groups (free Apple ID); widget shows no data')
    mode.add_argument('--paid-account', action='store_true', help='App Groups on (the default setup)')
    a = ap.parse_args()

    bundle = a.bundle_id
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+', bundle):
        sys.exit(f'error: "{bundle}" is not a valid bundle id (letters, digits, hyphens, at least one dot)')
    group = a.app_group or f'group.{bundle}'
    if not group.startswith('group.'):
        sys.exit('error: App Group ids must start with "group."')
    android = a.android_id or bundle
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+', android):
        sys.exit(f'error: "{android}" is not a valid Android applicationId (no hyphens; each part starts with a letter).'
                 ' Pass --android-id explicitly.')
    if a.team is not None and a.team and not re.fullmatch(r'[A-Z0-9]{10}', a.team):
        sys.exit('error: an Apple team ID is 10 upper-case letters/digits (Xcode → Settings → Accounts)')

    for f in FILES.values():
        if not f.exists():
            sys.exit(f'error: {f.relative_to(ROOT)} not found')

    x = FILES['xcconfig'].read_text()
    x = sub_once(x, r'^PANTRYPAL_BUNDLE_ID *=.*$', f'PANTRYPAL_BUNDLE_ID = {bundle}', 'PANTRYPAL_BUNDLE_ID line')
    x = sub_once(x, r'^PANTRYPAL_APP_GROUP *=.*$', f'PANTRYPAL_APP_GROUP = {group}', 'PANTRYPAL_APP_GROUP line')
    if a.team is not None:
        x = sub_once(x, r'^DEVELOPMENT_TEAM *=.*$', f'DEVELOPMENT_TEAM = {a.team}', 'DEVELOPMENT_TEAM line')
    if a.free_account or a.paid_account:
        runner = '' if a.free_account else 'Runner/Runner.entitlements'
        widget = '' if a.free_account else 'PantryWidget/PantryWidget.entitlements'
        x = sub_once(x, r'^PANTRYPAL_RUNNER_ENTITLEMENTS *=.*$', f'PANTRYPAL_RUNNER_ENTITLEMENTS = {runner}', 'runner entitlements line')
        x = sub_once(x, r'^PANTRYPAL_WIDGET_ENTITLEMENTS *=.*$', f'PANTRYPAL_WIDGET_ENTITLEMENTS = {widget}', 'widget entitlements line')

    d = FILES['dart'].read_text()
    d = sub_once(d, r"(String\.fromEnvironment\('WIDGET_APP_GROUP', defaultValue: ')[^']*(')", rf"\g<1>{group}\g<2>",
                 'appGroupId default')

    g = FILES['gradle'].read_text()
    g = sub_once(g, r'^(\s*applicationId = ")[^"]*(")', rf'\g<1>{android}\g<2>', 'applicationId line')

    FILES['xcconfig'].write_text(x); FILES['dart'].write_text(d); FILES['gradle'].write_text(g)
    print(f'iOS bundle id   {bundle}\niOS widget id   {bundle}.PantryWidget\nApp Group       {group}\n'
          f'Android id      {android}\nApple team      {a.team if a.team is not None else "(unchanged)"}')
    if a.free_account:
        print('App Groups      off (free account): the home-screen widget will not show pantry data')
    elif a.paid_account:
        print('App Groups      on')
    print('\nNext: flutter clean && flutter run   (on iOS, the App Group is registered automatically by Xcode signing)')

if __name__ == '__main__':
    main()
