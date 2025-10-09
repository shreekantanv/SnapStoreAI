import 'dart:typed_data';

enum AnalysisStatus { loading, success, empty, error }

class AnalysisResult {
  final AnalysisStatus status;
  final String? subjectImage;
  final Uint8List? subjectImageBytes;
  final Spectrum? spectrum;
  final List<ResultAlignment>? alignments;
  final List<KeywordGroup>? keywords;
  final String? summary;
  final Meta? meta;
  final String? errorMessage;

  AnalysisResult({
    this.status = AnalysisStatus.success,
    this.subjectImage,
    this.subjectImageBytes,
    this.spectrum,
    this.alignments,
    this.keywords,
    this.summary,
    this.meta,
    this.errorMessage,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      subjectImage: json['subjectImage'] as String?,
      subjectImageBytes: null,
      spectrum: json['spectrum'] != null
          ? Spectrum.fromJson(json['spectrum'] as Map<String, dynamic>)
          : null,
      alignments: (json['alignments'] as List<dynamic>?)
          ?.map((e) => ResultAlignment.fromJson(e as Map<String, dynamic>))
          .toList(),
      keywords: (json['keywords'] as List<dynamic>?)
          ?.map((e) => KeywordGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String?,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Spectrum {
  final String minLabel;
  final String maxLabel;
  final int value;
  final double confidence;

  Spectrum({
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.confidence,
  });

  factory Spectrum.fromJson(Map<String, dynamic> json) {
    return Spectrum(
      minLabel: json['minLabel'] as String,
      maxLabel: json['maxLabel'] as String,
      value: json['value'] as int,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class ResultAlignment {
  final String label;
  final int percent;

  ResultAlignment({
    required this.label,
    required this.percent,
  });

  factory ResultAlignment.fromJson(Map<String, dynamic> json) {
    return ResultAlignment(
      label: json['label'] as String,
      percent: json['percent'] as int,
    );
  }
}

class KeywordGroup {
  final String topic;
  final List<String> terms;

  KeywordGroup({
    required this.topic,
    required this.terms,
  });

  factory KeywordGroup.fromJson(Map<String, dynamic> json) {
    return KeywordGroup(
      topic: json['topic'] as String,
      terms: (json['terms'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}

class Meta {
  final int analyzedItemsCount;
  final String timeRange;
  final String modelUsed;

  Meta({
    required this.analyzedItemsCount,
    required this.timeRange,
    required this.modelUsed,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      analyzedItemsCount: json['analyzedItemsCount'] as int,
      timeRange: json['timeRange'] as String,
      modelUsed: json['modelUsed'] as String,
    );
  }
}
