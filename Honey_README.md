## HACS200 Honeypot Research Project

**Group 1B - Fantastic: Language-Dependent Honeypot**

This project utilizes multiple honeypots that vary in language to determine relationships between system language and attacker interest or behavior.

### 🌍 Languages
English, Russian, Chinese, Hebrew, Ukrainian, French, Spanish

### 🍯 Honey Types
- SSH Banners
- Passwords
- Research Documents
- Speeches
- Hashes
- Contracts

---

## 📚 Quick Links

### Honeypot Operations
- **Main Scripts** → `recycling/` directory
- **Honeypot Files** → `honeypot_files/` directory
- **Data Collection** → `data_collection/` directory

### Honey Generation (NEW! 🎉)
- **Quick Start** → `QUICKSTART_HONEY.md` ⭐ Start here!
- **Complete Summary** → `AI_HONEY_SUMMARY.md`
- **Full Guide** → `HONEY_GENERATION_GUIDE.md`
- **Example Outputs** → `sample_outputs/`

### Tools
- **Python Generator (Gemini)** → `honey_generator.py`
- **Bash Generator (Ollama)** → `honey_generator_ollama.sh`
- **Requirements** → `honey_requirements.txt`

---

## 🚀 Generating Synthetic Honey

### Option 1: Google Gemini API (Recommended - Free)
```bash
# Get free API key: https://makersuite.google.com/app/apikey
pip install google-generativeai
export GEMINI_API_KEY='your-key-here'
./honey_generator.py
```

### Option 2: Ollama (Local, No API Key)
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama2
./honey_generator_ollama.sh
```

**See `QUICKSTART_HONEY.md` for detailed instructions.**

---

## 📁 Project Structure

```
HACS200_Honeypot/
├── recycling/              # Main honeypot scripts
├── honeypot_files/         # Honey deployment directory
├── data_collection/        # Data collection scripts
├── honey_generator.py      # AI honey generator (Gemini)
├── honey_generator_ollama.sh  # AI honey generator (Ollama)
├── sample_outputs/         # Example honey outputs
└── [Documentation files]
```

---

## 🎯 Project Workflow

1. **Generate Honey** → Use AI tools to create synthetic data
2. **Deploy Honeypots** → Use scripts in `recycling/`
3. **Collect Data** → Scripts in `data_collection/`
4. **Analyze Results** → Compare language-based attacker behavior

---

## 📖 Getting Started

### For Honey Generation
1. Read `QUICKSTART_HONEY.md`
2. Choose tool (Gemini or Ollama)
3. Generate honey
4. Review `sample_outputs/` for quality comparison

### For Honeypot Operations
1. Review scripts in `recycling/`
2. Configure honeypot settings
3. Deploy using creation scripts
4. Monitor using data collection scripts

---

## 🔗 Additional Resources

- Example Student Project: `../Course Context/Example Student Project/`
- Standup 2 Documentation: `../drive-download-*/`
- Course Syllabus: `../Course Context/`

---

## ⚠️ Important Notes

- All honey is **completely synthetic and fictional**
- Never use real passwords or PII
- Honey designed for attacker deception only
- See documentation for security best practices

