;; these are things I put in my .emacs
;; David Kotz dfk@cs.dartmouth.edu

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Add bibtex mode
(autoload 'bibtex-mode "bibtex" "Bibtex mode" t)
; and redefine some of the key bindings
; and add my favorite extra fields 
(setq bibtex-mode-hook
   '(lambda ()
;;    (define-key bibtex-mode-map "\C-c\C-\'" 'bibtex-remove-double-quotes)
      (define-key bibtex-mode-map [?\C-c ?\C-'] 'bibtex-remove-double-quotes)
      (define-key bibtex-mode-map "\C-c\C-eI" 'bibtex-InBook)
      (define-key bibtex-mode-map "\C-c\C-e\C-i" 'bibtex-InProceedings)
      (define-key bibtex-mode-map "\C-c\C-eM" 'bibtex-Manual)
      (define-key bibtex-mode-map "\C-c\C-e\C-m" 'bibtex-Misc)
      (setq bibtex-mode-user-optional-fields '("URL" "keyword" "private" "comment"))
      )
   )

(setq auto-mode-alist (cons (cons "\\.bib$" 'bibtex-mode) auto-mode-alist))

