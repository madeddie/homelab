{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    madeddie-nur = {
      url = "github:madeddie/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, madeddie-nur }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        sharedBuildInputs = [
          pkgs.talosctl
          pkgs.talhelper
          pkgs.age
          pkgs.k9s
          pkgs.kubectl
          pkgs.direnv
          pkgs.kustomize
          pkgs.argocd
          pkgs.kubevirt
          pkgs.jekyll
          pkgs.ruby
          pkgs.kubernetes-helm
          pkgs.opentofu
        ];
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = sharedBuildInputs;
        };

        packages = {
          default = pkgs.stdenv.mkDerivation {
            name = "homelab";
            src = self; # Reference the flake's source
            buildInputs = sharedBuildInputs;

            # Define empty build phases if no build is required
            buildPhase = ''
              echo "No build required for default-package"
            '';
            installPhase = ''
              mkdir -p $out
              echo "Default package installed" > $out/README.txt
            '';
          };
        };
      }
    );
}
