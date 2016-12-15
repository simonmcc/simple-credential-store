## Common Stuff - decrypt passwords into env vars

# gpg or gpg2 installed?  favour gpg2
GPG=$(which gpg2)
if [ -z "${GPG}" ]; then
  GPG=$(which gpg)
fi

# GPG or ASCII Armoured GPG?
if [ -f "${OPENRC}.secret.gpg" ]; then
  PWGPG="${OPENRC}.secret.gpg"
elif [ -f "${OPENRC}.secret.asc" ]; then
  PWGPG="${OPENRC}.secret.asc"
else
  echo "ERROR: Couldn\'t find encrypted password file for ${OPENRC}, should be ${OPENRC}.password.gpg or ${OPENRC}.password.asc"
  exit
fi

# if there isn't a gpg-agent running, launch one
if [ -z "${GPG_AGENT_INFO}" ]; then
  eval $(gpg-agent --daemon --sh)
  echo "Agent started: GPG_AGENT_INFO=${GPG_AGENT_INFO}"

  # Sign an empty file so that the gpg-agent has the key passphrase
  tempfoo=credentials-common
  SIGNFILE=`mktemp /tmp/${tempfoo}.XXXXXX` || exit 1
  ${GPG} --use-agent --encrypt -r simon@mccartney.ie $SIGNFILE
  rm $SIGNFILE
else
  echo "Existing gpg-agent found: GPG_AGENT_INFO=${GPG_AGENT_INFO}"
fi

# decrypt the password file to the OS_PASSWORD env var
export ${EXPORT_SECRET_AS}=$(${GPG} --batch --use-agent --logger-file /dev/null --decrypt -o - ${PWGPG})
