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
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" ];

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

  # Enable iPhone tethering
  services.usbmuxd.enable = true;


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
      experimental-features = nix-command flakes
  '';

  # Don't use that ugly GUI program for password
  programs.ssh.askPassword = "";

  # Make sure we're not on powersave
  powerManagement.cpuFreqGovernor= "performance";

  # Overlays
  nixpkgs.overlays = [
    # dwm
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (drv: {
        src = prev.fetchFromSourcehut {
          owner = "~knarkzel";
          repo = "dwm";
          rev = "a91eb88ce69cdaf67413faba4251e89e0e08348f";
          sha256 = "NOOuiNFSC1BOZiF73ZM63+VrJYaa3wUg716Pho0M+SY=";
        };
      });
    })

    # dmenu
    (final: prev: {
      dmenu = prev.dmenu.overrideAttrs (drv: {
        src = prev.fetchFromSourcehut {
          owner = "~knarkzel";
          repo = "dmenu";
          rev = "681271e3e5cb413fd9f079599ab2aceafbe2bbaa";
          sha256 = "dp9pdGgPIgc5qKo78MvBKN4J69Yn1FTAAwAccmmj04I=";
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
        dunst &
        xbanish &
        hsetroot -solid "#f7f3ee"
      '';
    };
  };

  # Fonts
  fonts.fonts = with pkgs; [
    hack-font
    noto-fonts-emoji
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    libimobiledevice
    fd
    git
    ripgrep
    zip
    unzip
    file
    psmisc
    tldr
    clang
    p7zip
  ];
  
  # Define user account.
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
      (rust-bin.stable.latest.default.override { extensions = ["rust-src"]; })
      rust-analyzer
      mold

      # zig
      zig
      zls
      
      # other
      starship
      alacritty
      firefox
      ffmpeg
      mpv
      scrot
      mupdf
      lxrandr
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
        ''${pkgs.git}/bin/git clone --bare git@git.sr.ht:~knarkzel/dotfiles /home/odd/.cfg''
        ''${pkgs.git}/bin/git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ checkout -f''
        ''${pkgs.git}/bin/git --git-dir=/home/odd/.cfg --work-tree=/home/odd/ config status.showUntrackedFiles no''
        ''${pkgs.coreutils}/bin/mkdir -p /home/odd/downloads''
        ''${pkgs.coreutils}/bin/mkdir -p /home/odd/source''
      ];
    };
  };

  # xcape service
  systemd.user.services.xcape = {
    description = "Combine Ctrl+Escape";
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "forking";
      Restart = "always";
      ExecStart = ''${pkgs.xcape}/bin/xcape -e "Control_L=Escape"'';      
    };
  };
}
