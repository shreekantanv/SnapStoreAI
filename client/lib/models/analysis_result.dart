enum AnalysisStatus { loading, success, empty, error }

class AnalysisResult {
  final AnalysisStatus status;
  final String? subjectImage;
  final Spectrum? spectrum;
  final List<ResultAlignment>? alignments;
  final List<KeywordGroup>? keywords;
  final String? summary;
  final Meta? meta;
  final String? errorMessage;

  AnalysisResult({
    this.status = AnalysisStatus.success,
    this.subjectImage,
    this.spectrum,
    this.alignments,
    this.keywords,
    this.summary,
    this.meta,
    this.errorMessage,
  });
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
}

class ResultAlignment {
  final String label;
  final int percent;

  ResultAlignment({
    required this.label,
    required this.percent,
  });
}

class KeywordGroup {
  final String topic;
  final List<String> terms;

  KeywordGroup({
    required this.topic,
    required this.terms,
  });
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
}
