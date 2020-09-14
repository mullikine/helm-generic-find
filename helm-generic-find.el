(require 'helm)
(require 'helm-files)
(require 's)
(require 'dash)

;; The aim of this is to be able to instantiate a helm with a custom backend command

(defcustom helm-generic-find-cmd "echo yo"
  "Default executable for fzf"
  :type 'stringp
  :group 'helm-generic-find)

(defset helm-generic-find-source
  (helm-build-async-source "fzf"
    :candidates-process 'helm-generic-find--do-candidate-process
    :filter-one-by-one 'identity
    ;; Don't let there be a minimum. it's annoying
    :requires-pattern 0
    :action 'helm-find-file-or-marked
    :candidate-number-limit 9999))

(defun helm-generic-find--do-candidate-process ()
  (let* ((cmd-args (-filter 'identity
                            (nconc (cmd2list helm-generic-find-cmd)
                                   (list
                                    ;; Pattern is provided by helm when the function is run
                                    helm-pattern))))
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

(provide 'helm-generic-find)