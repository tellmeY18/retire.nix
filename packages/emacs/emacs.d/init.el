;;; init.el --- Load the modular config from lisp/  -*- lexical-binding: t; -*-

(dolist (m '("ui" "evil" "modeline" "completion" "ide" "markdown" "ghostel" "keybindings" "workspace"))
  (load (expand-file-name (concat "lisp/" m) my/config-dir) nil t))

;;; init.el ends here
