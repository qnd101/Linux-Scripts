#!/bin/sh

# Sanitize input
img_path=$1
([ -e "$img_path" ] && echo "$img_path" | grep ".png$") || {
    echo "ERR: Received '$img_path'. Provide a valid .png file!" >&2
    exit 1
}

language=$2
[ -z "$language" ] || [ -z "$(echo "$language" | tr -d "a-zA-Z0-9")" ] || {
    echo "ERR: Received '$language'. Provide a valid language name!" >&2
    exit 1
}

model=gemini-3-flash-preview
case "$3" in
    fast)
        model=gemini-2.5-flash
        ;;
    pro)
        model=gemini-3-pro-preview
        ;;
esac
echo "Using model: $model"

GEMINI_API_KEY=$(cat "$HOME/.gemini-api-key")

img_base64=$(base64 "$img_path" | tr -d '\n')

json_data=$(printf '{
    "contents": [
      {
        "parts": [
          {
            "text": "Convert this image into code of language %s. Provide the output purely in code. Do NOT embded it inside markdown syntax."
          },
          {
        "inline_data": {
              "mime_type":"image/png",
              "data": "%s"
            }
          }
        ]
      }
    ]
  }' "$language" "$img_base64")

echo "Thinking..."

# curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent" \
#   -H "x-goog-api-key: $GEMINI_API_KEY" \
#   -H 'Content-Type: application/json' \
#   -X POST \
#   -d "$json_data"

target_file=$(mktemp /tmp/img2code_XXXXXX)

curl "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H 'Content-Type: application/json' \
  -X POST \
  -d "$json_data" \
  | jq -r '.candidates[0].content.parts[0].text' \
  > "$target_file"

printf "File saved in '%s'. Open? (y/n) " "$target_file"
read -r response

[ "$response" = 'y' ] && nvim -c "set ft=$language" "$target_file"
