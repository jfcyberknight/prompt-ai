import os
import sys
import time
import requests
from git import Repo

# -----------------------------------------------------------
# Configuration
# -----------------------------------------------------------
SMART_ROUTER_URL = "https://ai-smart-router.vercel.app/api/chat"


def load_prompt(filename):
    path = os.path.join(os.path.dirname(__file__), '..', filename)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    return ""


def call_smart_router(api_secret, system_prompt, user_message, max_retries=3, retry_delay=60):
    """Appelle l'API centralisée ai-smart-router avec retry sur quota."""
    headers = {
        "Authorization": f"Bearer {api_secret}",
        "Content-Type": "application/json"
    }
    payload = {
        "messages": [
            {"role": "user", "content": f"{system_prompt}\n\n{user_message}"}
        ]
    }

    for attempt in range(max_retries):
        try:
            response = requests.post(SMART_ROUTER_URL, headers=headers, json=payload, timeout=60)

            if response.status_code == 200:
                data = response.json()
                provider = data.get("provider", "unknown")
                model = data.get("model", "unknown")
                print(f"✅ Response received from '{provider}' ({model}).")
                return data.get("content", "")

            elif response.status_code == 429:
                if attempt < max_retries - 1:
                    wait = retry_delay + (attempt * 30)
                    print(f"⚠️ Quota exceeded. Waiting {wait}s... (Attempt {attempt + 1}/{max_retries})")
                    time.sleep(wait)
                else:
                    print("⚠️ Quota exhausted on all retries. Skipping doc sync (non-blocking).")
                    return None

            elif response.status_code == 401:
                print("❌ Unauthorized. Check the LLM_API_KEY (API_SECRET) value.")
                sys.exit(1)

            else:
                print(f"❌ HTTP {response.status_code}: {response.text}")
                sys.exit(1)

        except requests.exceptions.Timeout:
            if attempt < max_retries - 1:
                print(f"⚠️ Request timed out. Retrying in 30s... (Attempt {attempt + 1}/{max_retries})")
                time.sleep(30)
            else:
                print("❌ Request timed out after multiple retries.")
                sys.exit(1)

        except requests.exceptions.RequestException as e:
            print(f"❌ Connection error: {e}")
            sys.exit(1)

    return None


def main():
    api_secret = os.getenv("LLM_API_KEY")

    if not api_secret:
        print("❌ Error: LLM_API_KEY (API_SECRET) is not set.")
        sys.exit(1)

    print("🚀 Initializing Prompt-AI Sync Engine (via AI Smart Router)...")

    # Load Prompts
    maestro_prompt = load_prompt("Le Maestro de Flotte GitHub.md")
    architect_prompt = load_prompt("Architecte de Documentation & Changelog.md")
    guardian_prompt = load_prompt("Le Gardien du README.md")

    # Analyze local repo diff
    repo = Repo(os.getcwd())
    try:
        diff = repo.git.diff('HEAD~1' if len(list(repo.iter_commits())) > 1 else 'HEAD')
    except Exception:
        diff = ""

    if not diff:
        print("ℹ️ No changes detected since last commit.")
        diff = "Aucun changement récent (analyse de l'état actuel du dépôt)."

    if len(diff) > 20000:
        print(f"⚠️ Diff too large ({len(diff)} chars), truncating to 20k...")
        diff = diff[:20000] + "\n... [Diff tronqué pour respecter les limites de quota]"

    system_prompt = f"""
    {maestro_prompt}

    {architect_prompt}

    {guardian_prompt}

    Tu es un automate de synchronisation de documentation.
    Analyse les changements suivants et fournis les mises à jour nécessaires pour CHANGELOG.md et README.md.
    """

    user_message = f"CHANGEMENTS DÉTECTÉS :\n{diff}"

    print("🧠 Requesting documentation analysis via AI Smart Router...")
    # The router handles provider fallback (Gemini → Groq) automatically server-side
    suggestion = call_smart_router(api_secret, system_prompt, user_message)

    if not suggestion:
        print("⚠️ No response received. Skipping doc sync (non-blocking).")
        sys.exit(0)

    print("📝 Writing suggestions to PROMPT_AI_SUGGESTION.md...")
    with open("PROMPT_AI_SUGGESTION.md", "w", encoding="utf-8") as f:
        f.write(suggestion)

    print("✅ Documentation sync draft generated in PROMPT_AI_SUGGESTION.md")


if __name__ == "__main__":
    main()
