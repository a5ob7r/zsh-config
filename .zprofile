if [ "${TERM}" = "linux" ]; then
  # Oceanic Next
  /bin/echo -e "
  \e]P0121c21
  \e]P1e44754
  \e]P289bd82
  \e]P3f7bd51
  \e]P45486c0
  \e]P5b77eb8
  \e]P650a5a4
  \e]P7ffffff
  \e]P852606b
  \e]P9e44754
  \e]PA89bd82
  \e]PBf7bd51
  \e]PC5486c0
  \e]PDb77eb8
  \e]PE50a5a4
  \e]PFffffff
  "
  # get rid of artifacts
  clear
fi

if [[ -f ~/.zprofile.local ]]; then
  source ~/.zprofile.local
fi
