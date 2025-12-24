import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GeminiService();

  Future<String?> generateResponse(List<String> urls) async {
    if (urls.isEmpty) return "No URLs found to analyze.";

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKeys[i],
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );

      final prompt = "";

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text?.trim();
    } on GenerativeAIException catch (e) {
      if (e.message.contains('429') ||
          e.message.toLowerCase().contains('quota')) {
        if (i >= apiKeys.length - 1) {
          i = 0;
        } else {
          i += 1;
        }
        return await generateResponse(urls);
      } else {
        return ('A different AI error occurred: ${e.message}');
      }
    } catch (e) {
      return "AI Connection Error: ${e.toString().split(']').last}";
    }
  }

  Future<String?> GetVT_NetworkResult(String NetARes) async {
    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKeys[i],
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );

      final prompt =
          """
You are a Network Security Analyst specializing in Mobile App Security. 
I will provide you with an App Name, Package Name, and a list of extracted URLs/IP addresses.

**Your Task:**
Analyze the list of network endpoints to identify malicious C2 (Command & Control), Phishing, or Data Exfiltration points. You must filter out "Noise" (Legitimate SDKs, abandoned dev links, XML schemas) to avoid False Positives.

### ANALYSIS LOGIC
1.  **Context Check:** Does the URL match the package name?
    * *Example:* `api.instagram.com` is expected in `com.instagram.android` OR any app using Instagram SDK.
    * *Example:* `crypto-wallet-update.com` is HIGHLY SUSPICIOUS in a "Flashlight" app.

2.  **Noise Filtering (Ignore these):**
    * **Standard SDKs:** `googleapis.com`, `facebook.com`, `crashlytics.com`, `app-measurement.com`, `unity3d.com` (Unless the app claims to be "Ad-Free" or "Privacy-Focused").
    * **Schemas/Standards:** `w3.org`, `xml.org`, `schemas.android.com`.
    * **Dev/Dead Links:** `localhost`, `127.0.0.1`, `example.com`, `test.com`.

3.  **Threat Indicators (Flag these):**
    * **Raw IPs:** Public IPs (e.g., `104.x.x.x`) used directly in code, especially on non-standard ports (NOT 80/443).
    * **Suspicious TLDs:** `.xyz`, `.top`, `.ru`, `.cn` *only if* the app is not related to those regions/domains.
    * **Obfuscation:** URLs containing base64 strings or suspicious parameters (`?cmd=`, `?exec=`).

### INPUT DATA
* **Extracted URLs/IPs:** $NetARes

### OUTPUT FORMAT
Return ONLY the following JSON. Do not use Markdown formatting (like ```json). Do not add conversational text.

{
  "network_verdict": "Malicious | Suspicious | Clean",
  "network_score": 0,  // 0-10 Scale (0=Clean, 10=C2/Botnet)
  "summary": "Concise explanation of the verdict.",
  "findings": {
    "malicious_endpoints": [
      // List ONLY high-confidence threats (C2 IPs, Phishing domains)
    ],
    "suspicious_endpoints": [
      // List items that look weird but might be legitimate (e.g., HTTP links, unknown APIs)
    ],
    "ignored_noise_count": 0 // Count of Safe SDKs/Dev links found
  }
}
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text?.trim();
    } on GenerativeAIException catch (e) {
      if (e.message.contains('429') ||
          e.message.toLowerCase().contains('quota')) {
        if (i >= apiKeys.length - 1) {
          i = 0;
        } else {
          i += 1;
        }
        return await GetVT_NetworkResult(NetARes);
      } else {
        return ('A different AI error occurred: ${e.message}');
      }
    } catch (e) {
      return "AI Connection Error: ${e.toString().split(']').last}";
    }
  }

  Future<String?> GetVT_BehaviorResult(String BInfo, double entropy) async {
    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKeys[i],
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );

      final prompt =
          """
You are a Senior Malware Analyst. I will provide you with the Entropy of `classes.dex` and a JSON extract from a VirusTotal report.

**Your Goal:** Assess the "Threat Level" of the Android application. You must balance "Security" with "False Positive Avoidance." 
DO NOT flag an app as Malicious solely because it is a "Test Build" or uses "Obfuscation" (which is common in legitimate apps).

### SCORING LOGIC (0-10 Scale)

**1. The "Developer Build" Trap (Critical for False Positives):**
   - IF `certificate` contains "Android Debug" OR "Test Key":
     - AND `permissions` are dangerous (SMS, Location, Overlay) -> **Score: 6-7 (Suspicious)**.
     - AND `permissions` are minimal/standard -> **Score: 2-3 (Clean/Dev Build)**.
   - *Reasoning:* Students and internal devs use debug certs. It is not inherently malware.

**2. The "Obfuscation" nuance:**
   - IF `tags` include "OBFUSCATED" OR "Entropy" > 7.2:
     - AND `critical_signatures` show "Hidden API calls" or "Dynamic Code Loading" -> **Score: 7-8**.
     - BUT `framework_detected` is "Flutter", "Unity", or "React Native" -> **Score: 1-3 (Clean)**.
     - *Reasoning:* Games and Cross-platform apps always have high entropy. This is normal.

**3. The "Malware" Triggers (Instant High Score):**
   - **Score 9-10:** Ransomware behaviors (File encryption, wiping directories), Banking Trojan behaviors (Overlay + SMS + Accessibility).
   - **Score 8:** Hardcoded IPs to non-standard ports (e.g., `1.2.3.4:6666`).

### INPUT DATA
* **Entropy:** $entropy
* **Behavior Report:**  $BInfo

### OUTPUT FORMAT (Strict JSON)
Return ONLY this JSON.

{
  "verdict": "Malicious | Suspicious | Clean | Unknown",
  "threat_score": 0,
  "confidence": "High | Medium | Low",
  "analysis_summary": "Concise justification. Explicitly state if it looks like a 'Safe Dev Build' or 'Legitimate Flutter App' to reassure the user.",
  "key_indicators": {
    "positives": [],  // Bad things found (e.g., "Debug Cert", "SMS Permission")
    "negatives": []   // Good things found (e.g., "Flutter Framework identified", "No dangerous APIs")
  },
  "technical_details": {
    "dex_entropy": 0.0,
    "framework": "Native | Flutter | Unity | Xamarin | None",
    "certificate_grade": "Production | Debug/Test | Self-Signed"
  }
}
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text?.trim();
    } on GenerativeAIException catch (e) {
      if (e.message.contains('429') ||
          e.message.toLowerCase().contains('quota')) {
        if (i >= apiKeys.length - 1) {
          i = 0;
        } else {
          i += 1;
        }
        return await GetVT_BehaviorResult(BInfo, entropy);
      } else {
        return ('A different AI error occurred: ${e.message}');
      }
    } catch (e) {
      return "AI Connection Error: ${e.toString().split(']').last}";
    }
  }

  int i = 0;
  List<String> apiKeys = [
    "your_api_key",
    "your_api_key",
    "your_api_key",
    "your_api_key",
    "your_api_key",
  ];
  String _modelName = 'gemini-flash-latest';
}
