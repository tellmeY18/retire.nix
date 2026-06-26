;;; markdown.el --- Markdown editing (GitHub-Flavored)  -*- lexical-binding: t; -*-

(dolist (entry '(("\\.md\\'"       . gfm-mode)
                 ("\\.markdown\\'" . gfm-mode)))
  (add-to-list 'auto-mode-alist entry))

(with-eval-after-load 'markdown-mode
  (setq markdown-fontify-code-blocks-natively t)
  (setq markdown-header-scaling t)
  (setq markdown-asymmetric-header t)
  (setq markdown-list-indent-width 2))

(add-hook 'markdown-mode-hook #'visual-line-mode)

(defun my/markdown-hide-markup (hide)
  (let ((inhibit-message t)
        (arg (if hide 1 -1)))
    (markdown-toggle-markup-hiding arg)
    (markdown-toggle-url-hiding arg)))

(defun my/markdown-setup-wysiwyg ()
  (my/markdown-hide-markup t)
  (add-hook 'evil-insert-state-entry-hook
            (lambda () (my/markdown-hide-markup nil)) nil t)
  (add-hook 'evil-insert-state-exit-hook
            (lambda () (my/markdown-hide-markup t)) nil t))

(add-hook 'markdown-mode-hook #'my/markdown-setup-wysiwyg)

;;; markdown.el ends here
