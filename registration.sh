#/bin/sh

CMD=${1:-enable}

enable () {
  echo "Attempting to enable registration API on nmos-registry"

  curl http://nmos-registry.local/settings/all -X PATCH -H "Content-Type: application/json" -d "{\"registration_available\":true}"
  if [ $? -eq 0 ]; then
    echo -e "\nOK - Successfully enabled"
  else
    echo -e "\nFAIL - Is the nmos-registry running?"
  fi
}

disable () {
  echo "Attempting to disable registration API on nmos-registry"

  curl http://nmos-registry.local/settings/all -X PATCH -H "Content-Type: application/json" -d "{\"registration_available\":false}"
  if [ $? -eq 0 ]; then
    echo -e "\nOK - Successfully disabled"
  else
    echo -e "\nFAIL - Is the nmos-registry running?"
  fi
}

case $CMD in
  enable)
    enable
    ;;
  disable)
    disable
    ;;
  *)
    echo "registration.sh [enable|disable]"
    ;;
esac
