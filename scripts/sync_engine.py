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
    
    # Model priority list: try fastest/cheapest first, fallback on quota errors
    models_to_try = ['gemini-2.0-flash-lite', 'gemini-2.0-flash']
    suggestion = None

    for model_name in models_to_try:
        print(f"🤖 Trying model: {model_name}...")
        max_retries = 3
        retry_delay = 60

        for attempt in range(max_retries):
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=full_prompt
                )
                suggestion = response.text
                print(f"✅ Success with model: {model_name}")
                break
            except errors.ClientError as e:
                if "429" in str(e) or "QUOTA_EXHAUSTED" in str(e):
                    if attempt < max_retries - 1:
                        print(f"⚠️ Quota exceeded on {model_name}. Waiting {retry_delay}s... (Attempt {attempt + 1}/{max_retries})")
                        time.sleep(retry_delay)
                        retry_delay += 30
                    else:
                        print(f"⚠️ {model_name} quota exhausted. Trying next model...")
                        break
                else:
                    print(f"❌ API Error on {model_name}: {e}")
                    break
            except Exception as e:
                print(f"❌ Unexpected error on {model_name}: {e}")
                break

        if suggestion:
            break

    if not suggestion:
        print("⚠️ All models quota exhausted for today. Skipping doc sync (non-blocking).")
        print("ℹ️  The workflow will retry on the next commit.")
        sys.exit(0)  # Exit 0 — quota issue should NOT block the CI pipeline
    
    print("📝 Gemini Suggestions received. Applying changes...")
    
    # Output for review/automation
    with open("PROMPT_AI_SUGGESTION.md", "w", encoding="utf-8") as f:
        f.write(suggestion)
    
    print("✅ Documentation sync draft generated in PROMPT_AI_SUGGESTION.md")

if __name__ == "__main__":
    main()
