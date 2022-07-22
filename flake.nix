{
  description = "Knarkzel's NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    emacs-overlay,
    ...
  } @ inputs: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    nixosConfigurations."odd" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix # System configuration
        ({pkgs, ...}: {
          nixpkgs.overlays = [
            # rust
            rust-overlay.overlays.default

            # emacs
            emacs-overlay.overlay

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
                  rev = "37903c99818426f4c913fbcc59fa23c84b206f54";
                  sha256 = "FECWdptTxU1ZZnBDMG3onnKv31X7noEaunI1FnP+8HA=";
                };
              });
            })
          ];
        })
      ];
    };
  };
}
