import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:norigo/features/culture_scan/application/culture_image_capture.dart';
import 'package:norigo/features/culture_scan/application/culture_vision_classifier.dart';
import 'package:norigo/features/culture_scan/domain/culture_vision_result.dart';

class MlKitCultureVisionClassifier extends CultureVisionClassifier {
  const MlKitCultureVisionClassifier();

  @override
  Future<CultureVisionResult?> classify(
    CultureImageCapture capture,
    CultureVisionRequest request,
  ) async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    final filePath = capture.filePath;
    if (filePath == null || filePath.trim().isEmpty) return null;

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.35),
    );
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final labels = await labeler.processImage(inputImage);
      if (labels.isEmpty) return null;
      return _resultFromLabels(labels, request);
    } finally {
      await labeler.close();
    }
  }
}

CultureVisionResult? _resultFromLabels(
  List<ImageLabel> labels,
  CultureVisionRequest request,
) {
  final labelText = labels
      .map((label) => '${label.label.toLowerCase()} ${label.confidence}')
      .join(' ');
  final contextText = [
    request.currentLocation,
    request.hintPlaceType,
  ].join(' ').toLowerCase();

  final scored =
      _allowedObjects
          .map((object) {
            final labelScore = object.labelKeywords.fold<double>(
              0,
              (score, keyword) => labelText.contains(keyword)
                  ? score + _bestConfidenceForKeyword(labels, keyword)
                  : score,
            );
            final contextScore = object.contextKeywords.fold<double>(
              0,
              (score, keyword) =>
                  contextText.contains(keyword) ? score + 0.16 : score,
            );
            return _ScoredObject(object, labelScore + contextScore);
          })
          .where((item) => item.score > 0)
          .toList(growable: false)
        ..sort((a, b) => b.score.compareTo(a.score));

  if (scored.isEmpty) return null;
  final best = scored.first;
  final confidence = best.score.clamp(0.36, 0.94).toDouble();
  final alternatives = scored
      .take(3)
      .map(
        (item) => CultureVisionAlternative(
          detectedObject: item.object.key,
          placeType: item.object.placeType,
          label: cultureObjectLabel(item.object.key),
          confidence: item.score.clamp(0.24, 0.94).toDouble(),
        ),
      )
      .toList(growable: false);

  return CultureVisionResult(
    detectedObject: best.object.key,
    placeType: best.object.placeType,
    confidence: confidence,
    alternatives: alternatives,
    needsConfirmation: confidence < 0.72,
    sourceType: 'vision_ai',
    sourceBadge: 'Vision AI',
  );
}

double _bestConfidenceForKeyword(List<ImageLabel> labels, String keyword) {
  var best = 0.0;
  for (final label in labels) {
    if (label.label.toLowerCase().contains(keyword) &&
        label.confidence > best) {
      best = label.confidence;
    }
  }
  return best == 0 ? 0.12 : best;
}

class _AllowedObject {
  const _AllowedObject({
    required this.key,
    required this.placeType,
    required this.labelKeywords,
    required this.contextKeywords,
  });

  final String key;
  final String placeType;
  final List<String> labelKeywords;
  final List<String> contextKeywords;
}

class _ScoredObject {
  const _ScoredObject(this.object, this.score);

  final _AllowedObject object;
  final double score;
}

const _allowedObjects = [
  _AllowedObject(
    key: 'temple_stone_stack',
    placeType: 'temple',
    labelKeywords: ['stone', 'rock', 'monument', 'temple', 'statue'],
    contextKeywords: ['temple', 'bulguksa', 'stone', 'wish'],
  ),
  _AllowedObject(
    key: 'restaurant_call_bell',
    placeType: 'restaurant',
    labelKeywords: ['button', 'bell', 'tableware', 'restaurant', 'food'],
    contextKeywords: ['restaurant', 'bell', 'table'],
  ),
  _AllowedObject(
    key: 'subway_pregnant_seat',
    placeType: 'subway',
    labelKeywords: ['seat', 'chair', 'train', 'subway', 'vehicle'],
    contextKeywords: ['subway', 'metro', 'pregnant', 'seat'],
  ),
  _AllowedObject(
    key: 'cafe_quiet_work',
    placeType: 'cafe',
    labelKeywords: ['coffee', 'cafe', 'laptop', 'table', 'desk'],
    contextKeywords: ['cafe', 'coffee', 'quiet', 'work'],
  ),
  _AllowedObject(
    key: 'kiosk_ordering',
    placeType: 'restaurant',
    labelKeywords: ['screen', 'kiosk', 'machine', 'display', 'computer'],
    contextKeywords: ['kiosk', 'order', 'restaurant', 'cafe'],
  ),
  _AllowedObject(
    key: 'market_cash_food',
    placeType: 'market',
    labelKeywords: ['food', 'market', 'cash', 'vendor', 'shop'],
    contextKeywords: ['market', 'cash', 'food', 'gwangjang'],
  ),
  _AllowedObject(
    key: 'market_queue_ticket',
    placeType: 'market',
    labelKeywords: ['ticket', 'paper', 'queue', 'number', 'market'],
    contextKeywords: ['market', 'queue', 'ticket', 'number', 'waiting'],
  ),
  _AllowedObject(
    key: 'palace_photo_etiquette',
    placeType: 'palace',
    labelKeywords: ['palace', 'building', 'camera', 'photo', 'person'],
    contextKeywords: ['palace', 'gyeongbokgung', 'photo', 'hanbok'],
  ),
  _AllowedObject(
    key: 'hanok_resident_etiquette',
    placeType: 'hanok_village',
    labelKeywords: ['house', 'building', 'street', 'village', 'roof'],
    contextKeywords: ['hanok', 'bukchon', 'resident', 'quiet', 'village'],
  ),
  _AllowedObject(
    key: 'waiting_number_ticket',
    placeType: 'restaurant',
    labelKeywords: ['ticket', 'paper', 'number', 'queue', 'restaurant'],
    contextKeywords: ['waiting', 'number', 'ticket', 'queue', 'restaurant'],
  ),
];
