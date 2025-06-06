{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    talhelper.url = "github:budimanjojo/talhelper";
  };

  outputs = { self, nixpkgs, utils, talhelper }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        talhelperPkgs = import talhelper {
          inherit system;
          lib = nixpkgs.lib;
          stdenv = pkgs.stdenv;
        };
      in
      {
        devShell = with pkgs; mkShell {
          buildInputs = [
            talosctl
            talhelperPkgs.talhelper
            age
            k9s
            kubectl
            direnv
            kustomize
            argocd
            kubevirt
            jekyll
            ruby
            kubernetes-helm
            opentofu
          ];
          #RUST_SRC_PATH = rustPlatform.rustLibSrc;
        };
      }
    );
}
