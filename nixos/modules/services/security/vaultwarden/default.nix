{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.vaultwarden;
  user = config.users.users.vaultwarden.name;
  group = config.users.groups.vaultwarden.name;

  StateDirectory =
    if lib.versionOlder config.system.stateVersion "24.11" then "bitwarden_rs" else "vaultwarden";

  dataDir = "/var/lib/${StateDirectory}";

  # Convert name from camel case (e.g. disable2FARemember) to upper case snake case (e.g. DISABLE_2FA_REMEMBER).
  nameToEnvVar =
    name:
    let
      parts = builtins.split "([A-Z0-9]+)" name;
      partsToEnvVar =
        parts:
        lib.foldl' (
          key: x:
          let
            last = lib.stringLength key - 1;
          in
          if lib.isList x then
            key + lib.optionalString (key != "" && lib.substring last 1 key != "_") "_" + lib.head x
          else if key != "" && lib.elem (lib.substring 0 1 x) lib.lowerChars then # to handle e.g. [ "disable" [ "2FAR" ] "emember" ]
            lib.substring 0 last key
            + lib.optionalString (lib.substring (last - 1) 1 key != "_") "_"
            + lib.substring last 1 key
            + lib.toUpper x
          else
            key + lib.toUpper x
        ) "" parts;
    in
    if builtins.match "[A-Z0-9_]+" name != null then name else partsToEnvVar parts;

  # Due to the different naming schemes allowed for config keys,
  # we can only check for values consistently after converting them to their corresponding environment variable name.
  configEnv =
    let
      configEnv = lib.concatMapAttrs (
        name: value:
        lib.optionalAttrs (value != null) {
          ${nameToEnvVar name} = if lib.isBool value then lib.boolToString value else toString value;
        }
      ) cfg.config;
    in
    {
      DATA_FOLDER = dataDir;
    }
    // lib.optionalAttrs (!(configEnv ? WEB_VAULT_ENABLED) || configEnv.WEB_VAULT_ENABLED == "true") {
      WEB_VAULT_FOLDER = "${cfg.webVaultPackage}/share/vaultwarden/vault";
    }
    // configEnv;

  configFile = pkgs.writeText "vaultwarden.env" (
    lib.concatStrings (lib.mapAttrsToList (name: value: "${name}=${value}\n") configEnv)
  );

  vaultwarden = cfg.package.override { inherit (cfg) dbBackend; };

  useSendmail = configEnv.USE_SENDMAIL or null == "true";
in
{
  imports = [
    (lib.mkRenamedOptionModule [ "services" "bitwarden_rs" ] [ "services" "vaultwarden" ])
  ];

  options.services.vaultwarden = {
    enable = lib.mkEnableOption "vaultwarden";

    dbBackend = lib.mkOption {
      type = lib.types.enum [
        "sqlite"
        "mysql"
        "postgresql"
      ];
      default = "sqlite";
      description = ''
        Which database backend vaultwarden will be using.
      '';
    };

    backupDir = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        The directory under which vaultwarden will backup its persistent data.
      '';
      example = "/var/backup/vaultwarden";
    };

    config = lib.mkOption {
      type =
        with lib.types;
        attrsOf (
          nullOr (oneOf [
            bool
            int
            str
          ])
        );
      default = {
        ROCKET_ADDRESS = "::1"; # default to localhost
        ROCKET_PORT = 8222;
      };
      example = lib.literalExpression ''
        {
          DOMAIN = "https://bitwarden.example.com";
          SIGNUPS_ALLOWED = false;

          # Vaultwarden currently recommends running behind a reverse proxy
          # (nginx or similar) for TLS termination, see
          # https://github.com/dani-garcia/vaultwarden/wiki/Hardening-Guide#reverse-proxying
          # > you should avoid enabling HTTPS via vaultwarden's built-in Rocket TLS support,
          # > especially if your instance is publicly accessible.
          #
          # A suitable NixOS nginx reverse proxy example config might be:
          #
          #     services.nginx.virtualHosts."bitwarden.example.com" = {
          #       enableACME = true;
          #       forceSSL = true;
          #       locations."/" = {
          #         proxyPass = "http://127.0.0.1:''${toString config.services.vaultwarden.config.ROCKET_PORT}";
          #       };
          #     };
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;

          ROCKET_LOG = "critical";

          # This example assumes a mailserver running on localhost,
          # thus without transport encryption.
          # If you use an external mail server, follow:
          #   https://github.com/dani-garcia/vaultwarden/wiki/SMTP-configuration
          SMTP_HOST = "127.0.0.1";
          SMTP_PORT = 25;
          SMTP_SSL = false;

          SMTP_FROM = "admin@bitwarden.example.com";
          SMTP_FROM_NAME = "example.com Bitwarden server";
        }
      '';
      description = ''
        The configuration of vaultwarden is done through environment variables,
        therefore it is recommended to use upper snake case (e.g. {env}`DISABLE_2FA_REMEMBER`).

        However, camel case (e.g. `disable2FARemember`) is also supported:
        The NixOS module will convert it automatically to
        upper case snake case (e.g. {env}`DISABLE_2FA_REMEMBER`).
        In this conversion digits (0-9) are handled just like upper case characters,
        so `foo2` would be converted to {env}`FOO_2`.
        Names already in this format remain unchanged, so `FOO2` remains `FOO2` if passed as such,
        even though `foo2` would have been converted to {env}`FOO_2`.
        This allows working around any potential future conflicting naming conventions.

        Based on the attributes passed to this config option an environment file will be generated
        that is passed to vaultwarden's systemd service.

        The available configuration options can be found in
        [the environment template file](https://github.com/dani-garcia/vaultwarden/blob/${vaultwarden.version}/.env.template).

        See [](#opt-services.vaultwarden.environmentFile) for how
        to set up access to the Admin UI to invite initial users.
      '';
    };

    environmentFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      example = "/var/lib/vaultwarden.env";
      description = ''
        Additional environment file as defined in {manpage}`systemd.exec(5)`.

        Secrets like {env}`ADMIN_TOKEN` and {env}`SMTP_PASSWORD`
        should be passed to the service without adding them to the world-readable Nix store.

        Note that this file needs to be available on the host on which `vaultwarden` is running.

        As a concrete example, to make the Admin UI available (from which new users can be invited initially),
        the secret {env}`ADMIN_TOKEN` needs to be defined as described
        [here](https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page):

        ```
        # Admin secret token, see
        # https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page
        ADMIN_TOKEN=...copy-paste a unique generated secret token here...
        ```
      '';
    };

    package = lib.mkPackageOption pkgs "vaultwarden" { };

    webVaultPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vaultwarden.webvault;
      defaultText = lib.literalExpression "pkgs.vaultwarden.webvault";
      description = "Web vault package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.backupDir != null -> cfg.dbBackend == "sqlite";
        message = "Backups for database backends other than sqlite will need customization";
      }
      {
        assertion = cfg.backupDir != null -> !(lib.hasPrefix dataDir cfg.backupDir);
        message = "Backup directory can not be in ${dataDir}";
      }
    ];

    users.users.vaultwarden = {
      inherit group;
      isSystemUser = true;
    };
    users.groups.vaultwarden = { };

    systemd.services.vaultwarden = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = with pkgs; [ openssl ];
      serviceConfig = {
        User = user;
        Group = group;
        EnvironmentFile = [ configFile ] ++ lib.optional (cfg.environmentFile != null) cfg.environmentFile;
        ExecStart = lib.getExe vaultwarden;
        LimitNOFILE = "1048576";
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = !useSendmail;
        PrivateDevices = !useSendmail;
        PrivateTmp = true;
        PrivateUsers = !useSendmail;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "noaccess";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        inherit StateDirectory;
        StateDirectoryMode = "0700";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
        ]
        ++ lib.optionals (!useSendmail) [
          "~@privileged"
        ];
        Restart = "always";
        UMask = "0077";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.backup-vaultwarden = lib.mkIf (cfg.backupDir != null) {
      description = "Backup vaultwarden";
      environment = {
        DATA_FOLDER = dataDir;
        BACKUP_FOLDER = cfg.backupDir;
      };
      path = with pkgs; [ sqlite ];
      # if both services are started at the same time, vaultwarden fails with "database is locked"
      before = [ "vaultwarden.service" ];
      serviceConfig = {
        SyslogIdentifier = "backup-vaultwarden";
        Type = "oneshot";
        User = lib.mkDefault user;
        Group = lib.mkDefault group;
        ExecStart = "${pkgs.bash}/bin/bash ${./backup.sh}";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.timers.backup-vaultwarden = lib.mkIf (cfg.backupDir != null) {
      description = "Backup vaultwarden on time";
      timerConfig = {
        OnCalendar = lib.mkDefault "23:00";
        Persistent = "true";
        Unit = "backup-vaultwarden.service";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.tmpfiles.settings = lib.mkIf (cfg.backupDir != null) {
      "10-vaultwarden".${cfg.backupDir}.d = {
        inherit user group;
        mode = "0770";
      };
    };
  };

  meta = {
    # uses attributes of the linked package
    buildDocsInSandbox = false;
    maintainers = with lib.maintainers; [
      dotlambda
      SuperSandro2000
    ];
  };
}
