{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];
  
  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Enable networking
  networking.hostName = "odd";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  # Configure graphics
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Location for redshift
  location = {
    latitude = 58.0;
    longitude = 9.0;
  };
  
  # Configure redshift
  services.redshift = {
    enable = true;
    brightness = {
      day = "1.0";
      night = "0.6";
    };
    temperature = {
      day = 6500;
      night = 2000;
    };
  };
  
  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # System config
  system.stateVersion = "22.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow experimental features  
  nix.extraOptions = ''
      experimental-features = nix-command
  '';

  # Don't use that ugly GUI program for password
  programs.ssh.askPassword = "";

  # Make sure we're not on powersave
  powerManagement.cpuFreqGovernor= "performance";

  # Overlays
  nixpkgs.overlays = [
    # Emacs
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/emacs-overlay.git";
      ref = "master";
      rev = "a04bc2fc2b6bc9c1ba738cf8de3d33768d298c7c";
    }))

    # Rust
    (import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))

    # dwm
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (drv: {
        src = prev.fetchFromGitHub {
          owner = "knarkzel";
          repo = "dwm";
          rev = "06816fcb2059a007e65f0d16caec519763ab360e";
          sha256 = "Bghri5KmjFRHJKJv4Bi4K304C9d2otUaweVK/j/VJdA=";
        };
      });
    })
  ];

  # Emacs with native compilation
  services.emacs.package = pkgs.emacsNativeComp;

  # Configure console keymap
  console.keyMap = "colemak";

  # Configure X11
  services.xserver = {
    enable = true;
    windowManager.dwm.enable = true;
    layout = "us";
    xkbVariant = "colemak";
    xkbOptions = "ctrl:nocaps";
    libinput = {
      enable = true;
      mouse.accelSpeed = "0";
    };
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "odd";
      sessionCommands = ''
        xset -dpms
        xset s off
        xset r rate 200 50
        ${pkgs.dunst}/bin/dunst &
        ${pkgs.xbanish}/bin/xbanish &
        ${pkgs.xcape}/bin/xcape -e "Control_L=Escape"
        ${pkgs.hsetroot}/bin/hsetroot -solid "#f7f3ee"
      '';
    };
  };

  # Fonts
  fonts.fonts = with pkgs; [
    hack-font
    noto-fonts-emoji
  ];
  
  # Define a user account.
  users.users.odd = {
    isNormalUser = true;
    description = "Odd-Harald";
    extraGroups = [ "networkmanager" "wheel" ];

    packages = with pkgs; [
      # window manager
      dmenu
      dunst
      xbanish
      xcape
      hsetroot

      # emacs
      ((emacsPackagesFor emacsNativeComp).emacsWithPackages (epkgs: [ epkgs.vterm ]))

      # rust
      (rust-bin.stable.latest.rust.override { extensions = ["rust-src"]; })
      rust-analyzer
      mold

      # zig
      zig
      zls
      
      # other
      fd
      git
      firefox
      starship
      alacritty
      ripgrep
      ffmpeg
      mpv
      scrot
      mupdf
      zip
      unzip
      file
      p7zip
      lxrandr
      clang
    ];
  };

  # Make sure dotfiles exist
  systemd.services.dotfiles = {
    description = "Initializes bare dotfiles repository";
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      ConditionPathExists = "!/home/odd/.cfg";
      Requires = "network-online.target";
      After = "network-online.target";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "odd";
      ExecStart = [
        ''${pkgs.git}/bin/git clone --bare https://github.com/knarkzel/dotfiles /home/odd/.cfg''
        ''${pkgs.git}/bin/git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ checkout -f''
        ''${pkgs.git}/bin/git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ config status.showUntrackedFiles no''
        ''${pkgs.coreutils}/bin/mkdir -p /home/odd/downloads''
        ''${pkgs.coreutils}/bin/mkdir -p /home/odd/source''
      ];
    };
  };
}
