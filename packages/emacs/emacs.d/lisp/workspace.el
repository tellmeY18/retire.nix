;;; workspace.el --- Tab-bar workspaces for project domains  -*- lexical-binding: t; -*-

(require 'project)

(tab-bar-mode 1)
(tab-bar-history-mode 1)

(setq tab-bar-close-button-show nil
      tab-bar-new-button-show nil
      tab-bar-show 1
      tab-bar-tab-hints t)

;; Register known projects so project.el can find them
(dolist (dir '("~/Documents/ohcnetwork" "~/Documents/10bedicu"))
  (let ((dir (expand-file-name dir)))
    (when (file-directory-p dir)
      (project--add-project-to-front dir))))

;; --- Tab navigation by index (leader 1..9) ---

(defun my/tab-select (n)
  (lambda () (interactive) (tab-bar-select-tab n)))

(dotimes (n 9)
  (define-key evil-normal-state-map
    (kbd (format "<leader>%d" (1+ n)))
    (my/tab-select (1+ n))))

(define-key evil-normal-state-map (kbd "<leader>]") #'tab-bar-switch-to-next-tab)
(define-key evil-normal-state-map (kbd "<leader>[") #'tab-bar-switch-to-prev-tab)
(define-key evil-normal-state-map (kbd "<leader>tn") #'tab-bar-new-tab)
(define-key evil-normal-state-map (kbd "<leader>tk") #'tab-bar-close-tab)

;; --- Workspace builders ---

(defun my/workspace-make (name dir &optional fn)
  "Create a new tab workspace named NAME rooted at DIR, run FN in it."
  (let ((target (expand-file-name dir)))
    (tab-bar-new-tab)
    (tab-bar-rename-tab name)
    (when (file-directory-p target)
      (project-switch-project target
        (lambda (d)
          (if fn (funcall fn d) (dired d)))))))

(defun my/workspace-ohc ()
  (interactive)
  (my/workspace-make "ohc" "~/Documents/ohcnetwork"))

(defun my/workspace-10b ()
  (interactive)
  (my/workspace-make "10b" "~/Documents/10bedicu"))

(defun my/workspace-jira ()
  (interactive)
  (my/workspace-make "jira" "~/Documents/ohcnetwork/jira/atlassian-mcp-server"
    (lambda (dir)
      (let ((default-directory dir))
        (ghostel '(4))))))

;; --- Startup: build all workspaces, replacing the single-term banner ---

(defun my/workspace-startup ()
  ;; Tab 1: ohcnetwork — project root
  (tab-bar-rename-tab "ohc")
  (let ((ohc (expand-file-name "~/Documents/ohcnetwork")))
    (when (file-directory-p ohc)
      (project-switch-project ohc (lambda (d) (dired d)))))
  ;; Tab 2: 10bedicu
  (my/workspace-make "10b" "~/Documents/10bedicu")
  ;; Tab 3: Jira MCP — ghostel terminal in the server dir
  (my/workspace-make "jira" "~/Documents/ohcnetwork/jira/atlassian-mcp-server"
    (lambda (dir)
      (let ((default-directory dir))
        (ghostel '(4))))))

;; Replace the single-banner startup with workspace startup
(remove-hook 'emacs-startup-hook #'my/ghostel-startup)
(add-hook 'emacs-startup-hook #'my/workspace-startup)
