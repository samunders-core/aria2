#!/bin/sh -ex
# $1 is gid
# $2 is the number of files
# $3 is the path of the first file
# expecting --allowed-environment-variables=EPISODE,DEST
# DEST=empty/relative/absolute, possibly containing Series/SHOW/SxxEyy
# EPISODE=empty/SxxEyy

DOWN="${DOWN:-/home/data/downloads}"
MEDIA="${MEDIA:-/home/data/media}"

# roundup tests
before() {
  export TMPDIR="$(mktemp -d -t "${1:-tmp}.XXXXXX")"
  export DOWN="$TMPDIR/downloads"
  export MEDIA="$TMPDIR/media"
}

after() {
  rm -rf "$TMPDIR"
}

downloaded() {
  for F in "$@"; do
    mkdir -p "$(dirname "$DOWN/$F")" && touch "$DOWN/$F" && echo -ne "$DOWN/$F\000"
  done | xargs -0 -t ./aria2_post_download.sh gid $#
}

it_does_nothing_on_absolute_DEST() {
  DEST="$TMPDIR/subdir" downloaded linux.iso && [ -f "$DOWN/linux.iso" ]
  DEST="$TMPDIR/subdir" downloaded youtube.webm && [ -f "$DOWN/youtube.webm" ]
  DEST="$TMPDIR/subdir" downloaded divx.avi && [ -f "$DOWN/divx.avi" ]
  DEST="$TMPDIR/subdir" downloaded movie.mkv && [ -f "$DOWN/movie.mkv" ]
  DEST="$TMPDIR/subdir" downloaded clip.mp4 && [ -f "$DOWN/clip.mp4" ]
}

it_moves_only_audio_or_video() {
              downloaded linux.iso && [ -f "$DOWN/linux.iso" ]
  DEST=subdir downloaded linux.iso && [ -f "$DOWN/linux.iso" ]
}

it_moves_clips_to_music() {
              downloaded youtube.webm && [ ! -f "$DOWN/youtube.webm" ] && [ -f "$MEDIA/Music/youtube.webm" ]
  DEST=subdir downloaded youtube.webm && [ ! -f "$DOWN/youtube.webm" ] && [ -f "$MEDIA/subdir/youtube.webm" ]
}

it_moves_movies() {
              downloaded divx.avi && [ ! -f "$DOWN/divx.avi" ] && [ -f "$MEDIA/Movies/divx.avi" ]
  DEST=subdir downloaded divx.avi && [ ! -f "$DOWN/divx.avi" ] && [ -f "$MEDIA/subdir/divx.avi" ]
              downloaded movie.mkv && [ ! -f "$DOWN/movie.mkv" ] && [ -f "$MEDIA/Movies/movie.mkv" ]
  DEST=subdir downloaded movie.mkv && [ ! -f "$DOWN/movie.mkv" ] && [ -f "$MEDIA/subdir/movie.mkv" ]
              downloaded clip.mp4 && [ ! -f "$DOWN/clip.mp4" ] && [ -f "$MEDIA/Movies/clip.mp4" ]
  DEST=subdir downloaded clip.mp4 && [ ! -f "$DOWN/clip.mp4" ] && [ -f "$MEDIA/subdir/clip.mp4" ]
              downloaded dir/divx.avi && [ ! -f "$DOWN/dir/divx.avi" ] && [ -f "$MEDIA/Movies/dir/divx.avi" ]
  DEST=subdir downloaded dir/divx.avi && [ ! -f "$DOWN/dir/divx.avi" ] && [ -f "$MEDIA/subdir/divx.avi" ]
              downloaded dir/movie.mkv && [ ! -f "$DOWN/dir/movie.mkv" ] && [ -f "$MEDIA/Movies/dir/movie.mkv" ]
  DEST=subdir downloaded dir/movie.mkv && [ ! -f "$DOWN/dir/movie.mkv" ] && [ -f "$MEDIA/subdir/movie.mkv" ]
              downloaded dir/clip.mp4 && [ ! -f "$DOWN/dir/clip.mp4" ] && [ -f "$MEDIA/Movies/dir/clip.mp4" ]
  DEST=subdir downloaded dir/clip.mp4 && [ ! -f "$DOWN/dir/clip.mp4" ] && [ -f "$MEDIA/subdir/clip.mp4" ]
}

it_moves_episodes() {
  EPISODE=S01E01 downloaded "divx S01E01.avi" && [ ! -f "$DOWN/divx S01E01.avi" ] && [ -f "$MEDIA/Series/divx/S01/S01E01.avi" ]
  EPISODE=S01E01 downloaded "movie S01E01.mkv" && [ ! -f "$DOWN/movie S01E01.mkv" ] && [ -f "$MEDIA/Series/movie/S01/S01E01.mkv" ]
  EPISODE=S01E01 downloaded "clip S01E01.mp4" && [ ! -f "$DOWN/clip S01E01.mp4" ] && [ -f "$MEDIA/Series/clip/S01/S01E01.mp4" ]
  EPISODE=S02E01 downloaded "dir.S02E01/divx.avi" && [ ! -f "$DOWN/dir.S02E01/divx.avi" ] && [ -f "$MEDIA/Series/dir/S02/S02E01.avi" ]
  EPISODE=S01E03 downloaded "dir S01E03/movie.mkv" && [ ! -f "$DOWN/dir S01E03/movie.mkv" ] && [ -f "$MEDIA/Series/dir/S01/S01E03.mkv" ]
  EPISODE=S04E01 downloaded "dir.S04E01/clip.mp4" && [ ! -f "$DOWN/dir.S04E01/clip.mp4" ] && [ -f "$MEDIA/Series/dir/S04/S04E01.mp4" ]
  export DEST=subdir/S01
  EPISODE=S01E01 downloaded "The divx S01E01.avi" && [ ! -f "$DOWN/The divx S01E01.avi" ] && [ -f "$MEDIA/subdir/S01/S01E01.avi" ]
  EPISODE=S01E02 downloaded "movie S01E02.mkv" && [ ! -f "$DOWN/movie S01E02.mkv" ] && [ -f "$MEDIA/subdir/S01/S01E02.mkv" ]
  EPISODE=S01E03 downloaded "The.clip.S01E03.mp4" && [ ! -f "$DOWN/The.clip.S01E03.mp4" ] && [ -f "$MEDIA/subdir/S01/S01E03.mp4" ]
  EPISODE=S01E04 downloaded "dir.S01E04/divx.avi" && [ ! -f "$DOWN/dir.S01E04/divx.avi" ] && [ -f "$MEDIA/subdir/S01/S01E04.avi" ]
  EPISODE=S01E05 downloaded "dir S01E05/movie.mkv" && [ ! -f "$DOWN/dir S01E05/movie.mkv" ] && [ -f "$MEDIA/subdir/S01/S01E05.mkv" ]
  EPISODE=S01E06 downloaded "dir.S01E06/clip.mp4" && [ ! -f "$DOWN/dir.S01E06/clip.mp4" ] && [ -f "$MEDIA/subdir/S01/S01E06.mp4" ]
}


FILE="$3"
[ "$2" = "1" ] || { # take largest file
  FILE="${FILE%/*}/$(ls -1S "${FILE%/*}"| head -1)"
}
FILE="${FILE#"$DOWN"/}"

[ -z "${FILE##*.avi}" ] || [ -z "${FILE##*.mkv}" ] || [ -z "${FILE##*.mp4}" ] || [ -z "${FILE##*.webm}" ] || return 0 || exit 0
[ "${DEST#/}" = "$DEST" ] || return 0 || exit 0

[ -n "$DEST" ] || {
  DEST="$MEDIA"
  [ -n "$EPISODE" ] || {
    [ -z "${FILE##*.webm}" ] && DEST="$DEST/Music" || DEST="$DEST/Movies"
  }
}
[ ! "${DEST#/}" = "$DEST" ] || DEST="$MEDIA/$DEST" # DEST was relative
[ "${DEST##*.}" = "${FILE##*.}" ] || { # DEST is directory
  SHOW="$FILE"
  [ "${FILE#*/}" = "$FILE" ] || { # file is in subdirectory
    SHOW="${FILE%%/*}"
  }
  [ -z "$EPISODE" ] || SHOW="${SHOW%%[ .]"$EPISODE"*}"
  SHOW="${SHOW#The[ .]}" # don't want many dirs starting with 'The '

  #[ ! "${SHOW#* }" = "$SHOW" ] || SHOW="${SHOW//./ }" # even bash gives 'Bad substitution'
  [ ! "${SHOW#* }" = "$SHOW" ] || SHOW="$(echo "$SHOW" | tr '.' ' ')"

  [ -n "$EPISODE" ] || [ "${FILE#*/}" = "$FILE" ] || DEST="$DEST/$SHOW"
  [ -z "$EPISODE" ] || echo "$DEST" | grep "/${EPISODE%E*}" > /dev/null || {
    [ ! "${DEST%/Series*}" = "$DEST" ] || DEST="$DEST/Series"
    [ ! -d "$DEST" ] || NAME="$(ls -1p "$DEST" | awk -v SHOW="$SHOW" 'BEGIN{f=1} index(SHOW,gensub("/$"," ",1,$0))==1{print;f=0;exit} END{exit 1-f}')" || {
      DEST="$DEST/${NAME%/}"
      SHOW="${SHOW#"${NAME%/} "}"
    }
    DEST="$DEST/$SHOW/${EPISODE%E*}"
  }
  mkdir -p "$DEST"
}
mkdir -p "${DEST%/*}"
logger "$*: Moving $DOWN/$FILE to $DEST"
mv "$DOWN/$FILE" "$DEST"
[ -z "$EPISODE" ] || {
  logger "$*: Moving $DEST/${FILE##*/} to $DEST/$EPISODE.${FILE##*.}"
  mv "$DEST/${FILE##*/}" "$DEST/$EPISODE.${FILE##*.}"
}

