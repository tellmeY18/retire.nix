;;; keybindings.el --- which-key, leader map, eglot/neotree keys  -*- lexical-binding: t; -*-

(which-key-mode)

(evil-define-key '(normal visual) 'global
  (kbd "<leader>e")        #'neotree-toggle
  (kbd "<leader>f")        #'consult-fd
  (kbd "<leader><leader>") #'project-find-file
  (kbd "<leader>bb")       #'my/consult-buffer-no-special
  (kbd "<leader>bB")       #'consult-buffer
  (kbd "<leader>gp")       #'consult-ripgrep
  (kbd "<leader>gl")       #'consult-line
  (kbd "<leader>d")        #'consult-flymake
  (kbd "<leader>s")        #'consult-imenu
  (kbd "<leader>S")        #'consult-eglot-symbols
  (kbd "<leader>ca")       #'eglot-code-actions
  (kbd "<leader>cr")       #'eglot-rename
  (kbd "<leader>cf")       #'my/change-major-mode
  (kbd "<leader>tt")       #'my/ghostel-fresh
  (kbd "<leader>tb")       #'ghostel-list-buffers
  (kbd "<leader>ts")       #'my/ghostel-split
  (kbd "<leader>tv")       #'my/ghostel-vsplit
  (kbd "<leader>GG")       #'magit-status
  (kbd "<leader>Gc")       #'magit-log-buffer-file
  (kbd "<leader>Gdo")      #'magit-diff-working-tree
  (kbd "<leader>Gdc")      #'magit-mode-bury-buffer
  (kbd "<leader>xd")       #'flymake-show-buffer-diagnostics
  (kbd "<leader>xn")       #'flymake-goto-next-error
  (kbd "<leader>xp")       #'flymake-goto-prev-error
  (kbd "<leader>wt")       #'my/toggle-title-bar
  (kbd "<leader>hf")       #'describe-function
  (kbd "<leader>hv")       #'describe-variable
  (kbd "<leader>hk")       #'describe-key)

(defun my/global-text-scale-reset ()
  (interactive)
  (let ((last-command-event ?0))
    (global-text-scale-adjust 1)))

(global-set-key (kbd "C-+") #'global-text-scale-adjust)
(global-set-key (kbd "C--") #'global-text-scale-adjust)
(global-set-key (kbd "C-=") #'my/global-text-scale-reset)

(with-eval-after-load 'eglot
  (evil-define-key 'normal eglot-mode-map
    (kbd "K")  #'eldoc-box-help-at-point
    (kbd "gd") #'xref-find-definitions
    (kbd "gr") #'xref-find-references
    (kbd "gi") #'eglot-find-implementation
    (kbd "gt") #'eglot-find-typeDefinition)
  (evil-set-command-property 'eglot-find-implementation :jump t)
  (evil-set-command-property 'eglot-find-typeDefinition :jump t))

(with-eval-after-load 'neotree
  (evil-define-key 'normal neotree-mode-map
    (kbd "RET") #'neotree-enter
    (kbd "TAB") #'neotree-quick-look
    (kbd "o")   #'neotree-enter
    (kbd "s")   #'neotree-enter-vertical-split
    (kbd "S")   #'neotree-enter-horizontal-split
    (kbd "g")   #'neotree-refresh
    (kbd "H")   #'neotree-hidden-file-toggle
    (kbd "R")   #'neotree-change-root
    (kbd "c")   #'neotree-create-node
    (kbd "d")   #'neotree-delete-node
    (kbd "r")   #'neotree-rename-node
    (kbd "q")   #'neotree-hide))

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "SPC b"   "buffer"
    "SPC g"   "search"
    "SPC c"   "code"
    "SPC G"   "git"
    "SPC G d" "diff"
    "SPC x"   "diagnostics"
    "SPC h"   "help"
    "SPC t"   "terminal"
    "SPC w"   "window"
    "SPC w t" "toggle title-bar"))

;;; keybindings.el ends here
