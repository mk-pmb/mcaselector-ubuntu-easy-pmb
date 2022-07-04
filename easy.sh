#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function mse_cli_main () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?

  local JAVA_CMD="${CUSTOM_JAVA_LAUNCHER:-java}"
  export JAVA_CMD
  local -A MEM=()
  mce_detect_java_version || return $?
  local -A CFG=(
    [java:fx:dir]="javafx-sdk-${MEM[java:ver:major]}"
    )

  local RUNMODE="${1:-run}"; shift
  case "$RUNMODE" in
    download | \
    run )
      mse_cmd_"${RUNMODE//-/_}" "$@"
      return $?;;
  esac

  local -fp "${FUNCNAME[0]}" | guess_bash_script_config_opts-pmb \
    --optvar=RUNMODE --avail=runmodes --dashes=
  [ "${RUNMODE//-/}" == help ] && return 0
  echo "E: $0, CLI: unsupported runmode: $RUNMODE" >&2
  return 4
}


function mce_detect_java_version () {
  local VER="$OVERRIDE_JAVA_MAJOR_VERSION"
  if [ -z "$VER" ]; then
    local SED='1s~^openjdk version "([0-9]+)\..*$~major=\1~'
    VER="$(sh -c '"$JAVA_CMD" -version 2>&1' | sed -re "$SED")"
    # ^-- Delegation to sh is used to get a uniform error message for missing
    #     executable that does not include likely-to-change trace info.
    case "$VER" in
      'sh: 1: '*': not found' | \
      __not_installed__ )
        echo "E: Found no '$JAVA_CMD' command. Is Java installed at all?" >&2
        return 5;;
      major=[0-9]* )
        VER="${VER%%$'\n'*}"
        VER="${VER#*=}"
        ;;
      * )
        echo "E: Failed to detect Java version." \
          "Response from $JAVA_CMD was: '$VER'" >&2
        return 8;;
    esac
  fi
  [ "${VER:-0}" -ge 1 ] || return 4$(
    echo "E: Internal control flow failure in $FUNCNAME" >&2)
  MEM[java:ver:major]="$VER"
  echo "D: Found Java major version: $VER" >&2
}


function mse_cmd_download () {
  mse_dl_jfx || return $?
  mse_dl_sel || return $?
  echo "D: All done. We should be ready to run."
}


function mse_dl_wget () {
  local DESCR="$1"; shift
  [ -n "$DESCR" ] || return 8$(echo "E: $FUNCNAME: No description given!" >&2)
  local SAVE="$1"; shift
  [ -n "$SAVE" ] || return 8$(echo "E: $FUNCNAME: No destination given!" >&2)
  local URL="$1"; shift
  [ -n "$URL" ] || return 8$(echo "E: $FUNCNAME: No source URL given!" >&2)

  if [ -s "$SAVE" ]; then
    echo -n 'D: File seems to be downloaded already: '
    du --human-readable --summarize -- "$SAVE"
    echo "D: No dowload required for $DESCR." \
      "The Download-URL would have been: $URL"
    return 0
  fi

  echo "D: Gonna download $DESCR: $SAVE <- $URL"
  local WGET=(
    wget
    --continue
    --output-document="$SAVE".part
    )

  case "$URL" in
    accept-bad-cert:* )
      URL="${URL#*:}"
      WGET+=( --no-check-certificate )
      ;;
  esac

  WGET+=( -- "$URL" )
  echo
  "${WGET[@]}" || return $?$(echo "E: wget failed, rv=$?" >&2)
  mv --verbose --no-target-directory -- "$SAVE"{.part,} || return $?
}


function mse_dl_jfx () {
  local JFX_DIR="${CFG[java:fx:dir]}"
  local VER="${MEM[java:ver:major]}"
  local REMOTE_DL_DIR="javafx-${VER}-ea-sdk-linux"
  local ZIP_DEST="$REMOTE_DL_DIR.zip"

  mse_dl_jfx_all_known_mirrors || return $?

  echo "D: Gonna unpack: $ZIP_DEST" >&2
  unzip -qo "$ZIP_DEST" "$JFX_DIR"/lib/'*' || return $?
  echo -n 'D: JavaFX has been installed: '
  du --human-readable --summarize -- "$JFX_DIR"
}


function mse_dl_jfx_all_known_mirrors () {
  local W='JavaFX'
  local U="https://gluonhq.com/download/$REMOTE_DL_DIR/"
  local URL="accept-bad-cert:$U.zip"
  # ^-- 2022-06-26: Their Let's Encrypt certificate has expired.
  mse_dl_wget "$W (official download servers)" "$ZIP_DEST" "$URL" && return 0

  echo "W: Download from official servers failed." \
    "Trying inofficial mirrors." >&2

  local D=
  [ "$VER" -le 17 ] && D=20210101
  URL="https://web.archive.org/web/${D:-99}/$U"
  mse_dl_wget "$W (via archive.org)" "$ZIP_DEST" "$URL" && return 0

  echo "E: Downloads failed from all known mirrors." >&2
  return 8
}


function mse_dl_sel () {
  local BFN='mcaselector'
  local VER='2.0.1'
  echo "W: Download $BFN: Unable to check whether a newer version than" \
    "$VER is available: Not implemented yet." >&2
  local JAR="$BFN-$VER.jar"
  local URL="https://github.com/Querz/$BFN/releases/download/$VER/$JAR"
  mse_dl_wget "$BFN" "$JAR" "$URL" || return $?
}


function mse_cmd_run () {
  local BFN='mcaselector'
  local SEL="$(ls --format=single-column -- "$BFN"-[0-9]*.jar \
    | sort --version-sort | tail --lines=1)"
  [ -f "$SEL" ] || return 4$(
    echo "E: Cannot find any version of $BFN. Try run: ./easy.sh download" >&2)
  echo "D: Using $SEL"

  local JFX="${CFG[java:fx:dir]}/lib"
  [ -d "$JFX" ] || return 5$(
    echo "E: Not a directory: '$JFX'. Try run: ./easy.sh download" >&2)

  local RUN=(
    "$JAVA_CMD"
    --module-path "$JFX"
    --add-modules ALL-MODULE-PATH
    -jar "$SEL"
    )
  echo "D: Running in directory: '$PWD'"
  echo "D: Effective command to be run: '${RUN[*]}'"
  "${RUN[@]}" || return $?$(echo "E: Java failed with rv=$?" >&2)
}










mse_cli_main "$@"; exit $?
