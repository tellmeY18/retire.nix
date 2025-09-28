{ ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;

    # Additional direnv configuration
    config = {
      global = {
        load_dotenv = true;
        hide_env_diff = true;
        strict_env = true;
        warn_timeout = "5s";
      };
    };

    # Custom stdlib functions
    stdlib = ''
      # Custom function to layout for Python projects
      layout_python() {
        local python=''${1:-python3}
        [[ $# -gt 0 ]] && shift
        unset PYTHONHOME
        if [[ -n $VIRTUAL_ENV ]]; then
          VIRTUAL_ENV=$(realpath "''${VIRTUAL_ENV}")
        else
          local venv_path="venv"
          if [[ -d .venv ]]; then
            venv_path=".venv"
          fi

          if [[ ! -d $venv_path ]]; then
            log_status "Creating virtual environment with $python"
            $python -m venv "$venv_path"
          fi

          VIRTUAL_ENV=$(realpath "$venv_path")
        fi

        export VIRTUAL_ENV
        PATH_add "$VIRTUAL_ENV/bin"
        export PYTHONPATH=""
      }

      # Custom function for Node.js projects
      layout_node() {
        local node_version=''${1:-18}

        if [[ -f .nvmrc ]]; then
          node_version=$(cat .nvmrc)
        fi

        if command -v fnm > /dev/null; then
          log_status "Setting up Node.js $node_version with fnm"
          eval "$(fnm env --use-on-cd)"
          fnm use "$node_version"
        elif command -v nvm > /dev/null; then
          log_status "Setting up Node.js $node_version with nvm"
          nvm use "$node_version"
        fi

        # Add node_modules/.bin to PATH if it exists
        if [[ -d node_modules/.bin ]]; then
          PATH_add node_modules/.bin
        fi
      }

      # Custom function for Rust projects
      layout_rust() {
        if [[ -f Cargo.toml ]]; then
          log_status "Setting up Rust environment"

          # Add cargo bin to PATH
          if [[ -d "$HOME/.cargo/bin" ]]; then
            PATH_add "$HOME/.cargo/bin"
          fi

          # Set RUST_SRC_PATH if rust-src is installed
          if command -v rustc > /dev/null; then
            local rust_src_path=$(rustc --print sysroot)/lib/rustlib/src/rust/library
            if [[ -d "$rust_src_path" ]]; then
              export RUST_SRC_PATH="$rust_src_path"
            fi
          fi
        fi
      }

      # Custom function for Go projects
      layout_go() {
        if [[ -f go.mod ]]; then
          log_status "Setting up Go environment"

          # Set GOPATH to project-local path
          export GOPATH="$PWD/.go"
          PATH_add "$GOPATH/bin"

          # Create necessary directories
          mkdir -p "$GOPATH/bin"
        fi
      }

      # Custom function for Java/JVM projects
      layout_java() {
        local java_version=''${1:-11}

        if command -v sdk > /dev/null; then
          log_status "Setting up Java $java_version with SDKMAN"
          sdk use java "$java_version"
        fi

        # Add gradle/maven wrappers to PATH
        if [[ -f gradlew ]]; then
          PATH_add "$(pwd)"
        fi

        if [[ -f mvnw ]]; then
          PATH_add "$(pwd)"
        fi
      }
    '';
  };
}
