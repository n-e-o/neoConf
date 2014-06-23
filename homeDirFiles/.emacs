;;
;; Emacs configuration
;;

(defconst xemacs (string-match "XEmacs" emacs-version)
  "non-nil iff XEmacs, nil otherwise")

;; ####################### Options #########################

(prefer-coding-system 'utf-8)           ; set utf-8 as base coding system
(setq inhibit-startup-message t)        ; don't show the GNU splash screen
(setq frame-title-format "%b")          ; titlebar shows buffer's name
(global-font-lock-mode t)               ; syntax highlighting
(setq font-lock-maximum-decoration t)   ; max decoration for all modes
(setq transient-mark-mode 't)           ; highlight selection
(setq line-number-mode 't)              ; line number
(setq column-number-mode 't)            ; column number
(when (display-graphic-p)
  (progn
    (scroll-bar-mode nil)               ; no scroll bar
    (menu-bar-mode nil)                 ; no menu bar
    (tool-bar-mode nil)                 ; no tool bar
    (mouse-wheel-mode t)))              ; enable mouse wheel

(setq delete-auto-save-files t)         ; delete unnecessary autosave files
(setq delete-old-versions t)            ; delete oldversion file
(setq normal-erase-is-backspace-mode t) ; make delete work as it should
(fset 'yes-or-no-p 'y-or-n-p)           ; 'y or n' instead of 'yes or no'
(setq default-major-mode 'text-mode)    ; change default major mode to text
(setq ring-bell-function 'ignore)       ; turn the alarm totally off
(setq make-backup-files nil)            ; no backupfile

;; FIXME: wanted 99.9% of the time, but can cause your death 0.1% of
;; the time =). Todo: save buffer before reverting
;(global-auto-revert-mode t)            ; auto revert modified files

(auto-image-file-mode)                  ; to see picture in emacs
(setq ido-enable-flex-matching t)       ; flex matching
(setq ido-everywhere t)                 ; ido activated everywhere by default
(ido-mode t)                            ; enable ido
(show-paren-mode t)			; match parenthesis
(setq-default indent-tabs-mode nil)	; don't use fucking tabs to indent


;; ################### Custom functions ####################

;; Compilation

(setq compile-command "")

(defun build ()
  (interactive)
  (when (string-equal compile-command "")
    (while (file-readable-p "Makefile")
      (cd ".."))
    (setq compile-command (concat "cd " (cwd) " && gmake"))

  (recompile)))


;; Edition

(defun c-switch-hh-cc ()
  (interactive)
  (let ((other
         (let ((file (buffer-file-name)))
           (if (string-match "\\.hh$" file)
               (replace-regexp-in-string "\\.hh$" ".cc" file)
             (replace-regexp-in-string "\\.cc$" ".hh" file)))))
    (find-file other)))


;; Shell

(defun cwd ()
  (replace-regexp-in-string "Directory " "" (pwd)))

(defun insert-shell-shebang ()
  (interactive)
  (when (buffer-file-name)
    (goto-char (point-min))
    (insert "#!/bin/bash\n\n")))

;; C/C++

(defun insert-header-guard ()
  (interactive)
  (save-excursion
    (when (buffer-file-name)
        (let*
            ((name (file-name-nondirectory buffer-file-name))
             (macro (replace-regexp-in-string
                     "\\." "_"
                     (replace-regexp-in-string
                      "-" "_"
                      (upcase name)))))
          (goto-char (point-min))
          (insert "#ifndef " macro "\n")
          (insert "# define " macro "\n\n")
          (goto-char (point-max))
          (insert "\n#endif\n")))))

(defun rbegin ()
  (min (point) (mark)))

(defun rend ()
  (max (point) (mark)))

(defun c-insert-fixme (&optional msg)
  (interactive "sFixme: ")
  (save-excursion
    (end-of-line)
    (when (not (looking-back "^\s*"))
      (insert " "))
    (insert "// FIXME")
    (when (not (string-equal msg ""))
      (insert ": " msg))))

(defun c-insert-debug (&optional msg)
  (interactive)
  (when (not (looking-at "\W*$"))
    (beginning-of-line)
    (insert "\n")
    (line-move -1))
  (c-indent-line)
  (insert "std::cerr << \"\" << std::endl;")
  (backward-char 15))

(defun c-insert-block (&optional r b a)
  (interactive "P")
  (unless b (setq b ""))
  (unless a (setq a ""))
  (if r
      (progn
        (save-excursion
          (goto-char (rbegin))
          (beginning-of-line)
          (insert "\n")
          (line-move -1)
          (insert b "{")
          (c-indent-line))
        (save-excursion
          (goto-char (- (rend) 1))
          (end-of-line)
          (insert "\n}" a)
          (c-indent-line)
          (line-move -1)
          (end-of-line))
        (indent-region (rbegin) (rend)))
    (progn
        (beginning-of-line)

        (setq begin (point))

        (insert b "{\n")
        (end-of-line)
        (insert "\n}" a)

        (indent-region begin (point))

        (line-move -1)
        (end-of-line))))

(defun c-insert-braces (&optional r)
  (interactive "P")
  (c-insert-block r))

(defun c-insert-ns (name r)
  (interactive "sName: \nP")
  (c-insert-block r (concat "namespace " name "\n")))

(defun c-insert-switch (value r)
  (interactive "sValue: \nP")
  (c-insert-block r (concat "switch (" value ")\n")))

(defun c-insert-if (c r)
  (interactive "sCondition: \nP")
  (c-insert-block r (concat "if (" c ")\n")))

(defun c-insert-class (name)
  (interactive "sName: ")
  (c-insert-block () (concat "class " name "\n") ";")
  (insert "public:")
  (c-indent-line)
  (insert "\n")
  (c-indent-line))

;; HOOKS

; Delete trailing whitespaces on save
(add-hook 'write-file-hooks 'delete-trailing-whitespace)
; Auto insert C/C++ header guard
(add-hook 'find-file-hooks
	  (lambda ()
	    (when (and (memq major-mode '(c-mode c++-mode)) (equal (point-min) (point-max)) (string-match ".*\\.hh?" (buffer-file-name)))
	      (insert-header-guard)
	      (goto-line 3)
	      (insert "\n"))))
(add-hook 'find-file-hooks
	  (lambda ()
	    (when (and (memq major-mode '(c-mode c++-mode)) (equal (point-min) (point-max)) (string-match ".*\\.cc?" (buffer-file-name)))
	      (insert-header-inclusion))))

(add-hook 'find-file-hooks
	  (lambda ()
	    (when (and (memq major-mode '(sh-mode)) (equal (point-min) (point-max)))
	      (insert-shell-shebang))))

; Start code folding mode in C/C++ mode
(add-hook 'c-mode-common-hook (lambda () (hs-minor-mode 1)))

;; Ruby

(add-to-list 'load-path "/usr/share/emacs/site-lisp/ruby-mode/")
(autoload 'ruby-mode "ruby-mode"
  "Mode for editing ruby source files" t)

;; file extensions
(add-to-list 'auto-mode-alist '("\\.l$" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.y$" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.ll$" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.yy$" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.xcc$" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.xhh$" . c++-mode))
(add-to-list 'auto-mode-alist '("\\.pro$" . sh-mode)) ; Qt .pro files
(add-to-list 'auto-mode-alist '("configure$" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.rb$" . ruby-mode))
(add-to-list 'auto-mode-alist '("Drakefile$" . ruby-mode))

;; Font

(setq default-font-size 105)

(defun set-font-size (&optional size)
  "Set the font size to SIZE (default: default-font-size)."
  (interactive "nSize: ")
  (unless size
    (setq size default-font-size))
  (set-face-attribute 'default nil :height size))

(set-face-attribute 'default nil :height 100)

(defun reset-font-size ()
  (interactive)
  (set-font-size))

(defun find-next (c l)
    (if (< c (car l))
        (car l)
      (if (cdr l)
          (find-next c (cdr l))
        (car l))))

(defun inc-font-size ()
  (interactive)
  (let ((sizes '(60 75 90 105 120 135 170 280))
        (current (face-attribute 'default :height)))
    (let ((new (find-next current sizes)))
      (set-font-size new)
      (message (int-to-string new)))))

(set-font-size)

;; Ido

;; tab means tab, i.e. complete. Not "open this file", stupid.
(setq ido-confirm-unique-completion t)
;; If the file doesn't exist, do try to invent one from a transplanar
;; directory. I just want a new file.
(setq ido-auto-merge-work-directories-length -1)

;; BINDINGS

;; BINDINGS :: font

(global-set-key [(control +)] 'inc-font-size)
(global-set-key [(control -)] 'dec-font-size)
(global-set-key [(control =)] 'reset-font-size)

;; BINDINGS :: windows

(global-unset-key [(control s)])
(global-set-key [(control s) (v)] 'split-window-horizontally)
(global-set-key [(control s) (h)] 'split-window-vertically)
(global-set-key [(control s) (d)] 'delete-window)
(global-set-key [(control s) (o)] 'delete-other-windows)

;; BINDINGS :: ido

(global-set-key [(control b)] 'ido-switch-buffer)

;; BINDINGS :: isearch
(global-set-key [(control f)] 'isearch-forward-regexp)  ; search regexp
(global-set-key [(control r)] 'query-replace-regexp)    ; replace regexp
(define-key
  isearch-mode-map
  [(control n)]
  'isearch-repeat-forward)                              ; next occurence
(define-key
  isearch-mode-map
  [(control p)]
  'isearch-repeat-backward)                             ; previous occurence
(define-key
  isearch-mode-map
  [(control z)]
  'isearch-cancel)                                      ; quit and go back to start point
(define-key
  isearch-mode-map
  [(control f)]
  'isearch-exit)                                        ; abort
(define-key
  isearch-mode-map
  [(control r)]
  'isearch-query-replace)                               ; switch to replace mode
(define-key
  isearch-mode-map
  [S-insert]
  'isearch-yank-kill)                                   ; paste
(define-key
  isearch-mode-map
  [(control e)]
  'isearch-toggle-regexp)                               ; toggle regexp
(define-key
  isearch-mode-map
  [(control l)]
  'isearch-yank-line)                                   ; yank line from buffer
(define-key
  isearch-mode-map
  [(control w)]
  'isearch-yank-word)                                   ; yank word from buffer
(define-key
  isearch-mode-map
  [(control c)]
  'isearch-yank-char)                                   ; yank char from buffer

;; BINDINGS :: C/C++

(require 'cc-mode)

(define-key
  c-mode-base-map
  [(control c) (w)]
  'c-switch-hh-cc)                                      ; switch between .hh and .cc
(define-key
  c-mode-base-map
  [(control c) (f)]
  'hs-hide-block)                                       ; fold code
(define-key
  c-mode-base-map
  [(control c) (s)]
  'hs-show-block)                                       ; unfold code
(define-key
  c-mode-base-map
  [(control c) (control n)]
  'c-insert-ns)                                         ; insert namespace
(define-key
  c-mode-base-map
  [(control c) (control s)]
  'c-insert-switch)                                     ; insert switch
(define-key
  c-mode-base-map
  [(control c) (control i)]
  'c-insert-if)                                         ; insert if
(define-key
  c-mode-base-map
  [(control c) (control b)]
  'c-insert-braces)                                     ; insert braces
(define-key
  c-mode-base-map
  [(control c) (control f)]
  'c-insert-fixme)                                      ; insert fixme
(define-key
  c-mode-base-map
  [(control c) (control d)]
  'c-insert-debug)                                      ; insert debug
(define-key
  c-mode-base-map
  [(control c) (control l)]
  'c-insert-class)                                      ; insert class

;; BINDINGS :: misc

(global-set-key [(control c) (control c)]
                'comment-region)
(if (display-graphic-p)
    (global-set-key [(control z)] 'undo)                ; undo only in graphic mode
)
(global-set-key [(control a)] 'mark-whole-buffer)       ; select whole buffer
(global-set-key [(control return)] 'dabbrev-expand)     ; auto completion
(global-set-key [C-home] 'beginning-of-buffer)          ; go to the beginning of buffer
(global-set-key [C-end] 'end-of-buffer)                 ; go to the end of buffer
(global-set-key [(meta g)] 'goto-line)                  ; goto line #
(global-set-key [A-left] 'windmove-left)                ; move to left windnow
(global-set-key [A-right] 'windmove-right)              ; move to right window
(global-set-key [A-up] 'windmove-up)                    ; move to upper window
(global-set-key [A-down] 'windmove-down)
(global-set-key [(control c) (c)] 'build)
(global-set-key [(control c) (e)] 'next-error)
(global-set-key [(control tab)] 'other-window)          ; Ctrl-Tab = Next buffer
(global-set-key [C-S-iso-lefttab]
                '(lambda () (interactive)
                   (other-window -1)))                  ; Ctrl-Shift-Tab = Previous buffer
(global-set-key [(control delete)]
                'kill-word)                             ; kill word forward
(global-set-key [(meta ~)] 'ruby-command)               ; run ruby command
(global-set-key [f5] 'build)
(global-set-key [f6] 'next-error)

;; COLORS

(set-background-color "black")
(set-foreground-color "white")
(set-cursor-color "Orangered")
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

;; Qt
(font-lock-add-keywords 'c++-mode
			'(("foreach\\|forever\\|emit" . 'font-lock-keyword-face)))

;; Lisp mode

(require 'lisp-mode)

(define-key
  lisp-mode-shared-map
  [(control c) (control c)]
  'comment-region)                                      ; comment


;; Compilation

(setq compilation-window-height 14)
(setq compilation-scroll-output t)

;; make C-Q RET insert a \n, not a ^M

(defadvice insert-and-inherit (before ENCULAY activate)
  (when (eq (car args) ?)
    (setcar args ?\n)))

;; Tuareg mode

;; (load "/usr/share/emacs/site-lisp/tuareg-mode/tuareg.el" t)
;; (add-to-list 'load-path "/usr/share/doc/tuareg-mode-1.44.3")



; Use UTF8 in tuareg mode

;; (add-hook 'tuareg-interactive-mode-hook
;; 	  (lambda ()
;;            (prefer-coding-system 'utf-8)
;;             ))

(setq auto-mode-alist (cons '("\\.ml\\w?" . tuareg-mode) auto-mode-alist))

(desktop-load-default)
(desktop-read)

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(after-save-hook (quote (executable-make-buffer-file-executable-if-script-p)))
 '(ido-auto-merge-work-directories-length -1)
 '(ido-confirm-unique-completion t)
 '(ido-create-new-buffer (quote always))
 '(ido-everywhere t)
 '(ido-ignore-buffers (quote ("\\`\\*breakpoints of.*\\*\\'" "\\`\\*stack frames of.*\\*\\'" "\\`\\*gud\\*\\'" "\\`\\*locals of.*\\*\\'" "\\` ")))
 '(ido-mode (quote both) nil (ido))
 '(require-final-newline t))

(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq-default ispell-program-name "aspell")
(setq-default gdb-many-windows t)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
