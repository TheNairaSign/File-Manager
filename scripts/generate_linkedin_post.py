import os
import subprocess
import json
from urllib.request import Request, urlopen

# 1. Extract Git Commit info
commit_msg = subprocess.check_output(
    ["git", "log", "-1", "--pretty=%B"]
).decode("utf-8").strip()

git_diff = subprocess.check_output(
    ["git", "diff", "HEAD~1", "--stat"]
).decode("utf-8").strip()

# 2. Skip trivial or merge commits (optional)
if "Merge" in commit_msg or len(git_diff) < 10:
    print("Skipping LinkedIn post generation for minor/merge commit.")
    exit(0)

# 3. Construct AI Prompt
prompt = f"""
You are a developer building a File Manager app using Flutter (frontend) and Java (backend).
Write a engaging, professional, and concise LinkedIn post based on the following commit update:

Commit Summary: {commit_msg}
File Changes Stat:
{git_diff}

Guidelines:
- Structure it with: What was built/fixed, technical highlight (Flutter/Java-specific), and a quick takeaway.
- Use developer-friendly emojis and appropriate tech hashtags (#Flutter #Java #BuildInPublic #DevLog).
- Keep it authentic and readable for recruiter & engineer audiences.
"""

# 4. Call Gemini API (Replace API_KEY with your actual environment variable)
import json
from urllib.request import Request, urlopen

# 4. Call Gemini API using built-in libraries
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    print("Error: GEMINI_API_KEY environment variable not set.")
    exit(1)

url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={API_KEY}"
headers = {"Content-Type": "application/json"}
payload = json.dumps({"contents": [{"parts": [{"text": prompt}]}]}).encode("utf-8")

req = Request(url, data=payload, headers=headers, method="POST")

try:
    with urlopen(req) as response:
        res_data = json.loads(response.read().decode("utf-8"))
        post_text = res_data['candidates'][0]['content']['parts'][0]['text']
        
        os.makedirs("linkedin_drafts", exist_ok=True)
        filename = f"linkedin_drafts/draft_{os.popen('date +%Y%m%d_%H%M%S').read().strip()}.txt"
        with open(filename, "w") as f:
            f.write(post_text)
            
        print(f"\n🚀 LinkedIn Post Draft generated! Saved to: {filename}\n")
except Exception as e:
    print("Failed to generate post:", e)