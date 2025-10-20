# Sample Honey Outputs

This directory contains **example outputs** showing what your generated synthetic honey will look like.

## 📋 Sample Files

### `sample_passwords.txt`
- 20 fake username:password combinations
- Mix of weak, medium, and strong passwords
- Realistic naming conventions
- Formatted like a leaked database dump

### `sample_research.txt`
- Confidential research document about quantum computing security
- Includes: header, authors, abstract, findings, conclusion
- Marked as "CONFIDENTIAL - DO NOT DISTRIBUTE"
- ~1,500 words of realistic technical content

### `sample_contract.txt`
- Confidential software licensing agreement
- Includes: parties, terms, clauses, payment details, signatures
- Marked as "CONFIDENTIAL - Attorney-Client Privileged"
- ~2,000 words of realistic legal language

## 🎯 What Makes Good Honey?

These samples demonstrate key characteristics of effective honeypot bait:

### ✅ Authenticity Markers
- **Confidential headers** - "DO NOT DISTRIBUTE", "INTERNAL USE ONLY"
- **Realistic formatting** - Proper document structure
- **Professional language** - Technical jargon, legal terms
- **Credible details** - Names, dates, amounts, document IDs

### ✅ Variety
- **Different sensitivity levels** - Some "top secret", others just "internal"
- **Multiple formats** - Lists, documents, contracts
- **Various topics** - Technical, business, legal

### ✅ Believability
- **Contextual details** - References to real technologies, industries
- **Proper structure** - Headers, sections, signatures
- **Appropriate length** - Not too short (suspicious) or too long (boring)

## 🔄 Generating Your Own

Use these samples as a reference for quality. Your AI-generated honey should match or exceed this level of realism.

### Using Gemini API:
```bash
./honey_generator.py --language English
```

### Using Ollama:
```bash
./honey_generator_ollama.sh
```

## 📊 Expected Output Quality

| Tool | Quality | Speed | Cost |
|------|---------|-------|------|
| Claude 3.5 | ⭐⭐⭐⭐⭐ | Fast | $$ |
| GPT-4 | ⭐⭐⭐⭐⭐ | Fast | $$ |
| Gemini Pro | ⭐⭐⭐⭐ | Fast | Free tier |
| Mistral (Ollama) | ⭐⭐⭐ | Medium | Free |
| Llama2 (Ollama) | ⭐⭐⭐ | Medium | Free |

## 🌍 Multilingual Examples

The same quality should be maintained across all languages:
- **English** - Native-quality documents
- **Russian** - Cyrillic text, Russian names/companies
- **Chinese** - Simplified Chinese, Chinese business context
- **Hebrew** - Right-to-left text, Israeli context
- **Ukrainian** - Ukrainian language, post-Soviet context
- **French** - French language, European business context
- **Spanish** - Spanish language, Latin/European context

## 💡 Tips for Review

When you generate your honey, check that it:
1. ✅ Looks authentic (would you believe it's real at first glance?)
2. ✅ Contains appropriate markers (CONFIDENTIAL, INTERNAL, etc.)
3. ✅ Has realistic details (names, dates, amounts)
4. ✅ Matches the language/cultural context
5. ✅ Varies in sensitivity (some more "valuable" than others)

## ⚠️ Remember

All honey is **completely synthetic and fictional**. It's designed to:
- Attract attacker attention
- Waste attacker time
- Create false confidence
- Enable tracking and analysis

**Never use real data in honeypots!**


