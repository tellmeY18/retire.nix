;;; completion.el --- Vertico/marginalia/orderless/consult completion UI  -*- lexical-binding: t; -*-

(vertico-mode 1)
(marginalia-mode 1)
(setq completion-styles '(orderless basic)
      completion-category-overrides '((file (styles partial-completion))))

(require 'corfu)
(setq corfu-auto t
      corfu-auto-prefix 2
      corfu-auto-delay 0.1
      corfu-cycle t
      corfu-quit-no-match 'separator)
(global-corfu-mode 1)
(require 'corfu-popupinfo)
(corfu-popupinfo-mode 1)

(require 'cape)
(add-to-list 'completion-at-point-functions #'cape-dabbrev t)
(add-to-list 'completion-at-point-functions #'cape-file t)

(defun my/consult-buffer-pair-with-mode (buffer)
  (let ((name (buffer-name buffer))
        (mode (symbol-name (buffer-local-value 'major-mode buffer))))
    (cons (concat name
                  (propertize (concat "  " mode) 'face 'completions-annotations))
          buffer)))

(with-eval-after-load 'consult
  (setq consult-source-buffer
        (plist-put consult-source-buffer :items
                   (lambda () (consult--buffer-query
                               :sort 'visibility
                               :as #'my/consult-buffer-pair-with-mode))))
  (setq consult-source-project-buffer
        (plist-put consult-source-project-buffer :items
                   (lambda ()
                     (when-let* ((root (consult--project-root)))
                       (consult--buffer-query
                        :sort 'visibility :directory root
                        :as #'my/consult-buffer-pair-with-mode))))))

(defun my/consult-buffer-no-special ()
  (interactive)
  (let ((consult-buffer-filter (cons "\\`\\*" consult-buffer-filter)))
    (consult-buffer)))

(setq xref-show-xrefs-function #'consult-xref
      xref-show-definitions-function #'consult-xref)

;;; completion.el ends here
