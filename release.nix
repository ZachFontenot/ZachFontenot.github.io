let
  sources = import ./nix/sources.nix;
in
{ compiler ? "ghc884"
, pkgs ? import sources.nixpkgs { }
}:

let
  inherit (pkgs.lib.trivial) flip pipe;
  inherit (pkgs.haskell.lib) appendPatch appendConfigureFlags;

  haskellPackages = pkgs.haskell.packages.${compiler}.override {
    overrides = hpNew: hpOld: {
      hakyll =
        pipe
          hpOld.hakyll
          [ (flip appendPatch ./hakyll.patch)
            (flip appendConfigureFlags [ "-f" "watchServer" "-f" "previewServer" ])
          ];

      fintech-startup = hpNew.callCabal2nix "fintech-startup" ./. { };

      niv = import sources.niv { };
    };
  };

  project = haskellPackages.fintech-startup;
in
{
  project = project;

  shell = haskellPackages.shellFor {
    packages = p: with p; [
      project
    ];
    buildInputs = with haskellPackages; [
      ghcid
      ormolu
      niv
      pkgs.cacert
      pkgs.nix
    ];
    withHoogle = true;
  };
}
