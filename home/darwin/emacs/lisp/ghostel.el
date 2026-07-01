;;; ghostel.el --- Ghostel terminal: evil integration, openers, file shim, startup banner  -*- lexical-binding: t; -*-

(add-hook 'ghostel-mode-hook #'evil-ghostel-mode)

(setq evil-ghostel-escape 'terminal)

(setq ghostel-buffer-name "term:")

(defun my/ghostel-foreground-program ()
  (when-let* (((eq system-type 'gnu/linux))
              (pid (bound-and-true-p ghostel--pid))
              (stat (ignore-errors
                      (with-temp-buffer
                        (insert-file-contents (format "/proc/%d/stat" pid))
                        (buffer-string))))
              ((string-match ".*) \\(.*\\)" stat)))
    (let* ((fields (split-string (match-string 1 stat)))
           (pgrp  (string-to-number (nth 2 fields)))
           (tpgid (string-to-number (nth 5 fields))))
      (when (and (> tpgid 0) (/= tpgid pgrp))
        (ignore-errors
          (string-trim
           (with-temp-buffer
             (insert-file-contents (format "/proc/%d/comm" tpgid))
             (buffer-string))))))))

(defun my/ghostel-buffer-name (title)
  (if (and title (not (string= "" title)))
      (format "term: %s" title)
    (let ((dir  (abbreviate-file-name (directory-file-name default-directory)))
          (prog (my/ghostel-foreground-program)))
      (if prog
          (format "term: %s: %s" dir prog)
        (format "term: %s" dir)))))

(setq ghostel-buffer-name-function #'my/ghostel-buffer-name)

(defun my/ghostel-refresh-name (buffer &rest _)
  (when (buffer-live-p buffer)
    (run-at-time
     0.1 nil
     (lambda ()
       (when (buffer-live-p buffer)
         (with-current-buffer buffer
           (when ghostel-buffer-name-function
             (let ((title (and ghostel--term (ghostel--get-title ghostel--term))))
               (ghostel--rename-managed
                (funcall ghostel-buffer-name-function title))))))))))

(with-eval-after-load 'ghostel
  (add-hook 'ghostel-command-start-functions  #'my/ghostel-refresh-name)
  (add-hook 'ghostel-command-finish-functions #'my/ghostel-refresh-name))

(defun my/ghostel-paste-clipboard ()
  (interactive)
  (let ((text (gui-get-selection 'CLIPBOARD)))
    (if (and text (not (string-empty-p text)))
        (ghostel-paste-string text)
      (user-error "System clipboard is empty"))))

(with-eval-after-load 'evil-ghostel
  (evil-define-key* '(insert emacs) evil-ghostel-mode-map
                      (kbd "C-<escape>") #'evil-normal-state
                      (kbd "M-o")       #'ghostel-emacs-mode
                      (kbd "C-c") #'ghostel-send-C-c
                    (kbd "C-x") (lambda () (interactive) (ghostel-send-key "x" "ctrl"))
                    (kbd "C-t") #'my/ghostel-fresh
                    (kbd "C-<tab>") #'ghostel-next
                    (kbd "C-S-<tab>") #'ghostel-previous
                    (kbd "C-<iso-lefttab>") #'ghostel-previous
                    (kbd "C-S-v") #'my/ghostel-paste-clipboard)
  (evil-define-key* 'normal evil-ghostel-mode-map
                    (kbd "C-t") #'my/ghostel-fresh
                    (kbd "C-<tab>") #'ghostel-next
                    (kbd "C-S-<tab>") #'ghostel-previous
                    (kbd "C-<iso-lefttab>") #'ghostel-previous
                    (kbd "RET") #'ghostel-open-link-at-point
                    (kbd "]l") #'ghostel-next-hyperlink
                    (kbd "[l") #'ghostel-previous-hyperlink))

(defun my/ghostel-browse-on-normal ()
  (when (evil-ghostel--active-p)
    (let ((inhibit-message t))
      (ghostel-emacs-mode))))

(defun my/ghostel-follow-on-insert ()
  (when (and (derived-mode-p 'ghostel-mode)
             (eq ghostel--input-mode 'emacs))
    (ghostel-semi-char-mode)))

(defun my/ghostel-wheel-browse (event)
  (with-current-buffer (window-buffer (posn-window (event-start event)))
    (when (and (evil-ghostel--active-p)
               (evil-insert-state-p)
               (not (ghostel--mouse-tracking-active-p)))
      (evil-normal-state))))

(with-eval-after-load 'evil-ghostel
  (add-hook 'ghostel-mode-hook
            (lambda ()
              (add-hook 'evil-normal-state-entry-hook
                        #'my/ghostel-browse-on-normal nil t)
              (add-hook 'evil-insert-state-entry-hook
                        #'my/ghostel-follow-on-insert -90 t)))
  (advice-add 'ghostel--scroll-intercept-up :before #'my/ghostel-wheel-browse))

(defun my/ghostel-fresh ()
  (interactive)
  (ghostel '(4)))

(defun my/ghostel-split ()
  (interactive)
  (select-window (split-window-below))
  (ghostel '(4)))

(defun my/ghostel-vsplit ()
  (interactive)
  (select-window (split-window-right))
  (ghostel '(4)))

(with-eval-after-load 'evil
  (setq evil--jumps-buffer-targets
        (concat evil--jumps-buffer-targets "\\|\\`term:")))

(defun my/ghostel-set-jump ()
  (when (fboundp 'evil-set-jump)
    (evil-set-jump)))

(defun my/ghostel-find-file (filename)
  (my/ghostel-set-jump)
  (find-file filename))

(defun my/ghostel-find-file-split (filename)
  (select-window (split-window-below))
  (my/ghostel-set-jump)
  (find-file filename))

(defun my/ghostel-find-file-vsplit (filename)
  (select-window (split-window-right))
  (my/ghostel-set-jump)
  (find-file filename))

(with-eval-after-load 'ghostel
  (setq ghostel-eval-cmds
        (cons '("find-file" my/ghostel-find-file)
              (assoc-delete-all "find-file" ghostel-eval-cmds)))
  (add-to-list 'ghostel-eval-cmds '("find-file-split"  my/ghostel-find-file-split))
  (add-to-list 'ghostel-eval-cmds '("find-file-vsplit" my/ghostel-find-file-vsplit)))

(defvar my/ghostel-shim-dir
  (expand-file-name "ghostel-shim" user-emacs-directory)
  "Directory holding our generated ghostel zsh-integration shim.")

(defun my/ghostel-install-shell-shim ()
  (let ((real (getenv "EMACS_GHOSTEL_PATH")))
    (when (and real (string-match-p "zsh" (or ghostel-shell "")))
      (let* ((dir (expand-file-name "etc/shell" my/ghostel-shim-dir))
             (shim (expand-file-name "ghostel.zsh" dir))
             (real-integ (expand-file-name "etc/shell/ghostel.zsh" real)))
        (make-directory dir t)
        (with-temp-file shim
          (insert
           "# Auto-generated by init.el — regenerated on each ghostel spawn.\n"
           "# Load ghostel's real zsh integration (defines `ghostel_cmd'),\n"
           "# then add file-opening helpers that call whitelisted Emacs cmds.\n"
           "'builtin' 'source' '--' " (shell-quote-argument real-integ) "\n"
           "export EMACS_GHOSTEL_PATH=" (shell-quote-argument real) "\n"
           "e()  { ghostel_cmd find-file        \"${1:a}\"; }\n"
           "es() { ghostel_cmd find-file-split  \"${1:a}\"; }\n"
           "ev() { ghostel_cmd find-file-vsplit \"${1:a}\"; }\n"))
        (setenv "EMACS_GHOSTEL_PATH" my/ghostel-shim-dir)))))

(add-hook 'ghostel-pre-spawn-hook #'my/ghostel-install-shell-shim)

(setq inhibit-startup-screen t)

(defun my/ghostel-startup ()
  (let ((buf (ghostel))
        (banner (expand-file-name "banner.txt" my/config-dir)))
    (when (file-readable-p banner)
      (with-current-buffer buf
        (ghostel-send-string
         (format
          " clear; printf '\\033[38;2;195;64;67m'; cat %s; printf '\\033[0m'\n"
          (shell-quote-argument banner)))))))

(add-hook 'emacs-startup-hook #'my/ghostel-startup)

;;; ghostel.el ends here
