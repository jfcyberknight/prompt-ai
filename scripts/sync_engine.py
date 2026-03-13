import os
import sys
from git import Repo
import openai

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

    print("🚀 Initializing Prompt-AI Sync Engine...")
    
    # Load Prompts
    maestro_prompt = load_prompt("Le Maestro de Flotte GitHub.md")
    architect_prompt = load_prompt("Architecte de Documentation & Changelog.md")
    guardian_prompt = load_prompt("Le Gardien du README.md")

    # Analyze local repo
    repo = Repo(os.getcwd())
    diff = repo.git.diff('HEAD~1' if len(list(repo.iter_commits())) > 1 else 'HEAD')
    
    client = openai.OpenAI(api_key=api_key)
    
    print("🧠 Analyzing changes with LLM...")
    
    # System instructions combining our prompts
    system_instruction = f"""
    {maestro_prompt}
    
    {architect_prompt}
    
    {guardian_prompt}
    
    Tu es un automate de synchronisation de documentation. 
    Analyse les changements suivants et fournis les mises à jour pour CHANGELOG.md et README.md.
    """
    
    user_content = f"Voici les derniers changements dans le dépôt :\n{diff}"
    
    response = client.chat.completions.create(
        model="gpt-4-turbo-preview",
        messages=[
            {"role": "system", "content": system_instruction},
            {"role": "user", "content": user_content}
        ]
    )
    
    suggestion = response.choices[0].message.content
    print("📝 LLM Suggestions received. Applying changes...")
    
    # Logic to parse the suggestion and apply to files would go here.
    # For now, we output it to a file for manual review or further automation.
    with open("PROMPT_AI_SUGGESTION.md", "w", encoding="utf-8") as f:
        f.write(suggestion)
    
    print("✅ Documentation sync draft generated in PROMPT_AI_SUGGESTION.md")

if __name__ == "__main__":
    main()
