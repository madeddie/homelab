{ pkgs ? import <nixpkgs> {} }:

with pkgs;
mkShell {
  # List of packages
  nativeBuildInputs = [
    talosctl
    talhelper
    sops
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

  # Load environment variables from .env file
  shellHook = ''
    if [ -f .env ]; then
      export $(grep -v '^#' .env | xargs)
    fi
    echo 'Welcome to madtech homelab devshell!'
  '';
}
