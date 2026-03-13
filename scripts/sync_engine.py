import os
import sys
from git import Repo
from google import genai

def load_prompt(filename):
    path = os.path.join(os.path.dirname(__file__), '..', filename)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()
    return ""

def main():
    api_key = os.getenv("LLM_API_KEY")
    gh_token = os.getenv("GITHUB_TOKEN")
    
    if not api_key:
        print("❌ Error: LLM_API_KEY is not set.")
        sys.exit(1)

    print("🚀 Initializing Prompt-AI Sync Engine (New GenAI SDK)...")
    
    # Initialize the new Google GenAI client
    client = genai.Client(api_key=api_key)

    # Load Prompts
    maestro_prompt = load_prompt("Le Maestro de Flotte GitHub.md")
    architect_prompt = load_prompt("Architecte de Documentation & Changelog.md")
    guardian_prompt = load_prompt("Le Gardien du README.md")

    # Analyze local repo
    repo = Repo(os.getcwd())
    # Limit diff to prevent hitting token limits or triggering quota issues
    try:
        diff = repo.git.diff('HEAD~1' if len(list(repo.iter_commits())) > 1 else 'HEAD')
    except Exception:
        diff = ""
    
    if not diff:
        print("ℹ️ No changes detected since last commit.")
        diff = "Aucun changement récent (analyse de l'état actuel)."
    
    if len(diff) > 20000:
        print("⚠️ Diff is too large ({} chars), truncating to 20k...".format(len(diff)))
        diff = diff[:20000] + "\n... [Diff tronqué pour respecter les limites de quota]"

    import time
    from google.genai import errors

    print("🧠 Analyzing changes with Gemini 2.0 Flash (Free Tier Optimized)...")

    # Combined Instruction
    full_prompt = f"""
    CONTEXTE ET RÔLES :
    {maestro_prompt}
    
    {architect_prompt}
    
    {guardian_prompt}
    
    INSTRUCTION :
    Tu es un automate de synchronisation de documentation. 
    Analyse les changements suivants dans le dépôt et fournis les mises à jour nécessaires pour CHANGELOG.md et README.md.
    
    CHANGEMENTS DÉTECTÉS :
    {diff}
    """
    
    max_retries = 5  # Increased for free tier stability
    retry_delay = 90  # Increased to 90s to ensure quota reset

    for attempt in range(max_retries):
        try:
            # Generate content using the latest model
            response = client.models.generate_content(
                model='gemini-2.0-flash',
                contents=full_prompt
            )
            suggestion = response.text
            break
        except errors.ClientError as e:
            # 429 is the most common for free tier limits
            if "429" in str(e) or "QUOTA_EXHAUSTED" in str(e):
                if attempt < max_retries - 1:
                    print(f"⚠️ Quota exceeded (Free Tier). Waiting {retry_delay}s... (Attempt {attempt + 1}/{max_retries})")
                    time.sleep(retry_delay)
                    retry_delay += 30 # Exponential backoff
                else:
                    print("❌ Error: Quota exhausted after multiple retries. Try increasing limits or wait until tomorrow.")
                    sys.exit(1)
            else:
                print(f"❌ API Error: {e}")
                sys.exit(1)
        except Exception as e:
            print(f"❌ An unexpected error occurred: {e}")
            sys.exit(1)
    
    print("📝 Gemini Suggestions received. Applying changes...")
    
    # Output for review/automation
    with open("PROMPT_AI_SUGGESTION.md", "w", encoding="utf-8") as f:
        f.write(suggestion)
    
    print("✅ Documentation sync draft generated in PROMPT_AI_SUGGESTION.md")

if __name__ == "__main__":
    main()
