class BertTokenizer {
  final Map<String, int> vocab;
  final int maxLen;

  BertTokenizer(String vocabString, {this.maxLen = 128})
      : vocab = _parseVocab(vocabString);

  static Map<String, int> _parseVocab(String vocabString) {
    final lines = vocabString.split('\n');
    final map = <String, int>{};
    for (var i = 0; i < lines.length; i++) {
      var token = lines[i].trim();
      if (token.isNotEmpty) {
        map[token] = i;
      }
    }
    return map;
  }

  TokenizationResult tokenize(String text) {
    // 1. Basic cleaning and splitting
    text = text.toLowerCase();
    // Simple split by whitespace and punctuation (basic approximation)
    // For better results, we'd need a full WordPiece implementation.
    // This is a simplified version.
    
    final words = text.split(RegExp(r'\s+'));
    final List<int> ids = [];
    
    // CLS token
    ids.add(vocab['[CLS]'] ?? 101);

    for (var word in words) {
      if (word.isEmpty) continue;
      
      // Try to find the word in vocab
      if (vocab.containsKey(word)) {
        ids.add(vocab[word]!);
      } else {
        // OOV - Try to break down (WordPiece-ish)
        // For now, just use UNK if not found to keep it simple and fast
        // Or try to match subwords if we want to be fancy.
        // Let's do a simple subword match attempt.
        bool found = false;
        for (int i = word.length; i > 0; i--) {
          String sub = word.substring(0, i);
          if (vocab.containsKey(sub)) {
             ids.add(vocab[sub]!);
             // Remaining part
             if (i < word.length) {
               String remaining = "##" + word.substring(i);
               if (vocab.containsKey(remaining)) {
                 ids.add(vocab[remaining]!);
               } else {
                 // Give up on remaining
                 ids.add(vocab['[UNK]'] ?? 100);
               }
             }
             found = true;
             break;
          }
        }
        if (!found) {
          ids.add(vocab['[UNK]'] ?? 100);
        }
      }
      
      if (ids.length >= maxLen - 1) break; // Reserve space for SEP
    }

    // SEP token
    ids.add(vocab['[SEP]'] ?? 102);

    // Padding
    final attentionMask = List.filled(ids.length, 1);
    
    if (ids.length < maxLen) {
      int padLen = maxLen - ids.length;
      ids.addAll(List.filled(padLen, 0)); // PAD = 0
      attentionMask.addAll(List.filled(padLen, 0));
    } else if (ids.length > maxLen) {
      ids.length = maxLen;
      attentionMask.length = maxLen;
      // Ensure last is SEP if truncated? 
      // Usually truncation happens before adding SEP, but for now this is fine.
      ids[maxLen - 1] = vocab['[SEP]'] ?? 102; 
    }

    return TokenizationResult(ids, attentionMask);
  }
}

class TokenizationResult {
  final List<int> ids;
  final List<int> attentionMask;

  TokenizationResult(this.ids, this.attentionMask);
}
