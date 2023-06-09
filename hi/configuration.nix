{ self, config, pkgs, ... }@sysargs: {
  system.stateVersion = "22.11";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  nixpkgs.config.allowUnfree = true;

  boot = {
    tmpOnTmpfs = true;

    kernelPackages = pkgs.linuxPackages_rpi4;
    initrd.checkJournalingFS = false;
    initrd.kernelModules = [ "xhci_pci" "usbhid" "uas" "usb_storage" ];
    kernelModules = [
      "i2c-dev"
    ];
    kernelParams = [
      "8250.nr_uarts=1"
      "console=tty1"
      "cma=128M"
      "vt.default_red=0x28,0xcc,0x98,0xd7,0x45,0xb1,0x68,0xa8,0x92,0xfb,0xb8,0xfa,0x83,0xd3,0x8e,0xeb"
      "vt.default_grn=0x28,0x24,0x97,0x99,0x85,0x62,0x9d,0x99,0x83,0x49,0xbb,0xbd,0xa5,0x86,0xc0,0xdb"
      "vt.default_blu=0x28,0x1d,0x1a,0x21,0x88,0x86,0x6a,0x84,0x74,0x34,0x26,0x2f,0x98,0x9b,0x7c,0xb2"
    ];

    loader.raspberryPi = {
      enable = true;
      version = 4;
      firmwareConfig = ''
        disable_overscan=1
        dtparam=sd_poll_once=on
        dtparam=audio=on
        dtparam=i2c1=on
      '';
    };
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = false;
  };

  hardware.enableRedistributableFirmware = true;
  hardware.raspberry-pi."4".fkms-3d.enable = true;

  zramSwap.enable = true;

  networking = {
    hostName = "kyoku-chan";
    useNetworkd = true;
    firewall.enable = false;
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de-latin1";
  };

  fonts = {
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override {
        fonts = [ "Iosevka" ];
      })
    ];

    fontconfig.defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [ "IosevkaNerdFont" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };

  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "Adwaita-Dark";
    PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig/";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_DESKTOP = "sway";
  };
  environment.systemPackages = with pkgs; [
    libsodium.dev
  ];

  programs = {
    sway.enable = true;
    command-not-found.enable = false;
    nix-ld.enable = true;
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    greetd = {
      enable = true;
      restart = true;
      vt = 7;
      settings = {
        default_session = {
          # command = "${pkgs.greetd.tuigreet}/bin/tuigreet -trc sway --remember-user-session";
          command = "sway";
          user = "ercanar";
        };
      };
    };

    udev.extraRules = ''
      SUBSYSTEM=="i2c-dev", KERNEL=="i2c-1", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown ercanar /dev/i2c-1'"
    '';
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  systemd.extraConfig = "DefaultTimeoutStopSec=10s";
  systemd.network.wait-online.enable = false;
  systemd.mounts = [{
    what = "dotfiles";
    where = "/etc/nixos";

    after = [ "home.mount" ];
    wantedBy = [ "local-fs.target" ];

    type = "overlay";
    options = let
      dots = "${config.users.users.ercanar.home}/dotfiles";
    in "lowerdir=${dots}/lo,upperdir=${dots}/hi,workdir=${dots}/work";
  }];
  systemd.tmpfiles.rules = [
    "d /var/cache/tuigreet 0755 greeter greeter"
  ];

  users.mutableUsers = false;
  users.users.ercanar = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    hashedPassword = "$y$j9T$zjEgVmMSgM4dbXcVwITTT.$hLUP9jj1sE.hCf0DIAb8Nzlu40HiIwhYVkKmSWUgKv5";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVieLCkWGImVI9c7D0Z0qRxBAKf0eaQWUfMn0uyM/Ql" ];
  };

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.ercanar = { config, lib, pkgs, ... }: {
    home = let mybin = "${config.home.homeDirectory}/bin"; in {
      stateVersion = "22.11";

      shellAliases = {
        cd = "mycd";
        fuck = "sudo $(history -p !!)";
        g = "git";
        ip = "ip -c";
        mkdir = "mkdir -pv";
        neofetch = "hyfetch";
        rl = "exec \\$SHELL -l";
        switch = "sudo mount -o remount /etc/nixos && sudo nixos-rebuild switch";
        yay = "cd ${config.home.homeDirectory}/dotfiles/hi && nix flake update && switch";
        vi = "vi -p";
        vim = "vim -p";
      };

      packages = with pkgs; [
        adwaita-qt
        feh
        file
        fuzzel
        gcc
        gocryptfs
        grim
        jq
        libnotify
        lsof
        mpv
        nil
        nixpkgs-fmt
        pciutils
        pkg-config
        wl-clipboard
        xdg_utils
      ];

      sessionPath = [ mybin ];

      file = {
        "Desktop".text = "";

        "${mybin}/audio-helper" = {
          executable = true;
          source = ./audio-helper.sh;
        };

        "${mybin}/brightness-helper" = {
          executable = true;
          source = ./brightness-helper.sh;
        };

        "${mybin}/dropdown" = {
          executable = true;
          source = ./dropdown.sh;
        };

        "${mybin}/new-pane-here" = {
          executable = true;
          source = ./new-pane-here.sh;
        };

        "${mybin}/prompt" = {
          executable = true;
          source = ./prompt.sh;
        };

        "${mybin}/terminal" = {
          executable = true;
          source = ./terminal.sh;
        };
      };
    };

    xdg = {
      enable = true;
      userDirs.enable = true;

      configFile."fuzzel/fuzzel.ini".source = ./fuzzel.ini;
      dataFile."dbus-1/services/mako-path-fix.service".text = ''
        [D-BUS Service]
        Name=org.freedesktop.Notifications
        Exec=/usr/bin/env PATH=/run/current-system/sw/bin ${pkgs.mako}/bin/mako
      '';
    };

    systemd.user.services = let
      Environment = let
        system = sysargs.config.system.path;
        user   = config.home.path;
      in "PATH=${system}/bin:${system}/sbin:${user}/bin:${user}/sbin";
    in {
      emo = {
        Install.WantedBy = [ "default.target" ];
        Service = {
          inherit Environment;
          WorkingDirectory = "/home/ercanar/emo/program";
          ExecStart = ''
            ${pkgs.nix}/bin/nix run "github:thiagokokada/nix-alien#nix-alien" -- \
            -l libsqlite3.so ./emo2 0 37812 ident
          '';
        };
      };

      kvm-switcher = {
        Install.WantedBy = [ "default.target" ];
        Service = {
          inherit Environment;
          ExecStart = "/home/ercanar/dev/kvm-switcher/kvm-switcher.sh";
        };
      };
    };

    services = {
      mako = {
        enable = true;
        defaultTimeout = 5000;
      };

      gpg-agent = {
        enable = true;
        pinentryFlavor = "qt";
      };

      flameshot.enable = true;

      swayidle = {
        enable = true;
        events = [
          { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
          { event = "before-sleep"; command = "${pkgs.systemd}/bin/loginctl lock-session"; }
        ];
        timeouts = [
          { timeout = 300; command = "${pkgs.systemd}/bin/loginctl lock-session"; }
          {
            timeout = 300;
            command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'";
            resumeCommand = "${pkgs.sway}/bin/swaymsg 'output * dpms on'";
          }
        ];
      };
    };

    programs = {
      firefox.enable = true;

      bash = {
        enable = true;
        enableCompletion = true;
        historyControl = [ "ignoredups" "ignorespace" ];
        shellOptions = [ "autocd" ];
        initExtra = builtins.replaceStrings
          [ "@{pkgs.complete-alias}" ]
          [ "${pkgs.complete-alias}" ]
          (builtins.readFile ./bashrc);
      };

      starship = {
        enable = true;
        settings = {
          character = {
            success_symbol = "[λ](bold green)";
            error_symbol = "[λ](bold red)";
          };
        };
      };

      zoxide.enable = true;

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      tmux = {
        enable = true;

        clock24 = true;
        escapeTime = 300;
        historyLimit = 10000;
        keyMode = "vi";
        mouse = true;
        shortcut = "w";
        terminal = "tmux-256color";

        extraConfig = builtins.readFile ./tmux.conf;
      };

      gpg.enable = true;

      git = {
        enable = true;
        delta = {
          enable = true;
          options = {
            side-by-side = true;
          };
        };

        userName = "Hannes Wendt";
        userEmail = "hanneswendt22@gmail.com";

        aliases = {
          a = "add";
          c = "commit";
          d = "diff";
          l = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %aN%C(reset)%C(bold yellow)%d%C(reset)' --all";
          pl = "pull";
          ps = "push";
          r = "restore";
          s = "status";
          sf = "submodule foreach";
        };

        signing = {
          key = "4A61A00BB08DD9FCA34AC2F72FA14F2648079901";
          signByDefault = true;
        };

        extraConfig.pull.rebase = false;
      };

      htop = {
        enable = true;
        settings = {
          account_guest_in_cpu_meter = 1;
          color_scheme = 5;
          hide_userland_threads = 1;
          highlight_base_name = 1;
          highlight_changes = 1;
          highlight_changes_delay_secs = 1;
          show_cpu_frequency = 1;
          show_cpu_temperature = 1;
          show_merged_command = 1;
          show_program_path = 0;
          show_thread_names = 1;
          tree_view = 1;

          tree_sort_key = config.lib.htop.fields.COMM;
          tree_sort_direction = 1;

          fields = with config.lib.htop.fields; [
            PID
            USER
            STATE
            NICE
            PERCENT_CPU
            PERCENT_MEM
            M_RESIDENT
            OOM
            TIME
            COMM
          ];
        } // (with config.lib.htop; leftMeters [
          (bar "AllCPUs")
          (bar "Memory")
          (bar "Zram")
          (bar "DiskIO")
          (bar "NetworkIO")
          (bar "Load")
          (text "Clock")
        ]) // (with config.lib.htop; rightMeters [
          (text "AllCPUs")
          (text "Memory")
          (text "Zram")
          (text "DiskIO")
          (text "NetworkIO")
          (text "LoadAverage")
          (text "Uptime")
        ]);
      };

      lsd = {
        enable = true;
        enableAliases = true;
        settings = {
          sorting.dir-grouping = "first";
        };
      };

      neovim =
        let
          customPlugins = {
            autoclose = pkgs.vimUtils.buildVimPlugin {
              name = "autoclose";
              src = pkgs.fetchgit {
                url = "https://github.com/m4xshen/autoclose.nvim";
                rev = "c4db42ffc0edbd244502be951c142df0c8a7e582";
                sha256 = "hxizkj9pIEvdps4f1hl0eGt0pNVHd2ejMlTQNeis404=";
              };
            };
          };
          allPlugins = pkgs.vimPlugins // customPlugins;
        in
        {
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
          vimdiffAlias = true;

          coc = {
            enable = true;
            pluginConfig = builtins.readFile ./coc.vim;
          };

          plugins = with allPlugins; [
            airline
            autoclose
            gitgutter
            vim-nix
            { plugin = suda-vim; config = "let g:suda_smart_edit = 1"; }
          ];

          extraConfig = builtins.readFile ./init.vim;
        };

      hyfetch = {
        enable = true;
        settings = {
          preset = "rainbow";
          mode = "rgb";
          color_align = {
            mode = "horizontal";
          };
        };
      };

      foot = {
        enable = true;
        settings = {
          main = {
            font = "monospace:size=11";
          };

          colors = {
            alpha = "0.9";
            foreground = "ebdbb2";
            background = "282828";
            regular0 = "282828";
            regular1 = "cc241d";
            regular2 = "98971a";
            regular3 = "d79921";
            regular4 = "458588";
            regular5 = "b16286";
            regular6 = "689d6a";
            regular7 = "a89984";
            bright0 = "928374";
            bright1 = "fb4934";
            bright2 = "b8bb26";
            bright3 = "fabd2f";
            bright4 = "83a598";
            bright5 = "d3869b";
            bright6 = "8ec07c";
            bright7 = "ebdbb2";
          };
        };
      };

      swaylock.settings = {
        daemonize = true;
        image = builtins.toString ./wallpaper.png;
      };

      waybar = {
        enable = true;
        systemd.enable = true;
        style = ./waybar.css;

        settings.mainBar = {
          position = "top";
          spacing = 2;
          ipc = true;

          modules-left = [
            "sway/workspaces"
          ];

          modules-center = [
            "sway/window"
          ];

          modules-right = [
            "pulseaudio"
            "network"
            "cpu"
            "memory"
            "disk"
            "temperature"
            "backlight"
            "battery"
            "clock"
            "idle_inhibitor"
            "tray"
          ];

          "sway/workspaces" = {
            all-outputs = true;
            format = "{icon}";
            format-icons = {
              "0" = "";
              "1" = "󰙯";
              "3" = "";
              "9" = "󰌆";
            };
          };

          pulseaudio = {
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = "  {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "󰜟";
              headset = "󰋎";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" "󰕾" "" ];
            };
          };

          network = {
            format-wifi = "{essid} ({signalStrength}%)  ";
            format-ethernet = "{ipaddr}/{cidr} 󰈀 ";
            tooltip-format = "{ifname} via {gwaddr} 󰈀 ";
            format-linked = "{ifname} (No IP) 󰈀 ";
            format-disconnected = "Disconnected 󰀦 ";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };

          cpu = {
            format = "{usage}%  ";
            tooltip = false;
          };

          memory = {
            format = "{}%  ";
          };

          disk = {
            format = "{percentage_used}% 󰋊 ";
          };

          temperature = {
            hwmon-path = "/sys/class/hwmon/hwmon0/temp1_input";
            critical-threshold = 70;
            format-critical = "{temperatureC}°C {icon}";
            format = "{temperatureC}°C {icon}";
            format-icons = [ "" "" "" "" "" ];
          };

          backlight = {
            device = "amdgpu";
            format = "{percent}% {icon}";
            format-icons = [ "󰃚 " "󰃛 " "󰃜 " "󰃝 " "󰃞 " "󰃟 " "󰃠 " ];
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };

            format = "{time} {capacity}% {icon}";
            format-charging = "{time} {capacity}% {icon} 󱐋";
            format-plugged = "{capacity}%  ";
            format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          };

          clock = {
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%Y-%m-%d}";
          };

          idle_inhibitor = {
            format = "{icon} ";
            format-icons = {
              activated = "󰈈";
              deactivated = "󰈉";
            };
          };

          tray = {
            spacing = 10;
          };
        };
      };
    };

    wayland.windowManager.sway = let
      term = "${pkgs.foot}/bin/foot";
      menu = "${pkgs.fuzzel}/bin/fuzzel";
      mod  = "Mod4";
    in {
      enable = true;
      config = {
        modifier = mod;

        focus.followMouse = true;

        window = {
          border = 1;
          titlebar = false;
          hideEdgeBorders = "both";
        };

        floating = {
          border = 1;
          titlebar = false;
          modifier = mod;
        };

        gaps = {
          inner = 2;
          smartGaps = true;
          smartBorders = "on";
        };

        input."type:keyboard" = {
          repeat_delay = "300";
          repeat_rate  = "50";
          xkb_layout   = "de";
          xkb_options  = "ctrl:nocaps,compose:sclk";
        };

        input."type:touchpad" = {
          dwt = "enabled";
          tap = "enabled";
        };

        output."*" = {
          bg = "${self}/wallpaper.png fill";
          mode = "2560x1440";
        };

        seat."*".hide_cursor = "when-typing enable";

        startup = [
          { command = "terminal"; }
          { command = "${pkgs.keepassxc}/bin/keepassxc"; }
        ];

        keybindings = {
          # programs
          "${mod}+Return"       = "exec terminal";
          "${mod}+Shift+Return" = "exec ${term}";

          "${mod}+Shift+a" = "exec ${term} -e ${pkgs.pulsemixer}/bin/pulsemixer";
          "${mod}+b"       = "exec systemctl --user restart waybar";
          "${mod}+d"       = "exec ${menu}";
          "${mod}+i"       = "exec ${term} -e ${pkgs.htop}/bin/htop";
          "${mod}+Shift+w" = "exec ${pkgs.firefox}/bin/firefox";
          "${mod}+x"       = "exec ${pkgs.swaylock}/bin/swaylock";

          # special
          "${mod}+Backspace"         = "exec prompt Shutdown? poweroff";
          "${mod}+Shift+Backspace"   = "exec prompt Reboot?   reboot";
          "${mod}+Control+Backspace" = "exec prompt Suspend?  swaylock && systemctl suspend";
          "${mod}+Escape"            = "exec prompt Logout?   pkill sway";

          # WM
          "${mod}+f"       = "fullscreen";
          "${mod}+Shift+f" = "floating toggle";
          "${mod}+h"       = "move scratchpad";
          "${mod}+Shift+h" = "scratchpad show";
          "${mod}+q"       = "kill";

          "${mod}+Tab"     = "workspace back_and_forth";
          "${mod}+space"   = "focus mode_toggle";

          "${mod}+Left"  = "focus left";
          "${mod}+Right" = "focus right";
          "${mod}+Up"    = "focus up";
          "${mod}+Down"  = "focus down";

          "${mod}+Shift+Left"  = "move left";
          "${mod}+Shift+Right" = "move right";
          "${mod}+Shift+Up"    = "move up";
          "${mod}+Shift+Down"  = "move down";

          "${mod}+dead_circumflex" = "workspace number 0";
          "${mod}+0" = "workspace number 0";
          "${mod}+1" = "workspace number 1";
          "${mod}+2" = "workspace number 2";
          "${mod}+3" = "workspace number 3";
          "${mod}+4" = "workspace number 4";
          "${mod}+5" = "workspace number 5";
          "${mod}+6" = "workspace number 6";
          "${mod}+7" = "workspace number 7";
          "${mod}+8" = "workspace number 8";
          "${mod}+9" = "workspace number 9";

          "${mod}+Shift+dead_circumflex" = "move container to workspace number 0";
          "${mod}+Shift+0" = "move container to workspace number 0";
          "${mod}+Shift+1" = "move container to workspace number 1";
          "${mod}+Shift+2" = "move container to workspace number 2";
          "${mod}+Shift+3" = "move container to workspace number 3";
          "${mod}+Shift+4" = "move container to workspace number 4";
          "${mod}+Shift+5" = "move container to workspace number 5";
          "${mod}+Shift+6" = "move container to workspace number 6";
          "${mod}+Shift+7" = "move container to workspace number 7";
          "${mod}+Shift+8" = "move container to workspace number 8";
          "${mod}+Shift+9" = "move container to workspace number 9";
        };

        workspaceAutoBackAndForth = true;

        bars = [];

        assigns = {
          "3" = [{ app_id = "firefox"; }];
          "9" = [{ app_id = "org.keepassxc.KeePassXC"; }];
        };
      };

      extraConfig = ''
        set $term ${term}
        for_window [app_id="dropdown.*"] floating enable
        for_window [app_id="dropdown.*"] resize set 800 400
      '';
    };
  };
}
