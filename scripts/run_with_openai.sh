#!/usr/bin/env bash
# Lance l'app Flutter avec OPENAI_API_KEY chargée depuis .env (si présent).
# Usage: ./scripts/run_with_openai.sh        → appareil par défaut
#        ./scripts/run_with_openai.sh web    → Chrome (pour éviter "key not configured" sur web)
set -e
cd "$(dirname "$0")/.."
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi
if [ -z "$OPENAI_API_KEY" ]; then
  echo "⚠️  OPENAI_API_KEY non définie. Crée un fichier .env avec OPENAI_API_KEY=sk-..."
fi
if [ "${1:-}" = "web" ]; then
  flutter run -d chrome --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY:-}"
else
  flutter run --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY:-}"
fi
