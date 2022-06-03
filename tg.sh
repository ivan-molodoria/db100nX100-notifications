#/bin/bash
set -x

LOGS_FILE='/root/db1000nX100-for-docker/put-your-ovpn-files-here/db1000nX100-log.txt'
TOTAL=$( grep -r 'Session network traffic' ${LOGS_FILE} | tail -n 1 | awk '{ print $4 }')
RESPONSES=$(grep -r 'Session network traffic' ${LOGS_FILE} | tail -n 1 | awk '{ print $5 }')
UPTIME=$(grep -r -o ". hours .* minutes"  ${LOGS_FILE} | tail -n 1)
LOCATIONS=$(grep -r GeoIP -A 8 ${LOGS_FILE} | tail -n 5 | awk -F' {2,}' 'BEGIN { OFS = "/" }{ print $2, $3 }')

# Get billing info only if DO variable set
if [ ! -z "$DIGITALOCEAN_TOKEN" ]; then
    BAL_RESPONSE=$(curl -s -X GET \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
      "https://api.digitalocean.com/v2/customers/my/balance")
    BAL_BAL=$(echo $BAL_RESPONSE | jq '.month_to_date_balance' | bc)
    BAL_USG=$(echo $BAL_RESPONSE | jq '.month_to_date_usage' | bc)
fi

# Get status of Docker container
docker ps | grep db1000nx100-container &> /dev/null
if [ $? == 0 ]; then
    STATUS=Running
else
    STATUS=Stopped
fi

# Static link to targets health checks
HEALTH_URL="https://itarmy.com.ua/check/"

message="*Host*: \`$(hostname)\`"
message+="%0A"
if [ ! -z "$DIGITALOCEAN_TOKEN" ]; then
    message+="*Balance/To pay*: \`$BAL_BAL\`/\`$BAL_USG\`"
    message+="%0A"
fi
message+="*Container status*: \`$STATUS\`"
message+="%0A"
if [ $STATUS == Running ]; then
    message+="*Uptime*: \`$UPTIME\`"
    message+="%0A"
    message+="*Traffic*: \`$TOTAL\`"
    message+="%0A"
    message+="\`$RESPONSES\`"
    message+="%0A"
    message+="*Country*/*VPN_provider*:"
    message+="%0A"
    message+="\`$LOCATIONS\`"
fi

keyboard="{\"inline_keyboard\":[[{\"text\":\"Open health report\", \"url\":\"${HEALTH_URL}\"}]]}"

curl -s --data "text=${message}" \
        --data "reply_markup=${keyboard}" \
        --data "chat_id=$TG_CHAT_ID" \
        --data "parse_mode=markdown" \
        "https://api.telegram.org/bot${TG_TOKEN}/sendMessage"
