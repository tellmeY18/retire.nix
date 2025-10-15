  {
    programs.emacs = {
      enable = true;
      extraConfig = ''
        ;; Basic settings
        (setq inhibit-startup-message t)
        (setq make-backup-files nil)
        (setq auto-save-default nil)
        (menu-bar-mode -1)
        (tool-bar-mode -1)
        (scroll-bar-mode -1)
        (global-display-line-numbers-mode 1)
        (setq display-line-numbers-type 'relative)
        (show-paren-mode 1)

        ;; Remove Doom-specific hooks and variables to prevent errors
        (setq doom-modules nil)
        (remove-hook 'doom-after-init-hook 'doom-display-benchmark-h)

        ;; Evil mode for vim keybindings
        (require 'evil)
        (evil-mode 1)

        ;; Enable undo-tree for better undo/redo
        (require 'undo-tree)
        (global-undo-tree-mode)
        (evil-set-undo-system 'undo-tree)

        ;; Which-key for key discovery
        (require 'which-key)
        (which-key-mode)

        ;; Helm for better completion
        (require 'helm)
        (helm-mode 1)
        (global-set-key (kbd "M-x") 'helm-M-x)
        (global-set-key (kbd "C-x C-f") 'helm-find-files)
        (global-set-key (kbd "C-x b") 'helm-buffers-list)

        ;; Projectile for project management
        (require 'projectile)
        (projectile-mode 1)
        (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
      '';
      extraPackages = epkgs: with epkgs; [
        evil
        evil-collection
        undo-tree
        which-key
        helm
        projectile
        magit
        company
        flycheck
        use-package
      ];
    };
  }
