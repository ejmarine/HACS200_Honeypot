# Honey Generation Cheat Sheet

## ⚡ Quick Commands

### Gemini API (Recommended)
```bash
# Setup (one-time)
pip install google-generativeai
# export GEMINI_API_KEY='your-key-from-https://makersuite.google.com/app/apikey'
export GEMINI_API_KEY='AIzaSyDCPHTFpKLciqs-MHkzzbVZ4xutBJYF0zs'

# Generate all honey
./honey_generator.py

# Generate specific language
./honey_generator.py --language Russian

# Generate specific type
./honey_generator.py --honey-type passwords
./honey_generator.py --honey-type research
./honey_generator.py --honey-type speeches
./honey_generator.py --honey-type contracts
```

### Ollama (Local, No API)
```bash
# Setup (one-time)
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama2

# Generate all honey
./honey_generator_ollama.sh

# Use better model
./honey_generator_ollama.sh --model mistral
```

## 📁 File Locations

| File | Purpose |
|------|---------|
| `honey_generator.py` | Python/Gemini generator |
| `honey_generator_ollama.sh` | Bash/Ollama generator |
| `honeypot_files/` | Generated honey output |
| `sample_outputs/` | Example outputs |
| `QUICKSTART_HONEY.md` | Quick start guide |
| `AI_HONEY_SUMMARY.md` | Complete summary |
| `HONEY_WORKFLOW.md` | Visual workflow |

## 🎯 Common Tasks

### Test Generation
```bash
./honey_generator.py --language English --honey-type passwords
cat honeypot_files/English/passwords.txt
```

### Deploy to Honeypot
```bash
cp honeypot_files/English/* /path/to/honeypot/English/
```

### Automated Weekly Updates
```bash
crontab -e
# Add: 0 0 * * 0 cd /path/to/honeypot && ./honey_generator.py
```

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| "No API key found" | `export GEMINI_API_KEY='your-key'` |
| "Rate limit exceeded" | Wait 1 minute or use Ollama |
| "Module not found" | `pip install google-generativeai` |
| "Ollama not found" | `curl -fsSL https://ollama.com/install.sh \| sh` |

## 🌍 Languages Supported

English • Russian • Chinese • Hebrew • Ukrainian • French • Spanish

## 🍯 Honey Types Generated

- **Passwords** (20) - Fake username:password pairs
- **Hashes** - MD5, SHA1, SHA256 from passwords
- **Research Docs** (3) - Confidential technical documents
- **Speeches** (2) - Internal executive speeches
- **Contracts** (2) - Legal agreements, NDAs

## 💰 Cost Comparison

| Tool | Cost | Speed | Quality |
|------|------|-------|---------|
| Gemini | FREE | ⚡⚡⚡ | ⭐⭐⭐⭐ |
| Ollama | FREE | ⚡⚡ | ⭐⭐⭐ |
| GPT-4 | ~$10 | ⚡⚡⚡ | ⭐⭐⭐⭐⭐ |

## 📋 Quality Checklist

- [ ] Realistic formatting
- [ ] Appropriate language
- [ ] Confidential markers ("CONFIDENTIAL", "INTERNAL USE ONLY")
- [ ] Believable content
- [ ] Varied sensitivity

## 🔗 Quick Links

- API Key: https://makersuite.google.com/app/apikey
- Ollama Docs: https://ollama.com/docs
- Project README: `README.md`

## ⏱️ Time Estimates

- **Setup**: 2-10 minutes
- **Generation** (7 languages): 30 min - 2 hours
- **Review**: 15 minutes
- **Total**: ~1-3 hours

## 📞 Need Help?

1. Check `QUICKSTART_HONEY.md`
2. Review `sample_outputs/`
3. Test with: `./honey_generator.py --language English --honey-type passwords`

---

**TL;DR**: `export GEMINI_API_KEY='key'` → `./honey_generator.py` → Check `honeypot_files/`

