/// The ways an item can get into the pantry. Display text lives in l10n
/// (`scanModeLabel` / `scanModeDescription` in lib/l10n/l10n.dart).
///
/// Single-item modes open the add/edit form; batch modes collect several
/// items and open the review screen before anything is saved.
enum ScanMode {
  barcode(batch: false, usesPhoto: false),
  dateLabel(batch: false, usesPhoto: true),
  manual(batch: false, usesPhoto: false),
  barcodeBatch(batch: true, usesPhoto: false),
  receipt(batch: true, usesPhoto: true);

  const ScanMode({required this.batch, required this.usesPhoto});
  final bool batch;
  final bool usesPhoto;
}
