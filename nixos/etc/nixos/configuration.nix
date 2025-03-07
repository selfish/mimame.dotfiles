# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  unstableTarball =
    fetchTarball "https://github.com/nixos/nixpkgs/tarball/nixos-unstable";

  # bash script to let dbus know about important env variables and
  # propagate them to relevent services run at the end of sway config
  # see
  # https://github.com/emersion/xdg-desktop-portal-wlr/wiki/"It-doesn't-work"-Troubleshooting-Checklist
  # note: this is pretty much the same as  /etc/sway/config.d/nixos.conf but also restarts  
  # some user services to make sure they have the correct environment variables
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  # currently, there is some friction between sway and gtk:
  # https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
  # the suggested way to set gtk settings is with gsettings
  # for gsettings to work, we need to tell it where the schemas are
  # using the XDG_DATA_DIR environment variable
  # run at the end of sway config
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      export GTK_THEME="Sweet-Dark"
      gnome_schema=org.gnome.desktop.interface
      gsettings set $gnome_schema gtk-theme "Sweet-Dark"
      gsettings set $gnome_schema theme "Sweet-Dark"
      gsettings set $gnome_schema icon-theme "BeautyLine"
      gsettings set $gnome_schema cursor-theme "capitaine-cursors-white"
      gsettings set $gnome_schema cursor-size 32
      gsettings set org.gnome.desktop.wm.preferences theme "Sweet-Dark"
      gsettings set $gnome_schema document-font-name 'Hack 13'
      gsettings set $gnome_schema font-name 'Hack 13'
      gsettings set $gnome_schema monospace-font-name 'Hack 13'
    '';
  };

in {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];
  # Add unstable packages injecting directly the unstable channel url
  nixpkgs.config = {
    packageOverrides = pkgs:
      with pkgs; {
        unstable = import unstableTarball { config = config.nixpkgs.config; };
      };
  };

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
  };

  networking = {
    firewall = {
      # Or disable the firewall altogether.
      enable = true;
      # Open ports in the firewall.
      allowedUDPPorts = [ ];
      allowedTCPPorts = [ ];
    };
    hostName = "nixos";
    networkmanager.enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    forwardX11 = true;
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # FIXME: Not working
  powerManagement.cpuFreqGovernor = "ondemand";

  system.autoUpgrade = {
    allowReboot = false;
    enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  # Synchronise time and date
  services.chrony.enable = true;
  services.localtimed.enable = true;
  services.geoclue2.enable = true;
  services.geoclue2.appConfig.localtimed = {
    isAllowed = true;
    isSystem = true;
    users = [ "1000" ];
  };
  services.avahi.enable = true;

  # Locate service
  services.locate = {
    enable = true;
    locate = pkgs.plocate;
    localuser = null;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    displayManager = {
      gdm.enable = true;
      defaultSession = "sway";
      autoLogin = {
        enable = true;
        user = "mimame";
      };
    };
    # Enable touchpad support (enabled by default in most desktopManager).
    libinput.enable = true;
  };

  services.interception-tools = {
    enable = true;
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    '';
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "altgr-intl";
  };

  # Configure console keymap
  console.keyMap = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.unstable.fish;
    users.mimame = {
      isNormalUser = true;
      description = "mimame";
      extraGroups = [ "networkmanager" "wheel" "video" ];
      packages = with pkgs;
        [
          #  firefox
          #  thunderbird
        ];

    };
  };

  services.gnome.gnome-keyring.enable = true;

  security.polkit.enable = true;

  # FIXME: use geoclue2 in the config file instead a fixed latitude
  # services.redshift.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;
    [

      aspell
      aspellDicts.en
      aspellDicts.es
      aspellDicts.fr
      at
      avfs
      axel
      baobab
      bc
      bind
      bison
      blueman
      bluez
      bluez-tools
      caffeine-ng
      clang # Maybe breaks the lvim treesitter compilation
      clipman
      configure-gtk
      dbus-sway-environment
      dosfstools
      fakeroot
      firmwareLinuxNonfree
      glib # gsettings
      gnome.seahorse
      gparted
      graphviz
      grim # screenshot functionality
      gthumb
      gvfs
      hyphen
      inkscape
      interception-tools
      jc
      keepassxc
      less
      libarchive
      libevdev
      libinput-gestures
      libnotify
      libreoffice-fresh
      light
      linuxKernel.kernels.linux_zen
      linuxKernel.packages.linux_zen.virtualbox
      lnav
      lsb-release
      lsof
      lua
      lxappearance
      man-db
      man-pages
      meld
      networkmanagerapplet
      nixfmt
      nixpkgs-review
      nodePackages.npm
      ntfs3g
      openssl
      parallel
      parted
      pass
      passExtensions.pass-import
      pulseaudio # to be able to use pactl
      putty
      pv
      pwgen
      python3Packages.cython
      python3Packages.howdoi
      python3Packages.ipython
      rustscan
      rustup
      scrot
      singularity
      slurp # screenshot functionality
      strace
      stress
      stylua
      sudo
      sway
      swayidle
      swaylock
      swaynotificationcenter
      tesseract5
      time
      util-linux
      virtualbox
      wayland
      wev
      wl-clipboard
      wlrctl
      xdg-user-dirs
      xdg-utils
      yarn
      ydotool

    ] ++ (with pkgs.unstable; [

      ansible
      aria2
      asciidoc-full
      asciidoctor
      auto-cpufreq
      autoconf
      automake
      bat
      beauty-line-icon-theme
      broot
      brotli
      btop
      bzip2
      calibre
      capitaine-cursors
      cmake
      coreutils
      crystal
      curl
      curlie
      delta
      difftastic
      direnv
      diskus
      dogdns
      dos2unix
      dropbox
      dstat
      dua
      duf
      dura
      entr
      espanso
      exa
      fd
      file
      filezilla
      firefox
      fish
      flameshot
      fuse-common
      fuse3
      fzf
      gawk
      gdu
      gimp
      git
      git-cola
      git-extras
      gitg
      github-cli
      gitoxide
      gitui
      glow
      gnumake
      gnupatch
      gnupg
      go
      google-chrome
      grc
      grex
      gron
      gzip
      handlr
      helix
      htop
      httpie
      hugo
      hyperfine
      i3status-rust
      jekyll
      jq
      julia-bin
      just
      kitty
      kitty-themes
      klavaro
      lazydocker
      lazygit
      litecli
      logseq
      lsd
      massren
      mcfly
      mdcat
      meson
      micro
      mosh
      mtr
      navi
      ncdu_2
      neofetch
      neovim
      newsboat
      nim
      ninja
      nushell
      obsidian
      onefetch
      ouch
      pandoc
      pcmanfm
      pcre2
      pdftk
      pigz
      pixz
      plantuml
      playerctl
      plocate
      podman
      podman-compose
      podman-tui
      procs
      progress
      pueue
      qutebrowser
      ranger
      rclone
      ripgrep
      rlwrap
      rofi
      rsync
      scc
      sd
      shards
      shellcheck
      shfmt
      spicetify-cli
      spotify
      sqlite
      sqlite-utils
      sqlitebrowser
      sshfs
      starship
      stow
      sweet
      tealdeer
      tectonic
      testdisk
      thefuck
      tokei
      translate-shell
      trash-cli
      tree
      tridactyl-native
      udiskie
      udisks
      universal-ctags
      unrar
      urlscan
      vagrant
      vifm
      visidata
      vivaldi
      vivid
      vlang
      vlc
      vscode
      watchexec
      wget
      xh
      xonsh
      zathura
      zellij
      zenith
      zig
      zlib-ng
      zotero
      zoxide
      zstd

    ]);

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" ]; })
    font-awesome
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # enable sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
      export GTK_USE_PORTAL=1
    '';
  };

  environment.etc = {
    "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
      bluez_monitor.properties = {
        ["bluez5.enable-sbc-xq"] = true,
        ["bluez5.enable-msbc"] = true,
        ["bluez5.enable-hw-volume"] = true,
        ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
      }
    '';
  };

  programs.light.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
