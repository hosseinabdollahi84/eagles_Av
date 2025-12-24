class VTExtractor {
  final dynamic data;

  VTExtractor(List<dynamic> inputList) : data = inputList;

  void _recursiveSearch(
    dynamic currentData,
    List<String> targets,
    Map<String, List<dynamic>> accumulator,
  ) {
    if (currentData is Map) {
      for (var entry in currentData.entries) {
        if (targets.contains(entry.key)) {
          if (entry.value is List) {
            accumulator[entry.key]!.addAll(entry.value);
          } else {
            accumulator[entry.key]!.add(entry.value);
          }
        }
        _recursiveSearch(entry.value, targets, accumulator);
      }
    } else if (currentData is List) {
      for (var item in currentData) {
        _recursiveSearch(item, targets, accumulator);
      }
    }
  }

  Map<String, dynamic> extractNetworkContext() {
    final targetKeys = [
      "ip_traffic",
      "dns_lookups",
      "http_conversations",
      "urls",
      "memory_pattern_urls",
      "memory_pattern_domains",
      "domains",
    ];

    final foundData = <String, List<dynamic>>{};
    for (var key in targetKeys) {
      foundData[key] = [];
    }

    _recursiveSearch(data, targetKeys, foundData);

    final cleanNetwork = {
      "ips": <String>{},
      "urls": <String>{},
      "domains": <String>{},
    };

    if (foundData["ip_traffic"] != null) {
      for (var traffic in foundData["ip_traffic"]!) {
        if (traffic is Map && traffic.containsKey("destination_ip")) {
          final ip = traffic["destination_ip"];
          final port = traffic["destination_port"] ?? "??";
          final protocol = traffic["transport_layer_protocol"] ?? "TCP";
          cleanNetwork["ips"]!.add("$ip:$port ($protocol)");
        }
      }
    }

    final List<dynamic> rawUrls = [];
    rawUrls.addAll(foundData["urls"] ?? []);
    rawUrls.addAll(foundData["memory_pattern_urls"] ?? []);

    if (foundData["http_conversations"] != null) {
      for (var h in foundData["http_conversations"]!) {
        if (h is Map && h["url"] != null) {
          rawUrls.add(h["url"]);
        }
      }
    }

    for (var url in rawUrls) {
      cleanNetwork["urls"]!.add(url.toString());
    }

    final List<dynamic> rawDomains = [];
    rawDomains.addAll(foundData["dns_lookups"] ?? []);
    rawDomains.addAll(foundData["memory_pattern_domains"] ?? []);

    for (var item in rawDomains) {
      if (item is Map) {
        final domain = item["hostname"] ?? item["domain"];
        if (domain != null) cleanNetwork["domains"]!.add(domain.toString());
      } else if (item is String) {
        cleanNetwork["domains"]!.add(item);
      }
    }

    return {
      "unique_ips": cleanNetwork["ips"]!.toList(),
      "unique_domains": cleanNetwork["domains"]!.toList(),
      "extracted_urls": cleanNetwork["urls"]!.toList(),
    };
  }

  Map<String, dynamic> extractBehaviorContext() {
    final targetKeys = [
      "tags",
      "signature_matches",
      "mitre_attack_techniques",
      "files_written",
      "files_dropped",
      "files_opened",
      "processes_created",
      "modules_loaded",
      "permissions",
      "certificate",
      "signer_info",
      "tls",
    ];

    final foundData = <String, List<dynamic>>{};
    for (var key in targetKeys) {
      foundData[key] = [];
    }

    _recursiveSearch(data, targetKeys, foundData);

    final cleanReport = <String, dynamic>{
      "tags": (foundData["tags"] ?? []).toSet().toList(),
      "signatures": <Map<String, dynamic>>[],
      "file_system": <String>[],
      "certificates": <String>[],
    };

    final allFileObjects = [
      ...?foundData["files_written"],
      ...?foundData["files_dropped"],
      ...?foundData["files_opened"],
    ];

    final uniquePaths = <String>{};
    for (var item in allFileObjects) {
      if (item is String) {
        uniquePaths.add(item);
      } else if (item is Map) {
        final path = item["path"] ?? item["filename"] ?? item["name"];
        if (path != null) uniquePaths.add(path.toString());
      }
    }
    cleanReport["file_system"] = uniquePaths.take(20).toList();

    final seenSigs = <String>{};
    if (foundData["signature_matches"] != null) {
      for (var sig in foundData["signature_matches"]!) {
        if (sig is Map) {
          final desc = sig["description"] ?? sig["name"];
          if (desc != null && !seenSigs.contains(desc)) {
            (cleanReport["signatures"] as List).add({
              "description": desc,
              "severity": sig["severity"] ?? "UNKNOWN",
              "data": sig["match_data"] ?? [],
            });
            seenSigs.add(desc.toString());
          }
        }
      }
    }

    if (foundData["tls"] != null) {
      for (var tls in foundData["tls"]!) {
        if (tls is Map) {
          String getCN(dynamic obj) {
            if (obj is Map && obj["CN"] != null) return obj["CN"].toString();
            return "Unknown";
          }

          final issuer = getCN(tls["issuer"]);
          final subject = getCN(tls["subject"]);
          (cleanReport["certificates"] as List).add(
            "Issuer: $issuer, Subject: $subject",
          );
        }
      }
    }

    return cleanReport;
  }
}
