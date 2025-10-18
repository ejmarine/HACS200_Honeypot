# Synthetic Honey Generation Guide

## Overview
This guide explains how to generate synthetic honey (fake data) for your language-dependent honeypot using AI tools.

## Option 1: Google Gemini API (Recommended - Free Tier Available)

### Setup
1. **Get API Key** (Free):
   - Visit: https://makersuite.google.com/app/apikey
   - Click "Create API Key"
   - Copy your key

2. **Install Dependencies**:
   ```bash
   pip install -r honey_requirements.txt
   ```

3. **Set API Key**:
   ```bash
   export GEMINI_API_KEY='your-api-key-here'
   ```

### Usage

**Generate all honey for all languages:**
```bash
python3 honey_generator.py
```

**Generate for specific language:**
```bash
python3 honey_generator.py --language Russian
```

**Generate specific honey type:**
```bash
python3 honey_generator.py --honey-type passwords
python3 honey_generator.py --honey-type research
python3 honey_generator.py --honey-type speeches
python3 honey_generator.py --honey-type contracts
```

**Custom output directory:**
```bash
python3 honey_generator.py --output-dir ./custom_honey
```

### Output Structure
```
honeypot_files/
├── English/
│   ├── passwords.txt
│   ├── password_hashes.txt
│   ├── research_doc_1.txt
│   ├── research_doc_2.txt
│   ├── research_doc_3.txt
│   ├── speech_1.txt
│   ├── speech_2.txt
│   ├── contract_1.txt
│   └── contract_2.txt
├── Russian/
│   └── ... (same structure)
└── ... (all other languages)
```

---

## Option 2: OpenAI API (High Quality, Paid)

### Setup
```bash
export OPENAI_API_KEY='your-key-here'
pip install openai
```

### Quick Script
```python
from openai import OpenAI
client = OpenAI()

response = client.chat.completions.create(
    model="gpt-4",
    messages=[{
        "role": "user",
        "content": "Generate 20 fake username:password combinations in Russian"
    }]
)
print(response.choices[0].message.content)
```

---

## Option 3: Ollama (Free, Local, No API Key)

### Setup
```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull a model (choose one)
ollama pull llama2          # Good general purpose
ollama pull mistral         # Better at code/structured
ollama pull codellama       # Best for technical content
```

### Usage
```bash
# Generate passwords
ollama run llama2 "Generate 20 fake username:password combinations for a honeypot. Format: username:password"

# Generate research document
ollama run mistral "Create a fake confidential research document about quantum computing in Russian language. Include title, author, abstract, and key findings."
```

### Python Integration with Ollama
```python
import subprocess
import json

def generate_with_ollama(prompt, model="llama2"):
    result = subprocess.run(
        ["ollama", "run", model, prompt],
        capture_output=True,
        text=True
    )
    return result.stdout

# Example
passwords = generate_with_ollama(
    "Generate 20 fake username:password combinations. Format: username:password"
)
print(passwords)
```

---

## Option 4: Anthropic Claude (High Quality, Paid)

### Setup
```bash
export ANTHROPIC_API_KEY='your-key-here'
pip install anthropic
```

### Quick Script
```python
import anthropic

client = anthropic.Anthropic()
message = client.messages.create(
    model="claude-3-5-sonnet-20241022",
    max_tokens=1024,
    messages=[{
        "role": "user",
        "content": "Generate 20 fake passwords for a honeypot"
    }]
)
print(message.content[0].text)
```

---

## Honey Types Generated

### 1. Passwords (`passwords.txt`)
- 20 fake username:password combinations
- Mix of weak, medium, and strong passwords
- Usernames reflect language naming conventions

### 2. Password Hashes (`password_hashes.txt`)
- MD5, SHA1, and SHA256 hashes
- Derived from the generated passwords
- Looks like leaked database dump

### 3. Research Documents (`research_doc_*.txt`)
- 3 documents per language
- Topics: quantum computing, encryption, AI security, etc.
- Includes: title, authors, abstract, findings
- Marked as "CONFIDENTIAL"

### 4. Speeches (`speech_*.txt`)
- 2 speeches per language
- Topics: security audits, mergers, compensation, etc.
- Includes: speaker intro, talking points, conclusion
- Marked as "INTERNAL USE ONLY"

### 5. Contracts (`contract_*.txt`)
- 2 contracts per language
- Types: licensing, NDA, vendor, non-compete, IP
- Includes: parties, terms, clauses, signatures
- Marked as "CONFIDENTIAL"

---

## Best Practices

### 1. **Use Realistic but Fake Data**
- Never use real PII or sensitive information
- Make it believable but clearly synthetic
- Include realistic formatting and markers

### 2. **Vary Complexity**
- Mix simple and complex documents
- Include different file sizes
- Vary data "sensitivity" levels

### 3. **Update Regularly**
- Regenerate honey periodically
- Keep it fresh to maintain realism
- Update dates and timestamps

### 4. **Cost Considerations**
- **Free**: Ollama (local), Gemini (limited free tier)
- **Paid**: OpenAI ($), Claude ($$)
- **Recommendation**: Start with Gemini free tier or Ollama

### 5. **Quality Ranking**
1. Claude 3.5 Sonnet (best quality, expensive)
2. GPT-4 (excellent, moderate cost)
3. Gemini Pro (good, free tier available)
4. Llama2/Mistral via Ollama (decent, free, local)

---

## Integration with Your Honeypot

### Method 1: Pre-generate and Deploy
```bash
# Generate all honey
python3 honey_generator.py

# Copy to honeypot directories
cp honeypot_files/English/* /path/to/honeypot/files/
```

### Method 2: Dynamic Generation
Integrate the generator into your `create.sh` or `main.sh` scripts:

```bash
#!/bin/bash
# In your create.sh

# Generate fresh honey
python3 /path/to/honey_generator.py --language English --output-dir ./temp_honey

# Deploy to honeypot
cp temp_honey/English/* /honeypot/files/
```

### Method 3: Scheduled Updates
```bash
# Add to crontab for weekly regeneration
0 0 * * 0 cd /path/to/honeypot && python3 honey_generator.py
```

---

## Troubleshooting

### Error: "No API key found"
```bash
# Make sure you've exported the key
export GEMINI_API_KEY='your-key-here'

# Or pass directly
python3 honey_generator.py --api-key 'your-key-here'
```

### Error: "Module not found"
```bash
pip install -r honey_requirements.txt
```

### Rate Limiting
- Gemini free tier: 60 requests/minute
- Add delays between requests if needed
- Consider using Ollama for unlimited local generation

### Poor Quality Output
- Try different models (GPT-4 > Gemini > Llama2)
- Refine prompts in the script
- Generate multiple versions and pick best

---

## Sample Output Examples

### Passwords
```
admin:P@ssw0rd123
dmitry_ivanov:Москва2024!
zhang_wei:北京qwerty88
```

### Research Document Header
```
CONFIDENTIAL - DO NOT DISTRIBUTE

Research Report: Next-Generation Quantum Encryption Methods

Author: Dr. Sarah Johnson, Dr. Michael Chen
Date: October 2025
Classification: Top Secret

ABSTRACT
This research investigates...
```

---

## Security Note

⚠️ **Important**: All generated data is completely synthetic and fictional. This honey is designed to:
- Attract and engage attackers
- Waste attacker time
- Provide false confidence
- Enable tracking and analysis

Never include real data in honeypots!

---

## Next Steps

1. ✅ Install dependencies
2. ✅ Get API key (or install Ollama)
3. ✅ Run honey generator
4. ✅ Review generated content
5. ✅ Deploy to honeypot directories
6. ✅ Test with your recycling scripts
7. ✅ Monitor attacker interaction

---

## Questions?

- Check the main README.md
- Review example project in Course Context
- Refer to Standup 2 documentation

