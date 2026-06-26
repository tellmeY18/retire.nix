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

;;; ui.el ends here
