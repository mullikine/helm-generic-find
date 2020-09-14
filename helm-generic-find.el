(require 'helm)
(require 'helm-files)
(require 's)
(require 'dash)

;; The aim of this is to be able to
;; instantiate a helm with a custom backend
;; command

(defun helm-generic-find (cmd &optional action)
  (interactive (list (read-string-hist "cmd: ")))
  (if (not action) (setq action 'helm-find-file-or-marked))
  (let* ((default-directory (my/pwd))
         (generic-find-cmd cmd)
         (generic-find-cmd-slug (slugify cmd))
         (generic-find-source-name (concat "helm generic " generic-find-cmd-slug))
         (generic-find-func-name (concat "helm-generic-" generic-find-cmd-slug "--do-candidate-process"))
         (generic-find-process-name (concat "helm generic " generic-find-cmd-slug " proc"))
         (generic-find-buffer-name (concat "*helm-" generic-find-cmd-slug "*")))
    (helm :sources (list (helm-build-async-source generic-find-source-name
                           :candidates-process (defun helm-generic-find--do-candidate-process ()
                                                 (let* ((cmd-args (-filter 'identity
                                                                           (nconc (cmd2list
                                                                                   (buffer-local-value 'generic-find-cmd (get-buffer helm-buffer)))
                                                                                  (list
                                                                                   ;; Pattern is provided by helm when the function is run
                                                                                   helm-pattern))))
                                                        (proc (apply 'start-file-process generic-find-process-name helm-buffer cmd-args)))
                                                   (prog1 proc
                                                     (set-process-sentinel
                                                      (get-buffer-process helm-buffer)
                                                      #'(lambda (process event)
                                                          (helm-process-deferred-sentinel-hook
                                                           process event (helm-default-directory)))))))
                           :filter-one-by-one 'identity
                           ;; Don't let there be a minimum. it's annoying
                           :requires-pattern 0
                           :action action
                           :candidate-number-limit 9999))
          :buffer generic-find-buffer-name)))

(provide 'helm-generic-find)