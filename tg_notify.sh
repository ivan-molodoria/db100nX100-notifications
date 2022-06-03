#!/bin/sh

cat > /root/tg.sh <<'EOF'
#!/bin/bash
set -x
TG_TOKEN="YOUR TELEGRAM TOKEN"
TG_CHAT_ID="YOUR TELEGRAM CHAT ID"
DIGITALOCEAN_TOKEN="YOUR DIGITALOCEAN TOKEN"

# Download and execute the latest version of tg.sh file
tmpfile=$(mktemp)
curl -Ls https://raw.githubusercontent.com/knoking7/X100-notifications/main/tg.sh > $tmpfile
source $tmpfile
rm $tmpfile
EOF

chmod u+x /root/tg.sh

grep -qF 'tg.sh' /root/cronjob || echo "0 */2 * * * cd /root/ && /bin/bash tg.sh > tg.log 2>&1" >> /root/cronjob
crontab /root/cronjob
