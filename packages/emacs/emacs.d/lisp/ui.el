;;; ui.el --- Frame chrome, line numbers, scrolling, font, theme  -*- lexical-binding: t; -*-

(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(setq display-line-numbers-type 'relative)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

(pixel-scroll-precision-mode 1)
(setq pixel-scroll-precision-interpolate-page t)
(setq scroll-conservatively 101
      scroll-margin 3
      scroll-step 1)

(let ((lib (locate-library "kanagawa-themes" t)))
  (when lib
    (add-to-list 'custom-theme-load-path (file-name-directory lib))))
(load-theme 'kanagawa-wave t)

;; ── Silence the bell ──────────────────────────────────────────
(setq ring-bell-function #'ignore)

;; ── Borderless (emacs-macport) ───────────────────────────────
;; Hide the native macOS title bar for a sleek, floating look.
;; Use `mac-show-title-bar' / <leader>wt to toggle it back on.
(when (fboundp 'mac-hide-title-bar)
  (mac-hide-title-bar t))

;; ── Default frame geometry — opens as a nice floating rectangle ──
;; Width/height in character units, left/top in pixels.
;; Adjust to taste or remove to let OmniWM manage sizing entirely.
(add-to-list 'default-frame-alist '(width . 140))
(add-to-list 'default-frame-alist '(height . 50))
(add-to-list 'default-frame-alist '(left . 180))
(add-to-list 'default-frame-alist '(top . 80))

;; ── Toggle title bar when borderless gets in the way ─────────
(defun my/toggle-title-bar ()
  "Show or hide the Emacs title bar (emacs-macport).
Calls `mac-hide-title-bar' with no argument to toggle."
  (interactive)
  (if (fboundp 'mac-hide-title-bar)
      (progn
        (mac-hide-title-bar)
        (message "Title bar toggled"))
    (message "Title bar toggle not available (not emacs-macport)")))

;;; ui.el ends here
