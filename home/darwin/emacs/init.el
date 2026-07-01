;;; init.el --- Modular config loader  -*- lexical-binding: t; -*-
;; Packages are managed by straight.el (bootstrapped in early-init.el).

(eval-when-compile
  (require 'use-package))

(setq straight-use-package-by-default t)

;; ── Custom recipes ────────────────────────────────────────────────────
;; ghostel has a native Zig module — ensure `zig` is on PATH for the build.

(use-package ghostel
  :straight (ghostel :host github :repo "dakra/ghostel"))

;; ── Packages (straight.el auto-fetches from MELPA/GitHub) ─────────────
(use-package evil)
(use-package evil-collection)
(use-package kanagawa-themes)
(use-package vertico)
(use-package orderless)
(use-package marginalia)
(use-package consult)
(use-package consult-eglot :after eglot)
(use-package corfu)
(use-package cape)
(use-package eldoc-box)
(use-package markdown-mode)
(use-package magit)
(use-package neotree)
(use-package which-key)
(use-package envrc)
(use-package nix-mode)
(use-package qml-mode)

;; ── Load modular config from lisp/ ────────────────────────────────────
(dolist (m '("ui" "evil" "modeline" "completion" "ide" "markdown" "ghostel" "keybindings" "workspace"))
  (load (expand-file-name (concat "lisp/" m) user-emacs-directory) nil t))

;;; init.el ends here
