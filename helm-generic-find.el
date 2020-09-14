(require 'helm)
(require 'helm-files)
(require 's)
(require 'dash)

;; The aim of this is to be able to
;; instantiate a helm with a custom backend
;; command

(defun helm-generic-cmd ()
  (buffer-local-value 'generic-find-cmd (get-buffer helm-buffer)))

;;;###autoload
(defun helm-generic-find (cmd)
  (interactive (list (read-string-hist "cmd: ")))
  (let* ((default-directory (pwd))
         (generic-find-cmd cmd)
         (generic-find-cmd-slug (slugify cmd))
         (generic-find-source-name (concat "helm generic " generic-find-cmd-slug))
         (generic-find-buffer-name (concat "*helm-" generic-find-cmd-slug "*")))
    (helm :sources (list (helm-build-async-source generic-find-source-name
                           :candidates-process (defun helm-generic-find--do-candidate-process ()
                                                 (let* ((cmd-args (-filter 'identity
                                                                           (nconc (cmd2list (helm-generic-cmd))
                                                                                  (list
                                                                                   ;; Pattern is provided by helm when the function is run
                                                                                   helm-pattern))))
                                                        ;; helm generic find process === name
                                                        (proc (apply 'start-file-process "helm generic find process" helm-buffer cmd-args)))
                                                   (prog1 proc
                                                     (set-process-sentinel
                                                      (get-buffer-process helm-buffer)
                                                      #'(lambda (process event)
                                                          (helm-process-deferred-sentinel-hook
                                                           process event (helm-default-directory)))))))
                           :filter-one-by-one 'identity
                           ;; Don't let there be a minimum. it's annoying
                           :requires-pattern 0
                           :action 'helm-find-file-or-marked
                           :candidate-number-limit 9999))
          :buffer generic-find-buffer-name)))

(provide 'helm-generic-find)