class ServerStatus {
  const ServerStatus({
    required this.apiVersion,
    required this.datasetVersion,
    required this.plannerName,
  });

  final String apiVersion;
  final String? datasetVersion;
  final String plannerName;

  bool get needsUpdate => !isCompatibleApiVersion(apiVersion);
}

bool isCompatibleApiVersion(String apiVersion) {
  final majorText = apiVersion.split('.').first;
  return int.tryParse(majorText) == 1;
}
