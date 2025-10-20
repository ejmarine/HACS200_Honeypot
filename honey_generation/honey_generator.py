#!/usr/bin/env python3
"""
Synthetic Honey Generator for Language-Dependent Honeypot
Generates fake passwords, documents, speeches, hashes, and contracts in multiple languages
"""

import os
import json
import hashlib
from pathlib import Path
from datetime import datetime
import google.generativeai as genai

# Configuration
LANGUAGES = {
    'English': 'en',
    'Russian': 'ru',
    'Chinese': 'zh',
    'Hebrew': 'he',
    'Ukrainian': 'uk',
    'French': 'fr',
    'Spanish': 'es'
}

HONEY_TYPES = {
    'passwords': {
        'count': 20,
        'prompt': 'Generate {count} realistic looking passwords that might be found in a leaked database. Include a mix of weak, medium, and strong passwords. Format as: username:password (one per line). Make them look authentic but completely fake.'
    },
    'research_documents': {
        'count': 3,
        'prompt': 'Create a realistic research document about {topic} in {language}. Include: title, author names, abstract, introduction, and key findings. Make it look like sensitive internal research but completely fictional. Length: ~500 words.'
    },
    'speeches': {
        'count': 2,
        'prompt': 'Write a realistic confidential corporate speech in {language} about {topic}. Include speaker introduction, main talking points, and conclusion. Make it seem sensitive/internal but completely fictional. Length: ~400 words.'
    },
    'contracts': {
        'count': 2,
        'prompt': 'Create a realistic looking confidential contract in {language} for {topic}. Include parties, terms, clauses, and signatures section. Make it look authentic but completely fictional. Length: ~600 words.'
    }
}

RESEARCH_TOPICS = [
    'quantum computing security vulnerabilities',
    'next-generation encryption methods',
    'AI-powered intrusion detection systems',
    'zero-trust architecture implementation',
    'biometric authentication systems'
]

SPEECH_TOPICS = [
    'quarterly security audit results',
    'new data protection initiatives',
    'upcoming merger and acquisition plans',
    'executive compensation strategy',
    'proprietary technology development roadmap'
]

CONTRACT_TOPICS = [
    'software licensing agreement',
    'non-disclosure agreement for R&D project',
    'vendor services contract',
    'employee non-compete agreement',
    'intellectual property transfer'
]


class HoneyGenerator:
    def __init__(self, api_key=None):
        """Initialize with Google Gemini API key"""
        if api_key is None:
            api_key = os.environ.get('GEMINI_API_KEY')
        
        if not api_key:
            raise ValueError("Please provide GEMINI_API_KEY environment variable or pass api_key parameter")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
    
    def generate_passwords(self, language, count=20):
        """Generate fake password list"""
        print(f"Generating passwords for {language}...", flush=True)
        
        prompt = f"""Generate {count} realistic looking username:password combinations that might be found in a leaked database.
        Mix of weak (password123), medium (Summer2024!), and strong (xK9$mP2#vL4@) passwords.
        Usernames should reflect {language} naming conventions.
        Output ONLY the list, one per line in format: username:password
        No explanations or additional text."""
        
        response = self.model.generate_content(prompt)
        return response.text.strip()
    
    def generate_document(self, language, doc_type, topic):
        """Generate a fake document (research/speech/contract)"""
        print(f"Generating {doc_type} in {language}: {topic}...", flush=True)
        
        lang_instruction = f"Write this ENTIRELY in {language} language" if language != 'English' else ""
        
        prompts = {
            'research': f"""{lang_instruction}
            Create a realistic confidential research document about: {topic}
            Include:
            - Document header with "CONFIDENTIAL" marking
            - Title and author names
            - Abstract
            - Introduction
            - Key findings (3-4 points)
            - Conclusion
            Make it look authentic but completely fictional. ~500 words.""",
            
            'speech': f"""{lang_instruction}
            Write a realistic confidential internal corporate speech about: {topic}
            Include:
            - "INTERNAL USE ONLY" header
            - Speaker introduction
            - Main talking points (4-5 points)
            - Call to action
            - Conclusion
            Make it seem sensitive but completely fictional. ~400 words.""",
            
            'contract': f"""{lang_instruction}
            Create a realistic confidential contract for: {topic}
            Include:
            - Contract header with document ID
            - "CONFIDENTIAL" marking
            - Parties involved (Party A and Party B with realistic company names)
            - Terms and conditions (4-5 clauses)
            - Payment/consideration terms
            - Signature section
            Make it authentic but completely fictional. ~600 words."""
        }
        
        response = self.model.generate_content(prompts[doc_type])
        return response.text.strip()
    
    def generate_hashes(self, password_content):
        """Generate MD5, SHA1, and SHA256 hashes from passwords"""
        print("Generating password hashes...", flush=True)
        
        hashes = []
        hashes.append("# Password Hashes (MD5, SHA1, SHA256)\n")
        hashes.append("# Format: username | MD5 | SHA1 | SHA256\n\n")
        
        for line in password_content.split('\n'):
            if ':' in line:
                username, password = line.strip().split(':', 1)
                md5 = hashlib.md5(password.encode()).hexdigest()
                sha1 = hashlib.sha1(password.encode()).hexdigest()
                sha256 = hashlib.sha256(password.encode()).hexdigest()
                hashes.append(f"{username} | {md5} | {sha1} | {sha256}\n")
        
        return ''.join(hashes)


def main():
    """Main execution function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate synthetic honey for honeypots')
    parser.add_argument('--api-key', help='Google Gemini API key (or set GEMINI_API_KEY env var)')
    parser.add_argument('--language', choices=list(LANGUAGES.keys()), help='Generate for specific language only')
    parser.add_argument('--output-dir', default='./honeypot_files', help='Output directory')
    parser.add_argument('--honey-type', choices=['passwords', 'research', 'speeches', 'contracts', 'hashes', 'all'], 
                       default='all', help='Type of honey to generate')
    
    args = parser.parse_args()
    
    # Initialize generator
    try:
        generator = HoneyGenerator(api_key=args.api_key)
    except ValueError as e:
        print(f"Error: {e}", flush=True)
        print("\nTo use this script, you need a Google Gemini API key:", flush=True)
        print("1. Get free API key: https://makersuite.google.com/app/apikey", flush=True)
        print("2. Set environment variable: export GEMINI_API_KEY='your-key-here'", flush=True)
        print("3. Or pass with --api-key flag", flush=True)
        return
    
    # Determine languages to process
    languages = [args.language] if args.language else list(LANGUAGES.keys())
    
    # Create output directory structure
    output_base = Path(args.output_dir)
    
    for language in languages:
        print(f"\n{'='*60}", flush=True)
        print(f"Processing: {language}", flush=True)
        print(f"{'='*60}\n", flush=True)
        
        lang_dir = output_base / language
        lang_dir.mkdir(parents=True, exist_ok=True)
        
        # Generate passwords
        if args.honey_type in ['passwords', 'all']:
            passwords = generator.generate_passwords(language, count=20)
            with open(lang_dir / 'passwords.txt', 'w', encoding='utf-8') as f:
                f.write(f"# Leaked Database Passwords - {language}\n")
                f.write(f"# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write("# WARNING: CONFIDENTIAL DATA\n\n")
                f.write(passwords)
            print(f"✓ Created: {lang_dir / 'passwords.txt'}", flush=True)
            
            # Generate hashes from passwords
            if args.honey_type in ['hashes', 'all']:
                hashes = generator.generate_hashes(passwords)
                with open(lang_dir / 'password_hashes.txt', 'w', encoding='utf-8') as f:
                    f.write(hashes)
                print(f"✓ Created: {lang_dir / 'password_hashes.txt'}", flush=True)
        
        # Generate research documents
        if args.honey_type in ['research', 'all']:
            for i, topic in enumerate(RESEARCH_TOPICS[:3], 1):
                doc = generator.generate_document(language, 'research', topic)
                with open(lang_dir / f'research_doc_{i}.txt', 'w', encoding='utf-8') as f:
                    f.write(doc)
                print(f"✓ Created: {lang_dir / f'research_doc_{i}.txt'}", flush=True)
        
        # Generate speeches
        if args.honey_type in ['speeches', 'all']:
            for i, topic in enumerate(SPEECH_TOPICS[:2], 1):
                speech = generator.generate_document(language, 'speech', topic)
                with open(lang_dir / f'speech_{i}.txt', 'w', encoding='utf-8') as f:
                    f.write(speech)
                print(f"✓ Created: {lang_dir / f'speech_{i}.txt'}", flush=True)
        
        # Generate contracts
        if args.honey_type in ['contracts', 'all']:
            for i, topic in enumerate(CONTRACT_TOPICS[:2], 1):
                contract = generator.generate_document(language, 'contract', topic)
                with open(lang_dir / f'contract_{i}.txt', 'w', encoding='utf-8') as f:
                    f.write(contract)
                print(f"✓ Created: {lang_dir / f'contract_{i}.txt'}", flush=True)
    
    print(f"\n{'='*60}", flush=True)
    print("✓ Honey generation complete!", flush=True)
    print(f"{'='*60}\n", flush=True)


if __name__ == '__main__':
    main()

