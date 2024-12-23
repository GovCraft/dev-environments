{ config, flake-parts-lib, lib, pkgs, ... }:
let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
in
{
  options.perSystem = mkPerSystemOption
    ({ config, self', inputs', pkgs, system, ... }:
      let
        mainSubmodule = types.submodule ({ config, ... }: {
          options = {
            enable = lib.mkEnableOption "Node.js development environment";
            nodeVersion = lib.mkOption {
              type = lib.types.str;
              default = "20";
              description = "Node.js version to use (e.g., '18', '20')";
            };
            withTools = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "typescript" "yarn" "pnpm" ];
              description = "List of Node.js global tools to include";
            };
            extraPackages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = "Additional packages to include";
            };
            ide = {
              type = lib.mkOption {
                type = lib.types.enum [ "vscode" "webstorm" "none" ];
                default = "none";
                description = "IDE preference for Node.js development";
              };
            };
          };
        });
      in
      {
        options.node-dev = lib.mkOption {
          type = mainSubmodule;
          description = lib.mdDoc ''
            Specification for the Node.js development environment
          '';
          default = { };
        };

        config = lib.mkIf config.node-dev.enable {
          env-packages.node = [
            (pkgs."nodejs_${config.node-dev.nodeVersion}")
            pkgs.nodePackages.npm
            pkgs.gnumake
            pkgs.gcc
            pkgs.python3
          ] ++ lib.optionals (config.node-dev.ide.type == "webstorm") [
            pkgs.jetbrains.webstorm
          ] ++ (map (tool: pkgs.nodePackages.${tool}) config.node-dev.withTools)
            ++ config.node-dev.extraPackages;

          env-hooks.node = ''
            echo "Node.js $(node --version) development environment"
            echo "npm $(npm --version)"
          '';
        };
      });
}
