#!/bin/bash

# Target directory for SSH keys
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"

# Get public keys from Bitwarden SSH agent
keys=$(ssh-add -L)

if [ -z "$keys" ] || [[ "$keys" == "The agent has no identities." ]]; then
    echo "Error: No keys found in ssh-agent."
    echo "Make sure the Bitwarden SSH Agent is active and unlocked."
    exit 1
fi

counter=1
echo "Exporting public keys from SSH Agent..."
echo "--------------------------------------------------------"

# Read line by line
while read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    
    # Format of ssh-add -L is: [type] [key-data] [comment]
    # Extract the comment (which can contain spaces)
    comment=$(echo "$line" | cut -d' ' -f3-)
    
    # Sanitize the comment for a safe filename
    if [ -n "$comment" ]; then
        # Replace spaces with underscores and remove non-alphanumeric characters
        filename=$(echo "$comment" | tr ' ' '_' | tr -cd 'a-zA-Z0-9._-')
        # Use fallback if sanitization leaves name empty
        [ -z "$filename" ] && filename="bitwarden_key_$counter"
    else
        filename="bitwarden_key_$counter"
    fi
    
    pub_file="$SSH_DIR/$filename.pub"
    
    # Save the key to the .pub file
    echo "$line" > "$pub_file"
    chmod 600 "$pub_file"
    
    echo "Generated: ~/.ssh/$filename.pub"
    echo "   Comment:  $comment"
    echo "   SSH config directives:"
    echo "     IdentityFile ~/.ssh/$filename.pub"
    echo "     IdentitiesOnly yes"
    echo "--------------------------------------------------------"
    
    counter=$((counter + 1))
done <<< "$keys"

echo "Done! All public keys have been saved to $SSH_DIR."
