"""PantryPal palettes + WCAG contrast check (text ≥ 4.5:1, UI parts ≥ 3:1). Run: python3 tools/palette.py
lib/theme/app_theme.dart is generated from LIGHT and DARK below; keep them in sync."""
def lum(h):
    r, g, b = (int(h[i:i+2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
def ratio(a, b):
    la, lb = sorted((lum(a), lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

LIGHT = dict(  # warm off-white
    surface='#FAF8F4', surfaceContainerLowest='#FFFFFF', surfaceContainerLow='#F5F2EC', surfaceContainer='#EFEBE4',
    surfaceContainerHigh='#E9E5DD', surfaceContainerHighest='#E3DED5', onSurface='#1F1E1B', onSurfaceVariant='#57534B',
    outline='#86817A', outlineVariant='#D3CEC4',
    primary='#2F6B3A', onPrimary='#FFFFFF', primaryContainer='#E6E2D9', onPrimaryContainer='#1F1E1B',
    secondary='#5C5850', onSecondary='#FFFFFF', secondaryContainer='#E2DDD3', onSecondaryContainer='#1F1E1B',
    tertiary='#7A5A3A', onTertiary='#FFFFFF', tertiaryContainer='#EFE3D6', onTertiaryContainer='#2B1F12',
    error='#B3261E', onError='#FFFFFF', errorContainer='#F9DEDC', onErrorContainer='#410E0B',
    inverseSurface='#32302C', onInverseSurface='#F3EFE8', inversePrimary='#9CD3A8',
)
DARK = dict(  # neutral grey
    surface='#1E1F21', surfaceContainerLowest='#17181A', surfaceContainerLow='#222326', surfaceContainer='#27282B',
    surfaceContainerHigh='#2E2F32', surfaceContainerHighest='#37383B', onSurface='#E6E4E1', onSurfaceVariant='#BDBAB4',
    outline='#8E8B86', outlineVariant='#45464A',
    primary='#93CFA0', onPrimary='#0C3916', primaryContainer='#3A3B3F', onPrimaryContainer='#E6E4E1',
    secondary='#C9C5BE', onSecondary='#2F2E2B', secondaryContainer='#3E3F43', onSecondaryContainer='#E6E4E1',
    tertiary='#E0C0A0', onTertiary='#3F2B16', tertiaryContainer='#4A4036', onTertiaryContainer='#F3E3D3',
    error='#F2B8B5', onError='#601410', errorContainer='#8C1D18', onErrorContainer='#F9DEDC',
    inverseSurface='#E6E4E1', onInverseSurface='#2F3033', inversePrimary='#2F6B3A',
)
TEXT = [('onSurface', s) for s in ['surface', 'surfaceContainerLowest', 'surfaceContainerLow', 'surfaceContainer', 'surfaceContainerHigh', 'surfaceContainerHighest']] + \
       [('onSurfaceVariant', s) for s in ['surface', 'surfaceContainerLow', 'surfaceContainer', 'surfaceContainerHighest']] + \
       [('onPrimary', 'primary'), ('onPrimaryContainer', 'primaryContainer'), ('onSecondary', 'secondary'),
        ('onSecondaryContainer', 'secondaryContainer'), ('onTertiaryContainer', 'tertiaryContainer'), ('onError', 'error'),
        ('onErrorContainer', 'errorContainer'), ('onInverseSurface', 'inverseSurface'), ('primary', 'surface'),
        ('primary', 'surfaceContainerLow'), ('error', 'surface')]
UI = [('outline', 'surface'), ('outline', 'surfaceContainerLow'), ('primary', 'surfaceContainerHighest'), ('inversePrimary', 'inverseSurface')]
if __name__ == '__main__':
    bad = 0
    for name, pal in [('light', LIGHT), ('dark', DARK)]:
        worst = min((ratio(pal[a], pal[b]), a, b) for a, b in TEXT)
        for a, b in TEXT:
            r = ratio(pal[a], pal[b])
            if r < 4.5: print(f'  {name}: TEXT {a} on {b} = {r:.2f}'); bad += 1
        for a, b in UI:
            r = ratio(pal[a], pal[b])
            if r < 3: print(f'  {name}: UI {a} on {b} = {r:.2f}'); bad += 1
        print(f'{name}: {len(TEXT)} text pairs, {len(UI)} UI pairs checked; lowest text contrast {worst[0]:.2f} ({worst[1]} on {worst[2]})')
    print('failures:', bad)
