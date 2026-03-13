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
    diff = repo.git.diff('HEAD~1' if len(list(repo.iter_commits())) > 1 else 'HEAD')
    
    if not diff:
        print("ℹ️ No changes detected since last commit.")
        diff = "Aucun changement récent (analyse de l'état actuel)."

    print("🧠 Analyzing changes with Gemini...")
    
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
    
    # Generate content using the new SDK
    response = client.models.generate_content(
        model='gemini-1.5-pro',
        contents=full_prompt
    )
    
    suggestion = response.text
    print("📝 Gemini Suggestions received. Applying changes...")
    
    # Output for review/automation
    with open("PROMPT_AI_SUGGESTION.md", "w", encoding="utf-8") as f:
        f.write(suggestion)
    
    print("✅ Documentation sync draft generated in PROMPT_AI_SUGGESTION.md")

if __name__ == "__main__":
    main()
