;;; modeline.el --- Lualine-style mode line with evil state tag  -*- lexical-binding: t; -*-

(setq evil-mode-line-format nil)

(defface my/ml-evil-normal   '((t :foreground "#16161D" :background "#7E9CD8" :weight bold))
  "Mode-line tag face for evil normal state.")
(defface my/ml-evil-insert   '((t :foreground "#1F1F28" :background "#98BB6C" :weight bold))
  "Mode-line tag face for evil insert state.")
(defface my/ml-evil-visual   '((t :foreground "#1F1F28" :background "#957FB8" :weight bold))
  "Mode-line tag face for evil visual state.")
(defface my/ml-evil-replace  '((t :foreground "#1F1F28" :background "#FFA066" :weight bold))
  "Mode-line tag face for evil replace state.")
(defface my/ml-evil-operator '((t :foreground "#1F1F28" :background "#C0A36E" :weight bold))
  "Mode-line tag face for evil operator-pending state.")
(defface my/ml-evil-emacs    '((t :foreground "#1F1F28" :background "#E46876" :weight bold))
  "Mode-line tag face for evil emacs state (warns: vim keys are off).")

(defvar my/evil-state-tags
  '((normal   "NORMAL"  my/ml-evil-normal)
    (insert   "INSERT"  my/ml-evil-insert)
    (visual   "VISUAL"  my/ml-evil-visual)
    (replace  "REPLACE" my/ml-evil-replace)
    (operator "O-PEND"  my/ml-evil-operator)
    (motion   "MOTION"  my/ml-evil-normal)
    (emacs    "EMACS"   my/ml-evil-emacs))
  "Alist mapping an evil state to its mode-line LABEL and FACE.")

(defun my/evil-mode-line-tag ()
  (when (bound-and-true-p evil-state)
    (let* ((entry (cdr (assq evil-state my/evil-state-tags)))
           (label (or (car entry) (upcase (symbol-name evil-state))))
           (face  (or (cadr entry) 'my/ml-evil-normal)))
      (propertize (format " %s " label) 'face face))))

(defun my/ml-vc-branch ()
  (when (and vc-mode (stringp vc-mode))
    (let ((branch (replace-regexp-in-string "\\`[[:space:]]*[A-Za-z]+[-:@!?^]" ""
                                             vc-mode)))
      (concat "  " (string-trim branch)))))

(defun my/ml-coding-system ()
  (symbol-name (coding-system-base (or buffer-file-coding-system 'undecided))))

(defun my/ml-file-format ()
  (pcase (coding-system-eol-type (or buffer-file-coding-system 'undecided))
    (0 "unix") (1 "dos") (2 "mac") (_ "")))

(setq-default
 mode-line-format
 '("%e"
   (:eval (my/evil-mode-line-tag))
   " "
   (:eval (my/ml-vc-branch))
   (flymake-mode flymake-mode-line-format)
   "  "
   mode-line-modified
   " "
   mode-line-buffer-identification
   mode-line-format-right-align
   (:eval (my/ml-coding-system))
   "  "
   (:eval (my/ml-file-format))
   "  "
   mode-name
   "  "
   "%p"
   "  "
   "%l:%c"
   "  "))

;;; modeline.el ends here
