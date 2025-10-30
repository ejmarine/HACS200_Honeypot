# Quick Start: Generate Synthetic Honey

## 🚀 Fastest Way to Get Started

### Option A: Google Gemini (Free API, Best Quality)

**1. Get API Key (30 seconds):**
- Visit: https://makersuite.google.com/app/apikey
- Click "Create API Key" → Copy it

**2. Generate Honey:**
```bash
cd /home/skirub/Files/Education/hacs200/HACS200_Honeypot

# Install dependencies
pip install google-generativeai

# Set your API key
export GEMINI_API_KEY='paste-your-key-here'

# Generate all honey for all languages
./honey_generator.py
```

**Done!** Check `honeypot_files/` for your synthetic honey.

---

### Option B: Ollama (100% Free, No API Key, Runs Locally)

**1. Install Ollama:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama2  # Download model (4GB)
```

**2. Generate Honey:**
```bash
cd /home/skirub/Files/Education/hacs200/HACS200_Honeypot

# Run the generator
./honey_generator_ollama.sh
```

**Done!** Check `honeypot_files/` for your synthetic honey.

---

## 📁 What Gets Generated

For each language (English, Russian, Chinese, Hebrew, Ukrainian, French, Spanish):

```
honeypot_files/
└── English/
    ├── passwords.txt              # 20 fake passwords
    ├── password_hashes.txt        # MD5, SHA1, SHA256 hashes
    ├── research_doc_1.txt         # Confidential research
    ├── research_doc_2.txt         # More research
    ├── research_doc_3.txt         # Even more research
    ├── speech_1.txt               # Internal corporate speech
    ├── speech_2.txt               # Another speech
    ├── contract_1.txt             # Confidential contract
    └── contract_2.txt             # Another contract
```

---

## 🎯 Common Use Cases

### Generate for One Language Only
```bash
# Gemini version
./honey_generator.py --language Russian

# Ollama version
# (Edit honey_generator_ollama.sh and change LANGUAGES array)
```

### Generate Only Passwords
```bash
./honey_generator.py --honey-type passwords
```

### Use Different Model (Ollama)
```bash
./honey_generator_ollama.sh --model mistral  # Better quality
./honey_generator_ollama.sh --model codellama  # Technical content
```

### Custom Output Directory
```bash
./honey_generator.py --output-dir /path/to/custom/dir
./honey_generator_ollama.sh --output-dir /path/to/custom/dir
```

---

## 🔄 Integrate with Your Honeypot

### Method 1: Copy Files Manually
```bash
# After generation
cp honeypot_files/English/* /your/honeypot/path/English/
cp honeypot_files/Russian/* /your/honeypot/path/Russian/
# ... etc
```

### Method 2: Modify create.sh
Add to your `recycling/create.sh`:
```bash
# Generate fresh honey before creating honeypot
/path/to/honey_generator.py --language English --output-dir ./temp_honey
cp temp_honey/English/* /honeypot/files/
```

### Method 3: Automate with Cron
```bash
# Add to crontab for weekly updates
crontab -e

# Add this line (runs every Sunday at midnight)
0 0 * * 0 cd /home/skirub/Files/Education/hacs200/HACS200_Honeypot && ./honey_generator.py
```

---

## 💡 Tips & Tricks

### 1. Cost Comparison
- **Ollama**: FREE (runs locally, uses your CPU/GPU)
- **Gemini**: FREE tier (60 requests/min, then $)
- **OpenAI GPT-4**: ~$0.03 per request
- **Claude**: ~$0.02 per request

**Recommendation**: Start with Ollama or Gemini free tier

### 2. Quality Ranking
1. **Claude 3.5 Sonnet** - Best quality, multilingual
2. **GPT-4** - Excellent, good at following formats
3. **Gemini Pro** - Good, free tier available
4. **Mistral (Ollama)** - Decent, better than llama2
5. **Llama2 (Ollama)** - OK, completely free

### 3. Speed
- **Ollama**: ~30 seconds per document (local CPU)
- **Gemini**: ~5-10 seconds per document (API)
- **GPT-4**: ~3-5 seconds per document (API)

### 4. Customization
Edit the generator scripts to:
- Add more topics
- Change document formats
- Adjust password complexity
- Add new honey types

---

## ⚠️ Important Notes

### Security
- ✅ All generated data is **completely synthetic**
- ✅ No real PII or sensitive information
- ✅ Safe to deploy in honeypots
- ❌ Never use real passwords or data

### Rate Limits
- **Gemini Free**: 60 requests/minute
- **Solution**: Add delays or use Ollama for unlimited generation

### Multilingual Quality
- **Best**: Claude, GPT-4 (excellent in all languages)
- **Good**: Gemini (good in major languages)
- **OK**: Ollama (English best, others variable)

---

## 🐛 Troubleshooting

### "No API key found"
```bash
export GEMINI_API_KEY='your-key-here'
# Or pass directly:
./honey_generator.py --api-key 'your-key-here'
```

### "Ollama command not found"
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama2
```

### "Module not found"
```bash
pip install google-generativeai
# or
pip install -r honey_requirements.txt
```

### Poor Output Quality
- Try a better model: `--model mistral` instead of llama2
- Or switch to Gemini/GPT-4
- Edit prompts in the script for better results

### Generation Too Slow
- Use Gemini API instead of Ollama (much faster)
- Or run Ollama with GPU acceleration
- Generate in batches (one language at a time)

---

## 📚 Next Steps

1. ✅ Generate your honey (use command above)
2. ✅ Review the generated files
3. ✅ Deploy to your honeypot directories
4. ✅ Test that attackers can access the files
5. ✅ Monitor logs to see what attackers access
6. ✅ Analyze which honey attracts most attention

---

## 📖 Full Documentation

For detailed information, see:
- `HONEY_GENERATION_GUIDE.md` - Complete guide
- `honey_generator.py` - Python/Gemini version
- `honey_generator_ollama.sh` - Bash/Ollama version
- `honey_requirements.txt` - Python dependencies

---

## 🆘 Need Help?

**Quick Tests:**
```bash
# Test Gemini API
./honey_generator.py --language English --honey-type passwords

# Test Ollama
ollama run llama2 "Say hello"
./honey_generator_ollama.sh
```

**Common Issues:**
1. **API Key Issues**: Double-check you exported it correctly
2. **Slow Generation**: Use Gemini instead of Ollama
3. **Bad Quality**: Try better model (mistral, GPT-4, Claude)

**Resources:**
- Gemini API Docs: https://ai.google.dev/docs
- Ollama Docs: https://ollama.com/docs
- Example Project: `/Course Context/Example Student Project/`


