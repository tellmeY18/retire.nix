;;; ide.el --- LSP (eglot), tree-sitter major modes, mode switching  -*- lexical-binding: t; -*-

(require 'envrc)
(envrc-global-mode 1)

(with-eval-after-load 'envrc
  (advice-add 'envrc--show-summary :override
              (lambda (_result directory)
                (message "direnv: loaded (%s)"
                         (abbreviate-file-name (directory-file-name directory))))))

(dolist (hook '(rust-ts-mode-hook
                typescript-ts-mode-hook
                tsx-ts-mode-hook
                js-ts-mode-hook
                nix-mode-hook
                go-ts-mode-hook
                elixir-ts-mode-hook
                heex-ts-mode-hook
                json-ts-mode-hook
                python-ts-mode-hook
                bash-ts-mode-hook
                dockerfile-ts-mode-hook
                docker-compose-ts-mode-hook
                qml-mode-hook))
  (add-hook hook #'eglot-ensure))

(with-eval-after-load 'eglot
  (setq eglot-code-action-indications '(margin))

  (dolist (entry '(((elixir-ts-mode heex-ts-mode) "elixir-ls")
                   (docker-compose-ts-mode "docker-compose-langserver" "--stdio")
                   (qml-mode "qmlls")))
    (add-to-list 'eglot-server-programs entry)))

(define-derived-mode docker-compose-ts-mode yaml-ts-mode "Compose"
  "Major mode for Docker Compose files: YAML tree-sitter + compose LSP.")

(dolist (entry '(("\\.rs\\'"      . rust-ts-mode)
                 ("\\.ts\\'"      . typescript-ts-mode)
                 ("\\.tsx\\'"     . tsx-ts-mode)
                 ("\\.js\\'"      . js-ts-mode)
                 ("\\.json\\'"    . json-ts-mode)
                 ("\\.exs?\\'"    . elixir-ts-mode)
                 ("mix\\.lock\\'" . elixir-ts-mode)
                 ("\\.heex\\'"    . heex-ts-mode)
                 ("\\.go\\'"      . go-ts-mode)
                 ("\\.py\\'"      . python-ts-mode)
                 ("\\.\\(sh\\|bash\\)\\'" . bash-ts-mode)
                 ("\\.qml\\'"     . qml-mode)
                 ("\\(?:^\\|/\\)\\(?:docker-\\)?compose\\(?:\\.[^/]*\\)?\\.ya?ml\\'"
                  . docker-compose-ts-mode)
                 ("\\(?:^\\|/\\)\\(?:Containerfile\\|Dockerfile\\)\\(?:\\.[^/]*\\)?\\'"
                  . dockerfile-ts-mode)
                 ("\\.dockerfile\\'" . dockerfile-ts-mode)))
  (add-to-list 'auto-mode-alist entry))

(require 'eldoc-box)

(defun my/change-major-mode ()
  (interactive)
  (funcall (intern (completing-read
                    "Major mode: " obarray
                    (lambda (s) (and (commandp s)
                                     (string-suffix-p "-mode" (symbol-name s))))
                    t))))

;;; ide.el ends here
