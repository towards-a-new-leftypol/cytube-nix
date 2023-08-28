mkdir -p /tmp/cytube_google_subtitles
mkdir -p /tmp/cytube_cache
mkdir -p /tmp/cytube_chanlogs

CYTUBE_CONFIG_YAML_LOCATION=/home/phil/Documents/nix_derivations/cytube/config.yaml \
CYTUBE_SYSLOG_LOCATION=/tmp/cytube_sys.log \
CYTUBE_ERRLOG_LOCATION=/tmp/cytube_err.log \
CYTUBE_EVTLOG_LOCATION=/tmp/cytube_event.log \
CYTUBE_WEB_HTTPLOG_LOCATION=/tmp/cytube_http.log \
CYTUBE_WEB_CACHE_DIR=/tmp/cytube_cache/ \
CYTUBE_CHANLOGS_DIR=/tmp/cytube_chanlogs/ \
CYTUBE_FFMPEGLOG_LOCATION=/tmp/cytube_ffmpeg.log \
CYTUBE_GOOGLE_DRIVE_SUBTITLES_LOCATION=/tmp/cytube_google_subtitles/ \
node result/lib/node_modules/CyTube/index.js
