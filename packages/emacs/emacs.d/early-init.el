;;; early-init.el --- writable-state redirects for a store-baked config -*- lexical-binding: t; -*-

(defun my/xdg (env fallback)
  (let ((v (getenv env)))
    (if (and v (file-name-absolute-p v)) v (expand-file-name fallback))))

(defvar my/config-dir user-emacs-directory
  "The read-only Nix-store directory this config was loaded from.")

(defconst my/cache-dir (expand-file-name "emacs/" (my/xdg "XDG_CACHE_HOME" "~/.cache")))
(defconst my/state-dir (expand-file-name "emacs/" (my/xdg "XDG_STATE_HOME" "~/.local/state")))
(defconst my/data-dir  (expand-file-name "emacs/" (my/xdg "XDG_DATA_HOME"  "~/.local/share")))

(dolist (d (list my/cache-dir my/state-dir my/data-dir))
  (make-directory d t))

(setq user-emacs-directory my/state-dir)

(when (and (fboundp 'startup-redirect-eln-cache)
           (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (startup-redirect-eln-cache
   (convert-standard-filename (expand-file-name "eln-cache/" my/cache-dir))))

(let ((backup   (expand-file-name "backup/"    my/cache-dir))
      (autosave (expand-file-name "auto-save/" my/cache-dir))
      (lockdir  (expand-file-name "lock/"      my/cache-dir)))
  (dolist (d (list backup autosave lockdir)) (make-directory d t))
  (setq backup-directory-alist         `(("." . ,backup))
        auto-save-file-name-transforms `((".*" ,autosave t))
        lock-file-name-transforms      `((".*" ,lockdir  t))
        auto-save-list-file-prefix     (expand-file-name "auto-save-list/.saves-" my/cache-dir)))

(setq recentf-save-file     (expand-file-name "recentf"   my/state-dir)
      savehist-file         (expand-file-name "savehist"  my/state-dir)
      save-place-file       (expand-file-name "places"    my/state-dir)
      bookmark-default-file (expand-file-name "bookmarks" my/state-dir)
      project-list-file     (expand-file-name "projects"  my/state-dir))

(dolist (d (list (expand-file-name "auto-save-list/" my/cache-dir)
                 (expand-file-name "transient/"      my/cache-dir)
                 (expand-file-name "url/"            my/cache-dir)))
  (make-directory d t))
(setq url-configuration-directory (expand-file-name "url/" my/cache-dir)
      transient-levels-file  (expand-file-name "transient/levels.el"  my/cache-dir)
      transient-values-file  (expand-file-name "transient/values.el"  my/cache-dir)
      transient-history-file (expand-file-name "transient/history.el" my/cache-dir))

(setq nsm-settings-file (expand-file-name "network-security.data" my/data-dir)
      custom-file       (expand-file-name "custom.el" my/state-dir))
(when (file-exists-p custom-file) (load custom-file nil t))

(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(add-hook 'after-init-hook
          (lambda ()
            (load (expand-file-name "init" my/config-dir) nil t))
          t)

;;; early-init.el ends here
