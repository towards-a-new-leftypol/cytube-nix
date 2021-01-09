{ config, pkgs, lib, system, ... }:

let
  cytubePkg = (import ./override.nix { inherit pkgs system; }).package;

  cfg = config.services.cytube;
  dirWithEverything = "/var/lib/cytube";

  # MariaDB [lainchan]> ALTER USER cytube@localhost IDENTIFIED BY "shinywaterturbojetpenis";
  cytubeConfig = ''
    mysql:
      server: "${cfg.database.server}"
      port: ${builtins.toString cfg.database.port}
      database: "${cfg.database.name}"
      user: "${cfg.database.user}"
      password: "${cfg.database.password}"
      pool-size: 2
    listen:
      - ip: ""
        port: ${builtins.toString cfg.httpPort}
        http: true
        io: true
    http:
      default-port: ${builtins.toString cfg.publicPort}
      root-domain: "${cfg.cookie-domain}"
      alt-domains:
        - "127.0.0.1"
      minify: false
      max-age: "7d"
      gzip: false
      gzip-threshold: 1024
      cookie-secret: "${cfg.cookie-secret}"
      index:
        max-entries: 50
      trust-proxies: [ "loopback" ]

    https:
      enabled: false

    html-template:
      title: "Sync"
      description: "Free, open source synchtube"

    io:
      domain: "http://${cfg.cookie-domain}:${builtins.toString cfg.publicPort}"
      default-port: ${builtins.toString cfg.publicPort}
      ip-connection-limit: ${builtins.toString cfg.concurrentUsers}

    youtube-v3-key: "${cfg.youtube-v3-key}"
    max-channels-per-user: 5
    max-accounts-per-ip: 5
    guest-login-delay: 60

    # Allows you to customize the path divider. The /r/ in http://localhost/r/yourchannel
    # Acceptable characters are a-z A-Z 0-9 _ and -
    channel-path: "r"
    # Allows you to blacklist certain channels.  Users will be automatically kicked
    # upon trying to join one.
    channel-blacklist: []
    # Minutes between saving channel state to disk
    channel-save-interval: 5

    # Configure periodic clearing of old alias data
    aliases:
      # Interval (in milliseconds) between subsequent runs of clearing
      purge-interval: 3600000
      # Maximum age of an alias (in milliseconds) - default 1 month
      max-age: 2592000000

    # Workaround for Vimeo blocking my domain
    vimeo-workaround: false

    # Regular expressions for defining reserved user and channel names and page titles
    # The list of regular expressions will be joined with an OR, and compared without
    # case sensitivity.
    #
    # Default: reserve any name containing "admin[istrator]" or "owner" as a word
    # but only if it is separated by a dash or underscore (e.g. dadmin is not reserved
    # but d-admin is)
    reserved-names:
      usernames:
        - "^(.*?[-_])?admin(istrator)?([-_].*)?$"
        - "^(.*?[-_])?owner([-_].*)?$"
      channels:
        - "^(.*?[-_])?admin(istrator)?([-_].*)?$"
        - "^(.*?[-_])?owner([-_].*)?$"
      pagetitles: []

    contacts: []

    playlist:
      max-items: 4000
      # How often (in seconds), mediaUpdate packets are broadcast to clients
      update-interval: 5

    # If set to true, when the ipThrottle and lastguestlogin rate limiters are cleared
    # periodically, the garbage collector will be invoked immediately.
    # The server must be invoked with node --expose-gc index.js for this to have any effect.
    aggressive-gc: false

    # If you have ffmpeg installed, you can query metadata from raw files, allowing
    # server-synched raw file playback.  This requires the following:
    #   * ffmpeg must be installed on the server
    ffmpeg:
      enabled: true
    # Executable name for ffprobe if it is not "ffprobe".  On Debian and Ubuntu (on which
    # libav is used rather than ffmpeg proper), this is "avprobe"
      ffprobe-exec: "ffprobe"

    link-domain-blacklist: []

    # Drop root if started as root!!
    setuid:
      enabled: false
      group: "${cfg.group}"
      user: "${cfg.user}"
    # how long to wait in ms before changing uid/gid
      timeout: 15

    # Allows for external services to access the system commandline
    # Useful for setups where stdin isn't available such as when using PM2
    service-socket:
      enabled: false
      socket: "service.sock"

    # Twitch Client ID for the data API (used for VOD lookups)
    # https://github.com/justintv/Twitch-API/blob/master/authentication.md#developer-setup
    twitch-client-id: null

    poll:
      max-options: 50
  '';

  configYamlFile = pkgs.writeText "config.yaml" (cytubeConfig);
in

with lib;
{
  options = {
    services.cytube = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = "Enable CyTube node application";
      };

      user = mkOption {
        type = types.str;
        default = "cytube";
        description = "User the cytube server will run as";
      };

      group = mkOption {
        type = types.str;
        default = "cytube";
        description = "Group the cytube server will run as";
      };

      httpPort = mkOption {
        type = types.int;
        default = 8080;
        description = "http serve port";
      };

      publicPort = mkOption {
        type = types.int;
        default = 80;
        description = "http port for generating links";
      };

      concurrentUsers = mkOption {
        type = types.int;
        default = 50;
        description = "Maximum allowed websocket connections";
      };

      youtube-v3-key = mkOption {
        type = types.str;
        default = "";
        description = "See https://github.com/calzoneman/sync/blob/3.0/config.template.yaml#L111";
      };

      cookie-secret = mkOption {
        type = types.str;
        description = "Secret for session cookies";
      };

      cookie-domain = mkOption {
        type = types.str;
        default = "localhost";
        description = "Root domain for cookies. eg. example.com";
      };

      database = {
        server = mkOption {
          type = types.str;
          default = "localhost";
          description = "hostname or ip address of the database";
        };

        port = mkOption {
          type = types.int;
          default = 3306;
          description = "database port";
        };

        name = mkOption {
          type = types.str;
          default = "cytube";
          description = "Name of the database to use.";
        };

        user = mkOption {
          type = types.str;
          default = "cytube";
          description = "User to connect to the database as.";
        };

        password = mkOption {
          type = types.str;
          description = "Password for the database user";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.nodejs
      cytubePkg
      pkgs.ffmpeg
    ];

    systemd.services.cytube = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        #CYTUBE_CONFIG_YAML_LOCATION = "${dirWithEverything}/config.yaml";
        #CYTUBE_CONFIG_YAML_LOCATION = "/etc/devops/nix-support-dev/cytube-nix/config.yaml";
        CYTUBE_CONFIG_YAML_LOCATION = "${configYamlFile}";
        CYTUBE_SYSLOG_LOCATION = "${dirWithEverything}/sys.log";
        CYTUBE_ERRLOG_LOCATION = "${dirWithEverything}/error.log";
        CYTUBE_EVTLOG_LOCATION = "${dirWithEverything}/events.log";
        CYTUBE_WEB_HTTPLOG_LOCATION = "${dirWithEverything}/http.log";
        CYTUBE_WEB_CACHE_DIR = "${dirWithEverything}/cache/";
        CYTUBE_CHANLOGS_DIR = "${dirWithEverything}/chanlogs/";
        CYTUBE_FFMPEGLOG_LOCATION = "${dirWithEverything}/ffmpeg.log";
        CYTUBE_GOOGLE_DRIVE_SUBTITLES_DIR = "${dirWithEverything}/google_subtitles/";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = dirWithEverything;
        #Restart = "on-failure";
        ExecStart = "${pkgs.nodejs}/bin/node ${cytubePkg}/lib/node_modules/CyTube/index.js";
        KillSignal = "SIGQUIT";
      };
    };

    systemd.tmpfiles.rules = [
      "d '${dirWithEverything}' 0750 ${cfg.user} ${cfg.group}"
      "d '${dirWithEverything}/cache' 0750 ${cfg.user} ${cfg.group}"
      "d '${dirWithEverything}/chanlogs' 0750 ${cfg.user} ${cfg.group}"
      "d '${dirWithEverything}/google_subtitles' 0750 ${cfg.user} ${cfg.group}"
    ];

    users.groups = {
      ${cfg.group} = {};
    };

    users.extraUsers.${cfg.user} = {
      group = cfg.group;
    };

  };
}
