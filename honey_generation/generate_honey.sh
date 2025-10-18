#!/bin/bash
# Gemini-Only Honey Generator
# Quick wrapper to generate synthetic honey using Google Gemini API

# Set your Gemini API key
export GEMINI_API_KEY='your key'

# Activate virtual environment
source "$(dirname "$0")/honey_env/bin/activate"

# Run the Python generator with any arguments passed
python3 "$(dirname "$0")/honey_generator.py" "$@"

# Deactivate when done
deactivate

