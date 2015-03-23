;;; pl --- Combinator parsing library for Emacs, similar to Haskell's Parsec

;; Copyright (C) 2015 John Wiegley

;; Author: John Wiegley <jwiegley@gmail.com>
;; Created: 19 Mar 2015
;; Version: 1.0
;; Keywords: parsing lisp devel
;; X-URL: https://github.com/jwiegley/emacs-pl

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Please see the README

(eval-when-compile
  (require 'cl))
(require 'cl-lib)

(defgroup pl nil
  "Combinator parsing library for Emacs, similar to Haskell's Parsec"
  :group 'development)

(defun pl-ch (ch &rest args)
  (if (char-equal (char-after) ch)
      (prog1
          (cond
           ((memq :nil args) nil)
           ((memq :beg args)
            (point))
           ((memq :end args)
            (1+ (point)))
           (t
            (char-to-string ch)))
        (forward-char 1))
    (throw 'failed nil)))

(defun pl-re (regexp &rest args)
  (if (looking-at regexp)
      (prog1
          (cond
           ((memq :nil args) nil)
           ((memq :beg args)
            (match-beginning 0))
           ((memq :end args)
            (match-end 0))
           ((memq :group args)
            (let ((group
                   (loop named outer for arg on args
                         when (eq (car arg) :group) do
                         (return-from outer (cadr arg)))))
              (if group
                  (match-string group)
                (error "Unexpected regexp :group %s" group))))
           (t
            (match-string 0)))
        (goto-char (match-end 0)))
    (throw 'failed nil)))

(defsubst pl-str (str &rest args)
  (pl-re (regexp-quote str)))

(defsubst pl-num (num &rest args)
  (pl-re (regexp-quote (number-to-string num))))

(defmacro pl-or (&rest parsers)
  (let ((outer-sym (make-symbol "outer"))
        (parser-sym (make-symbol "parser")))
    `(loop named ,outer-sym for ,parser-sym in ',parsers
           finally (throw 'failed nil) do
           (catch 'failed
             (return-from ,outer-sym (eval ,parser-sym))))))

(defmacro pl-try (&rest forms)
  `(catch 'failed ,@forms))

(defalias 'pl-and 'progn)
(defalias 'pl-parse 'pl-try)

(defmacro pl-until (parser &optional &key skip)
  `(catch 'done
     (while (not (eobp))
       (catch 'failed
         (throw 'done ,parser))
       ,(if skip
            `(,skip 1)
          `(forward-char 1)))))

(defmacro pl-many (&rest parsers)
  (let ((final-sym (make-symbol "final"))
        (result-sym (make-symbol "result"))
        (parsers-sym (make-symbol "parsers")))
    `(let ((,parsers-sym ',parsers)
           ,result-sym
           ,final-sym)
       (while (and ,parsers-sym
                   (setq ,result-sym
                         (catch 'failed
                           (list (eval (car ,parsers-sym))))))
         (push (car ,result-sym) ,final-sym)
         (setq ,parsers-sym (cdr ,parsers-sym)))
       (nreverse ,final-sym))))

(provide 'pl)

;;; pl.el ends here
