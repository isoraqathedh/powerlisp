;;;; powerlisp.lisp
;;;; A useful utility for Linux powerusers.
;;;; Copyright © 2018 Lucas Vieira <lucasvieira@lisp.com.br>
;;;;
;;;; Licensed under the MIT License.
;;;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;;;; this software and associated documentation files (the "Software"), to deal in
;;;; the Software without restriction, including without limitation the rights to
;;;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
;;;; the Software, and to permit persons to whom the Software is furnished to do so,
;;;; subject to the following conditions:
;;;; 
;;;; The above copyright notice and this permission notice shall be included in all
;;;; copies or substantial portions of the Software.
;;;; 
;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
;;;; FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
;;;; COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
;;;; IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;;;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.    


;;; Important stuff:
;;; This script assumes that you are using certain default programs and settings,
;;; which are the ones I am using:
;;; - SBCL as Common Lisp implementation
;;; - Font: Fixed Semicondensed 9
;;; - Black-and-white theme
;;; - DuckDuckGo as default search engine
;;; - dmenu as launcher
;;; - Firefox as browser
;;; - Zeal as documentation reader
;;; Do not forget to change those to your liking. Hack this file as much as you can.

;;; Run this file using:
;;; $ sbcl --script powerlisp.lisp
;;; Notice that I try not to rely on Quicklisp for anything. This is intentional
;;; so that the shortcut launches faster.


;; ============================================
;; Look and programs customization

(defparameter *input-font*   "xft:LucidaTypewriter:size=8")
(defparameter *input-bg*     "#000000")
(defparameter *input-fg*     "#bbbbbb")
(defparameter *input-sel-bg* "#ffffff")
(defparameter *input-sel-fg* "#000000")
(defparameter *default-search-engine* 'duckduckgo)
(defparameter *browser-command* "/usr/bin/firefox")
(defparameter *notify-command* "/usr/bin/notify-send")
(defparameter *zeal-command* "/usr/bin/zeal")
(defparameter *dmenu-command* "/usr/bin/dmenu")
(defparameter *input-params*
  (list "-b"
	"-fn" *input-font*
	"-nb" *input-bg*
	"-nf" *input-fg*
	"-sb" *input-sel-bg*
	"-sf" *input-sel-fg*
	"-l" "0"))
     
				
;; ============================================
;; Websites, search engines, services

(defparameter *favorite-websites*
  '((reddit     . "https://reddit.com")
    (twitter    . "https://twitter.com")
    (netflix    . "https://netflix.com")
    ;;(hooktube   . "https://hooktube.com")
    (youtube    . "https://youtube.com")
    (protonmail . "https://mail.protonmail.com/login")
    (gitlab     . "https://gitlab.com")
    (linkedin   . "https://linkedin.com")
    (hackernews . "https://news.ycombinator.com")
    (slashdot   . "https://slashdot.org")
    (instagram  . "https://instagram.com")
    (whatsapp   . "https://web.whatsapp.com")
    (cplusplus  . "http://cplusplus.com")))

(defparameter *search-engines*
  '((duckduckgo   ("https://duckduckgo.com/?q="))
    (startpage    ("https://startpage.com/do/search?language=english&cat=web&query="))
    ;;(hooktube     ("https://hooktube.com/results?search_query="))
    (youtube     ("https://youtube.com/results?search_query="))
    (twitter      ("https://twitter.com/search?q="))
    (wikipedia    ("https://en.wikipedia.org/w/index.php?search="
		   "&title=Special%3ASearch"))
    (github       ("https://github.com/search?utf8=%E2%9C%93&q="
	           "&type="))
    (wolfram      ("https://www.wolframalpha.com/input/?i="))
    (cplusplus    ("http://cplusplus.com/search.do?q="))
    (urbandict    ("https://urbandictionary.com/define.php?term="))
    (knowyourmeme ("http://knowyourmeme.com/search?q="))))

(defparameter *zeal-docs*
  '((c           . "c")
    (c++         . "cpp")
    (common-lisp . "lisp")
    (css         . "css")
    (emacs-lisp  . "elisp")
    (erlang      . "erlang")
    (go          . "go")
    (haskell     . "haskell")
    (html        . "html")
    (js          . "javascript")
    (julia       . "julia")
    (latex       . "latex")
    (markdown    . "markdown")
    (php         . "php")
    (processing  . "processing")
    (rust        . "rust")
    (bootstrap   . "bootstrap")
    (jquery      . "jquery")))

(defparameter *subcommands* nil)

;; ============================================
;; Command calling helpers

(defun *build-command* (command-parts &optional (query nil))
  "Build a command using its first part, its next part
and a query, if it is a search engine. If said query exists,
it is sandwiched between the first and last parts."
  (concatenate 'string
	       (car command-parts)
	       query
	       (apply #'concatenate 'string (cdr command-parts))))

(defun send-notification (&rest text)
  "Sends a notification to the desktop."
  #+SBCL (sb-ext:run-program *notify-command* text))

(defun request-input (prompt options)
  "Requests input using your input method. You may provide
selection options. Yields the user input as a string."
  #+SBCL
  (let* ((process (sb-ext:run-program *dmenu-command*
				      (append (list "-p" prompt)
					      *input-params*)
				      :input :stream
				      :output :stream
				      :wait nil))
	 (process-input  (sb-ext:process-input process))
	 (process-output (sb-ext:process-output process))
	 (input-options (mapcar (lambda (x)
				  (string-downcase (format nil "~a~%" x)))
				options)))
    ;; Submit list of elements to process input
    (format process-input "~a" (apply #'concatenate 'string input-options))
    (finish-output process-input)
    (close process-input)
    ;; Await process end and dump what we read
    (sb-ext:process-wait process)
    (when (listen process-output)
      (read-line process-output))))

(defun powerlisp-call-browser (&rest website)
  "Effectively calls the browser with the given website as argument."
  #+SBCL (sb-ext:run-program *browser-command* website :wait nil))

(defun call-docs (docset-result search-query)
  "Calls Zeal with the documentation we need."
  #+SBCL (sb-ext:run-program
	  *zeal-command*
	  (list (concatenate 'string
			     docset-result
			     ":"
			     search-query))
	  :wait nil))

(defun powerlisp-call-external (program-path &rest arguments)
  "Calls an external command and does not wait for the process to
finish. `program-path` needs to be an absolute path to the binary.
`arguments` is a list of strings, where each string is an argument.
The arguments need to be isolated, with no whitespace inbetween."
  (when (and (stringp program-path)
	     (every #'stringp arguments))
    #+SBCL (sb-ext:run-program
	    program-path
	    arguments
	    :wait nil)))


;; ============================================
;; User input processing

(defun atom-convert (output-string)
  "Convert a user-received string to an atom.
This might need security tweaks..."
  (intern
   (string-trim " " (string-upcase output-string))))
  
(defun match-output (output-string options)
  "Match a string given from the output of a process to a list
of options. Yields both the atom and the value associated with the
string on the referred list of options."
  (let* ((input-atom (atom-convert output-string))
	 (associated-value (cdr (assoc input-atom options))))
    (values input-atom associated-value)))

(defun build-search-query (query engine)
  "Builds a search query for the given search engine. Yields the
prepared URL as a string."
  (let ((engine-query-format (assoc engine *search-engines*)))
    (if (null engine-query-format)
	(send-notification "POWERLISP: ERROR"
			   (format nil "Cannot find search engine \"~a\""
				   engine))
        (let ((query-begin (caadr engine-query-format))
	      (query-rest  (cdadr engine-query-format)))
	  (concatenate 'string
		       query-begin
		       query
		       (apply #'concatenate 'string query-rest))))))

(defun options-to-list (options)
  "Converts the atoms which are associated with certain URLs in an alist
to a single list of those atoms."
  (loop for opt in options collect (car opt)))

;; ============================================
;; User interface management

(defun request-search ()
  "Prompts the search menu. Asks for the search engine to
be used, and for the query to be searched."
  (let ((command-result
	 (request-input "Search engine?"
			(options-to-list *search-engines*))))
    (multiple-value-bind (engine-atom engine-query-info)
	(match-output command-result *search-engines*)
      (if (null engine-query-info)
	  (when (not (null engine-atom))
	    (send-notification
	     "POWERLISP: ERROR"
	     (format nil "Unknown search engine \"~a\"" engine-atom)))
	  (let ((search-input (request-input "Search target?" nil)))
	    (when (not (null search-input))
	      (send-notification
	       "POWERLISP SEARCH"
	       (format nil "Searching for \"~a\" in ~a..."
		       search-input engine-atom))
	      (powerlisp-call-browser (build-search-query search-input engine-atom))))))))

(defun request-docs ()
  "Prompts the documentation search menu. Asks for a docset
and then searches the entry on it."
  (let ((docset-result
	 (request-input "Docset?"
			(options-to-list *zeal-docs*))))
    (multiple-value-bind (docset-atom docset-prefix)
	(match-output docset-result *zeal-docs*)
      (if (null docset-prefix)
	  (when (not (null docset-atom))
	    (send-notification
	     "POWERLISP: ERROR"
	     (format nil "Unknown docset \"~a\"" docset-atom)))
	  (let ((search-input (request-input "Search target?" nil)))
	    (when (not (null search-input))
	      (send-notification
	       "POWERLISP DOC SEARCH"
	       (format nil "Searching for \"~a\" in ~a DOCS..."
		       search-input docset-atom))
	      (call-docs docset-prefix search-input)))))))

;; ============================================
;; USER CONFIGURATION API
;; Add them to ~/.powerlisp or to ~/.config/powerlisp.lisp.
;; Use the following functions to add stuff.

(defun powerlisp-add-favorite (atom url)
  "Add a single favorite website to favorites list."
  (setf *favorite-websites*
	(append *favorite-websites*
		(list (cons atom url)))))

(defun powerlisp-add-search-engine (atom query-parts)
  "Add a single search engine to search engines list.
The query-parts parameter must be a list of query components,
with the first one coming before the query value, and the rest
coming after the query value. These strings are concatenated
in this order."
  (setf *search-engines*
	(append *search-engines*
		(list (list atom query-parts)))))

(defun powerlisp-add-multi-favorites (favorites-list)
  "Adds many favorites to the favorites list.
Format of the list must follow the format for the favorites list.
Using this function instead of powerlisp-add-favorite is recommended
when you have many websites."
  (setf *favorite-websites*
	(append *favorite-websites*
		favorites-list)))

(defun powerlisp-add-multi-search-engines (engines-list)
  "Adds many search engines  to the search engines list.
Format of the list must follow the format for the search engines list.
Using this function instead of powerlisp-add-search-engine is recommended
when you have many engines."
  (setf *search-engines*
	(append *search-engines*
		engines-list)))


(defun powerlisp-add-command (command callback)
  "Adds a command to Powerlisp.
command is the command atom, callback must be a zero-arguments function."
  (when (functionp callback)
    (setf *subcommands*
	  (append (list (cons command callback))
		  *subcommands*))))

(defun powerlisp-add-multi-commands (commands-list)
  "Adds many commands to Powerlisp at once.
The list of commands must be a list comprised of consed
atoms + procedures. It is important to maintain this structure in order
for this to work."
  (when (every (lambda (entry) (functionp (cdr entry)))
	       commands-list)
    (setf *subcommands*
	  (append commands-list *subcommands*))))


(defun powerlisp-add-documentation (command prefix-string)
  "Adds a new documentation set to the end of Powerlisp's
documentations. The command is an identification atom, while the prefix-string
is the string to preceed the doc search query."
  (setf *zeal-docs*
	(append (list (cons command prefix-string))
		*zeal-docs*)))

(defun powerlisp-spawn-menu (prompt alist)
  "Spawns an input menu with the given prompt, and offers an alist
of values. This function yields two values: an atom equivalent to the user
input and, if the option selected is valid, yields the associated value
as well; if not, yields nil instead."
  (multiple-value-bind (atom assoc-value)
      (match-output (request-input prompt
				   (options-to-list alist))
		    alist)
    (when assoc-value (values atom assoc-value))))

(defun powerlisp-request-user-input (&optional (prompt "input?"))
  "Spawns an input menu with no options. The value returned is a
plain string containing what the user typed. One can customize
the prompt by feeding it to this function."
  (request-input prompt nil))

(defmacro with-powerlisp-options-menu ((prompt alist) &body body)
  "Calls an options menu using an alist. If the input matches any of
the values on the alist, the input is bound as an atom to `option`,
and the associated value is bound to `assoc-value`. The body is then
executed."
  `(multiple-value-bind (option assoc-value)
       (powerlisp-spawn-menu ,prompt ,alist)
     (when assoc-value ,@body)))

(defun powerlisp-notify (text &optional (title "POWERLISP"))
  "Sends a notification to the desktop. One can optionally setup the
notification title."
  (send-notification "POWERLISP" text))


;; ============================================
;; User configuration loading

;; Magic for loading default configuration
(when (probe-file "~/.powerlisp")
  (load "~/.powerlisp"))

(when (probe-file "~/.config/powerlisp.lisp")
  (load "~/.config/powerlisp.lisp"))

;; ============================================
;; Build list of common commands

(powerlisp-add-command 'docs   #'request-docs)
(powerlisp-add-command 'search #'request-search)

(defun request-command (command-atom)
  "Dispatches the requested command."
  (let ((function (cdr (assoc command-atom *subcommands*))))
    (when (functionp function)
      (funcall function))))


(defun run-powerlisp ()
  "Prompts the favorites menu. Asks for the user to type one of the
favorite websites prompted, or a command (such as search), or even
for text which will be converted to a search query."
  (let* ((subcommands-list (options-to-list *subcommands*))
	 (command-result
	  (request-input "Website, command, plain search?"
			 (append subcommands-list
				 (options-to-list *favorite-websites*)))))
    (multiple-value-bind (command-atom command-url)
	(match-output command-result *favorite-websites*)
      (cond ((null command-url)
	     (cond ((member command-atom subcommands-list)
		    (request-command command-atom))
		   (t (when (not (null command-result))
			(send-notification
			 "POWERLISP PLAIN SEARCH"
			 (format nil "Searching for \"~a\"..."
				 command-result))
                        ;; TODO: I want to be able to just type
                        ;; websites on the future.
			(powerlisp-call-browser (build-search-query
				       command-result
				       *default-search-engine*))))))
	    (t (send-notification
		"POWERLISP"
		(format nil "Opening ~a~%(~a)..."
			command-atom
			command-url))
	       (powerlisp-call-browser command-url))))))


(run-powerlisp) ;; Magic happens here.
