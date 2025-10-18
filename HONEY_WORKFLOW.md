# Honey Generation & Deployment Workflow

## 📊 Complete Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    HONEY GENERATION WORKFLOW                    │
└─────────────────────────────────────────────────────────────────┘

    STEP 1: Choose Your AI Tool
    ────────────────────────────────
    
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ Google       │  │   Ollama     │  │  OpenAI      │
    │  Gemini      │  │   (Local)    │  │  GPT-4       │
    │              │  │              │  │              │
    │ ✓ Free       │  │ ✓ Free       │  │ ✗ Paid       │
    │ ✓ Fast       │  │ ✓ Private    │  │ ✓ Best       │
    │ ✓ Easy       │  │ ✓ Unlimited  │  │ ✓ Fast       │
    └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
           │                 │                 │
           └─────────────────┴─────────────────┘
                             │
                             ▼
    
    STEP 2: Setup & Configuration
    ────────────────────────────────
    
    ┌─────────────────────────────────────────┐
    │  Gemini:                                │
    │  1. Get API key (free)                  │
    │  2. pip install google-generativeai     │
    │  3. export GEMINI_API_KEY='key'         │
    │                                         │
    │  Ollama:                                │
    │  1. Install Ollama                      │
    │  2. ollama pull llama2                  │
    │  3. Ready to go!                        │
    └─────────────────────────────────────────┘
                             │
                             ▼
    
    STEP 3: Run Generator
    ────────────────────────────────
    
    ┌─────────────────────────────────────────┐
    │  ./honey_generator.py                   │
    │         OR                              │
    │  ./honey_generator_ollama.sh            │
    │                                         │
    │  Options:                               │
    │  --language Russian                     │
    │  --honey-type passwords                 │
    │  --output-dir /custom/path              │
    └─────────────────────────────────────────┘
                             │
                             ▼
    
    STEP 4: Honey Generation
    ────────────────────────────────
    
         For Each Language:
         
    ┌────────────────┐  ┌────────────────┐  ┌────────────────┐
    │   Passwords    │  │   Research     │  │   Speeches     │
    │                │  │   Documents    │  │                │
    │ • 20 fake      │  │ • 3 docs       │  │ • 2 speeches   │
    │   passwords    │  │ • Confidential │  │ • Internal     │
    │ • Mixed        │  │ • Technical    │  │ • Executive    │
    │   strength     │  │                │  │                │
    └────────┬───────┘  └────────┬───────┘  └────────┬───────┘
             │                   │                   │
             └───────────────────┴───────────────────┘
                                 │
    ┌────────────────┐  ┌────────▼───────┐  ┌────────────────┐
    │   Hashes       │  │   Contracts    │  │   [Future      │
    │                │  │                │  │    Types]      │
    │ • MD5, SHA1    │  │ • 2 contracts  │  │                │
    │ • SHA256       │  │ • Legal docs   │  │ • Custom       │
    │ • From PWs     │  │ • NDAs, etc.   │  │   honey        │
    └────────────────┘  └────────────────┘  └────────────────┘
                                 │
                                 ▼
    
    STEP 5: Output Structure
    ────────────────────────────────
    
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
    │   └── [same files, Russian content]
    ├── Chinese/
    │   └── [same files, Chinese content]
    └── ... (7 languages total)
    
                                 │
                                 ▼
    
    STEP 6: Quality Review
    ────────────────────────────────
    
    ┌─────────────────────────────────────────┐
    │  Check generated honey:                 │
    │                                         │
    │  ✓ Realistic formatting?                │
    │  ✓ Appropriate language?                │
    │  ✓ Confidential markers?                │
    │  ✓ Believable content?                  │
    │  ✓ Varied sensitivity levels?           │
    │                                         │
    │  Compare with: sample_outputs/          │
    └─────────────────────────────────────────┘
                                 │
                                 ▼
    
    STEP 7: Deploy to Honeypots
    ────────────────────────────────
    
    ┌─────────────────────────────────────────┐
    │  Option A: Manual Copy                  │
    │  cp honeypot_files/English/* /pot/en/   │
    │                                         │
    │  Option B: Integrate with Scripts       │
    │  # Add to recycling/create.sh           │
    │  ./honey_generator.py --language $LANG  │
    │                                         │
    │  Option C: Automated (Cron)             │
    │  0 0 * * 0 ./honey_generator.py         │
    └─────────────────────────────────────────┘
                                 │
                                 ▼
    
    STEP 8: Monitor & Analyze
    ────────────────────────────────
    
    ┌─────────────────────────────────────────┐
    │  Track which honey attracts attackers:  │
    │                                         │
    │  • Which files accessed?                │
    │  • Which languages more attractive?     │
    │  • Password strength preferences?       │
    │  • Document types of interest?          │
    │                                         │
    │  Use: data_collection scripts           │
    └─────────────────────────────────────────┘
                                 │
                                 ▼
    
    STEP 9: Iterate & Improve
    ────────────────────────────────
    
    ┌─────────────────────────────────────────┐
    │  Based on attacker behavior:            │
    │                                         │
    │  • Regenerate honey weekly/monthly      │
    │  • Adjust topics to trends              │
    │  • Vary sensitivity levels              │
    │  • Add new honey types                  │
    │  • Refine prompts for better quality    │
    └─────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         SUCCESS! 🎉                             │
│  You now have realistic, multilingual synthetic honey for your  │
│  language-dependent honeypot research project!                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 Quick Decision Tree

```
Start: Need to generate honey?
  │
  ├─ Do you have 2 minutes? ─── YES ─→ Use Gemini (Free, Fast)
  │                                    1. Get API key
  │                                    2. ./honey_generator.py
  │
  ├─ Want no API keys? ────── YES ─→ Use Ollama (Free, Local)
  │                                    1. Install Ollama
  │                                    2. ./honey_generator_ollama.sh
  │
  ├─ Need best quality? ───── YES ─→ Use GPT-4/Claude (Paid)
  │                                    1. Get API key
  │                                    2. Modify script
  │
  └─ Want to test first? ──── YES ─→ Check sample_outputs/
                                       See what to expect
```

## ⏱️ Time Estimates

| Step | Gemini | Ollama | Manual |
|------|--------|--------|--------|
| Setup | 2 min | 10 min | 0 min |
| Generate All (7 languages) | 30 min | 2 hours | 8+ hours |
| Review | 15 min | 15 min | 30 min |
| Deploy | 5 min | 5 min | 5 min |
| **Total** | **~1 hour** | **~2.5 hours** | **~9 hours** |

## 💰 Cost Breakdown

### Your Project Needs:
- 7 languages × 50 requests/language = **~350 API requests**

| Tool | Total Cost | Cost per Request |
|------|------------|------------------|
| **Gemini Free Tier** | $0.00 | Free (60/min limit) |
| **Ollama** | $0.00 | Free (unlimited) |
| **GPT-4** | ~$10.50 | $0.03 per request |
| **Claude 3.5** | ~$7.00 | $0.02 per request |

**Recommendation**: Gemini free tier is perfect for your project!

## 📋 Checklist

### Before Generation
- [ ] Choose AI tool (Gemini recommended)
- [ ] Get API key (if using Gemini/GPT-4/Claude)
- [ ] Install dependencies (`pip install google-generativeai`)
- [ ] Review sample outputs to set quality expectations

### During Generation
- [ ] Set API key: `export GEMINI_API_KEY='key'`
- [ ] Run generator: `./honey_generator.py`
- [ ] Monitor progress (watch terminal output)
- [ ] Check for errors or rate limits

### After Generation
- [ ] Review generated files in `honeypot_files/`
- [ ] Compare quality with `sample_outputs/`
- [ ] Test language accuracy (native speakers if possible)
- [ ] Verify confidential markers present

### Deployment
- [ ] Copy honey to honeypot directories
- [ ] Test attacker access to files
- [ ] Configure logging to track access
- [ ] Set up monitoring scripts

### Ongoing
- [ ] Monitor which honey attracts attention
- [ ] Regenerate honey periodically (weekly/monthly)
- [ ] Analyze attacker behavior patterns
- [ ] Document findings for research

## 🔄 Integration Examples

### Example 1: Standalone Generation
```bash
cd /home/skirub/Files/Education/hacs200/HACS200_Honeypot
export GEMINI_API_KEY='your-key'
./honey_generator.py
ls honeypot_files/English/
```

### Example 2: Integrate with Recycling Script
```bash
# Add to recycling/create.sh
echo "Generating fresh honey..."
/path/to/honey_generator.py --language English --output-dir /tmp/honey
cp /tmp/honey/English/* /honeypot/target/files/
echo "Honey deployed!"
```

### Example 3: Automated Weekly Updates
```bash
# Add to crontab
crontab -e

# Every Sunday at midnight
0 0 * * 0 cd /home/skirub/Files/Education/hacs200/HACS200_Honeypot && ./honey_generator.py && /path/to/deploy_script.sh
```

### Example 4: Language-Specific Generation
```bash
# Generate only Russian honey
./honey_generator.py --language Russian

# Generate only passwords for all languages
./honey_generator.py --honey-type passwords

# Custom output location
./honey_generator.py --output-dir /custom/path
```

## 🎨 Customization Tips

### Add New Topics
Edit `honey_generator.py` or `honey_generator_ollama.sh`:
```python
RESEARCH_TOPICS = [
    'quantum computing security',
    'blockchain vulnerabilities',  # Add new topic
    'AI security frameworks',       # Add new topic
]
```

### Adjust Password Complexity
```python
def generate_passwords(self, language, count=20):
    prompt = f"""Generate {count} passwords.
    70% strong (12+ chars, special chars)
    20% medium (8-12 chars)
    10% weak (6-8 chars, common words)
    """
```

### Change Document Length
```python
'research_documents': {
    'prompt': '... Length: ~1000 words.'  # Change from 500
}
```

## 📞 Support Resources

### Documentation
- `QUICKSTART_HONEY.md` - Fastest way to start
- `AI_HONEY_SUMMARY.md` - Complete overview (this doc)
- `HONEY_GENERATION_GUIDE.md` - Detailed guide
- `sample_outputs/` - Quality examples

### Troubleshooting
- API key issues → Check environment variable
- Rate limits → Use Ollama or wait
- Poor quality → Try GPT-4 or refine prompts
- Wrong language → Verify language parameter

### Testing
```bash
# Quick test (one language, one honey type)
./honey_generator.py --language English --honey-type passwords

# Verify output
cat honeypot_files/English/passwords.txt

# Compare with sample
diff honeypot_files/English/passwords.txt sample_outputs/English/sample_passwords.txt
```

---

**Ready to generate honey? Start with Step 1 above!** 🍯


