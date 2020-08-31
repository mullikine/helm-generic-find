;;; helm-generic-find.el --- helm binding for FZF

;; Copyright (C) 2011 Free Software Foundation, Inc.

;; Author: Ivan Buda Mandura (ivan.mandura93@gmail.com)

;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))
;; Keywords: helm fzf

;;; Commentary:

;;; Code:

(require 'helm)
(require 'helm-files)
(require 's)
(require 'dash)

(defcustom helm-generic-find-executable "fzf"
  "Default executable for fzf"
  :type 'stringp
  :group 'helm-generic-find)

(defun helm-generic-find--project-root ()
  (cl-loop for dir in '(".git/" ".hg/" ".svn/" ".git")
           when (locate-dominating-file default-directory dir)
           return it))

(defset helm-generic-find-source
  (helm-build-async-source "fzf"
    :candidates-process 'helm-generic-find--do-candidate-process
    :filter-one-by-one 'identity
    ;; Don't let there be a minimum. it's annoying
    :requires-pattern 0
    :action 'helm-find-file-or-marked
    :candidate-number-limit 9999))

(defun helm-generic-find--do-candidate-process ()
  (let* ((cmd-args (-filter 'identity (list helm-generic-find-executable
                                            "--tac"
                                            "--no-sort"
                                            "-f"
                                            helm-pattern)))
         (proc (apply 'start-file-process "helm-generic-find" helm-buffer cmd-args)))
    (prog1 proc
      (set-process-sentinel
       (get-buffer-process helm-buffer)
       #'(lambda (process event)
         (helm-process-deferred-sentinel-hook
          process event (helm-default-directory)))))))

;;;###autoload
(defun helm-generic-find (directory)
  (interactive "D")
  (let ((default-directory directory))
    (helm :sources '(helm-generic-find-source)
          :buffer "*helm-generic-find*")))

(defun helm-generic-find-project-root ()
  (interactive)
  (let ((default-directory (helm-generic-find--project-root)))
    (unless default-directory
      (error "Could not find the project root."))
    (helm :sources '(helm-generic-find-source)
          :buffer "*helm-generic-find*")))

(provide 'helm-generic-find)

;;; helm-generic-find.el ends here
