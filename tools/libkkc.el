;;; libkkc.el --- Emacs client interface to libkkc -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Daiki Ueno <ueno@gnu.org>

;; Author: Daiki Ueno <ueno@gnu.org>
;; Keywords: Japanese

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'dbus-codegen)

(dbus-codegen-define-proxy libkkc-server
			   "\
<node>
  <interface name=\"org.du_a.Kkc.Server\">
    <method name=\"CreateContext\">
      <arg type=\"s\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"DestroyContext\">
      <arg type=\"s\" name=\"object_path\" direction=\"in\"/>
    </method>
  </interface>
</node>"
			   "org.du_a.Kkc.Server")

(dbus-codegen-define-proxy libkkc-context
			   "\
<node>
  <interface name=\"org.du_a.Kkc.Context\">
    <method name=\"ProcessKeyEvent\">
      <arg type=\"u\" name=\"keyval\" direction=\"in\"/>
      <arg type=\"u\" name=\"keycode\" direction=\"in\"/>
      <arg type=\"u\" name=\"modifiers\" direction=\"in\"/>
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"ProcessCommandEvent\">
      <arg type=\"s\" name=\"command\" direction=\"in\"/>
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"Reset\">
    </method>
    <method name=\"HasOutput\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"PeekOutput\">
      <arg type=\"s\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"PollOutput\">
      <arg type=\"s\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"ClearOutput\">
    </method>
    <property type=\"s\" name=\"Input\" access=\"read\"/>
    <property type=\"i\" name=\"InputCursorPos\" access=\"read\"/>
    <property type=\"u\" name=\"InputMode\" access=\"readwrite\"/>
    <property type=\"u\" name=\"PunctuationStyle\" access=\"readwrite\"/>
    <property type=\"b\" name=\"AutoCorrect\" access=\"readwrite\"/>
  </interface>
</node>"
			   "org.du_a.Kkc.Context")

(dbus-codegen-define-proxy libkkc-candidate-list
			   "\
<node>
  <interface name=\"org.du_a.Kkc.CandidateList\">
    <method name=\"SelectAt\">
      <arg type=\"u\" name=\"index_in_page\" direction=\"in\"/>
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"Select\">
    </method>
    <method name=\"First\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"Next\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"Previous\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"CursorUp\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"CursorDown\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"PageUp\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"PageDown\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"Get\">
      <arg type=\"i\" name=\"index\" direction=\"in\"/>
      <arg type=\"s\" name=\"midasi\" direction=\"out\"/>
      <arg type=\"b\" name=\"okuri\" direction=\"out\"/>
      <arg type=\"s\" name=\"text\" direction=\"out\"/>
      <arg type=\"s\" name=\"annotation\" direction=\"out\"/>
    </method>
    <signal name=\"Populated\">
    </signal>
    <signal name=\"Selected\">
      <arg type=\"s\" name=\"midasi\"/>
      <arg type=\"b\" name=\"okuri\"/>
      <arg type=\"s\" name=\"text\"/>
      <arg type=\"s\" name=\"annotation\"/>
    </signal>
    <property type=\"i\" name=\"CursorPos\" access=\"read\"/>
    <property type=\"i\" name=\"Size\" access=\"read\"/>
    <property type=\"u\" name=\"PageStart\" access=\"read\"/>
    <property type=\"u\" name=\"PageSize\" access=\"read\"/>
    <property type=\"b\" name=\"Round\" access=\"read\"/>
    <property type=\"b\" name=\"PageVisible\" access=\"read\"/>
  </interface>
</node>"
			   "org.du_a.Kkc.CandidateList")

(dbus-codegen-define-proxy libkkc-segment-list
			   "\
<node>
  <interface name=\"org.du_a.Kkc.SegmentList\">
    <method name=\"Get\">
      <arg type=\"i\" name=\"index\" direction=\"in\"/>
      <arg type=\"s\" name=\"input\" direction=\"out\"/>
      <arg type=\"s\" name=\"output\" direction=\"out\"/>
    </method>
    <method name=\"FirstSegment\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"LastSegment\">
      <arg type=\"b\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"NextSegment\">
    </method>
    <method name=\"PreviousSegment\">
    </method>
    <method name=\"GetOutput\">
      <arg type=\"s\" name=\"result\" direction=\"out\"/>
    </method>
    <method name=\"GetInput\">
      <arg type=\"s\" name=\"result\" direction=\"out\"/>
    </method>
    <property type=\"i\" name=\"CursorPos\" access=\"read\"/>
    <property type=\"i\" name=\"Size\" access=\"read\"/>
  </interface>
</node>"
			   "org.du_a.Kkc.SegmentList")

(defvar libkkc-server nil)
(defvar libkkc-context nil)
(defvar libkkc-candidates nil)
(defvar libkkc-segments nil)

(defvar libkkc-sentence-overlay nil)
(defvar libkkc-segment-overlay nil)

(defvar libkkc-candidates-visible nil)
(defconst libkkc-candidates-labels '(?a ?s ?d ?f ?j ?k ?l))

(defvar libkkc-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map " " 'libkkc-command-next-candidate)
    (define-key map "\r" 'libkkc-command-commit)
    (define-key map [return] 'libkkc-command-commit)
    (define-key map "\177" 'libkkc-command-delete)
    (define-key map "\C-i" 'libkkc-command-shrink-segment)
    (define-key map "\C-o" 'libkkc-command-expand-segment)
    (define-key map "\C-f" 'libkkc-command-next-segment)
    (define-key map "\C-b" 'libkkc-command-previous-segment)
    (define-key map [right] 'libkkc-command-next-segment)
    (define-key map [left] 'libkkc-command-previous-segment)
    map))

(defun libkkc-command-next-candidate ()
  (interactive)
  (libkkc-context-process-command-event libkkc-context "next-candidate"))

(defun libkkc-command-commit ()
  (interactive)
  (libkkc-context-process-command-event libkkc-context "commit"))

(defun libkkc-command-delete ()
  (interactive)
  (libkkc-context-process-command-event libkkc-context "delete"))

(defun libkkc-command-shrink-segment ()
  (interactive)
  (libkkc-context-process-command-event libkkc-context "shrink-segment"))

(defun libkkc-command-expand-segment ()
  (interactive)
  (libkkc-context-process-command-event libkkc-context "expand-segment"))

(defun libkkc-command-next-segment ()
  (interactive)
  (libkkc-context-process-command-event libkkc-context "next-segment"))

(defun libkkc-command-previous-segment ()
  (interactive)
  (libkkc-context-process-command-event libkkc-context "previous-segment"))

(defun libkkc-redisplay ()
  ;; Reset overlays.
  (when (overlayp libkkc-sentence-overlay)
    (let ((sentence-start (overlay-start libkkc-sentence-overlay))
	  (sentence-end (overlay-end libkkc-sentence-overlay)))
      (when sentence-start
	(delete-region sentence-start sentence-end))
      (delete-overlay libkkc-sentence-overlay)))
  (when (overlayp libkkc-segment-overlay)
    (delete-overlay libkkc-segment-overlay))
  ;; Commit if the context has output.
  (if (libkkc-context-has-output libkkc-context)
      (let ((output (libkkc-context-poll-output libkkc-context)))
	(insert output))
    ;; Render preedit text, if available.
    (let ((sentence-start (point)))
      (if (<= 0 (libkkc-segment-list-cursor-pos libkkc-segments))
	  (let ((cursor-pos (libkkc-segment-list-cursor-pos libkkc-segments))
		(size (libkkc-segment-list-retrieve-size-property
		       libkkc-segments)))
	    (dotimes (index size)
	      (let ((segment (libkkc-segment-list-get libkkc-segments index))
		    (segment-start (point)))
		(insert (nth 1 segment))
		(when (= index cursor-pos)
		  (if (overlayp libkkc-segment-overlay)
		      (move-overlay libkkc-segment-overlay
				    segment-start (point))
		    (setq libkkc-segment-overlay
			  (make-overlay segment-start (point)))
		    (overlay-put libkkc-segment-overlay
				 'face 'highlight))))))
	(insert (libkkc-context-input libkkc-context)))
      (if (overlayp libkkc-sentence-overlay)
	  (move-overlay libkkc-sentence-overlay sentence-start (point))
	(setq libkkc-sentence-overlay
	      (make-overlay sentence-start (point)))
	(overlay-put libkkc-sentence-overlay 'face 'underline))))
  nil)

(defun libkkc-deactivate-current-input-method-function ()
  (when (and (equal current-input-method "japanese-libkkc")
	     libkkc-context)
    (libkkc-server-destroy-context
     libkkc-server
     (libkkc-context-path libkkc-context))))

(defun libkkc-loop ()
  (let ((converting t))
    (while converting
      (let* ((overriding-terminal-local-map libkkc-keymap)
	     (input-method-function nil)
	     (help-char nil)
	     (keyseq (read-key-sequence nil))
	     (cmd (lookup-key libkkc-keymap keyseq)))
	(if (commandp cmd)
	    (setq converting (call-interactively cmd))
	  (if (and (stringp keyseq)
		   (= (length keyseq) 1)
		   (< ?  (aref keyseq 0) ?\x7F))
	      (setq converting
		    (libkkc-context-process-key-event libkkc-context
						      (aref keyseq 0) 0 0))
	    (libkkc-context-reset libkkc-context)
	    (setq converting nil)))
	(libkkc-redisplay)
	(unless converting
	  (libkkc-context-reset libkkc-context)
	  ;; KEYSEQ is not defined in KKC keymap.
	  ;; Let's put the event back.
	  (setq unread-input-method-events
		(append (string-to-list (this-single-command-raw-keys))
			unread-input-method-events)))))))

(defun libkkc-input-method-function (c)
  (if (and libkkc-candidates-visible
	   (memq c libkkc-candidates-labels))
      (let ((labels libkkc-candidates-labels)
	    (index 0))
	(while labels
	  (if (eq c (car labels))
	      (setq labels nil))
	  (setq index (1+ index)
		labels (cdr labels)))
	(libkkc-candidate-list-select-at libkkc-candidates index))
    (if (libkkc-context-process-key-event libkkc-context c 0 0)
	(progn
	  (libkkc-redisplay)
	  (libkkc-loop))
      (list c))))

(defun libkkc-activate (_input-method)
  (make-local-variable 'libkkc-server)
  (setq libkkc-server
	(libkkc-server-create :session
			      "org.du_a.Kkc.Server"
			      "/org/du_a/Kkc/Server"))
  (let ((context-object-path
	 (libkkc-server-create-context libkkc-server)))
    (make-local-variable 'libkkc-context)
    (setq libkkc-context
	  (libkkc-context-create :session
				 "org.du_a.Kkc.Server"
				 context-object-path))
    (make-local-variable 'libkkc-candidates)
    (setq libkkc-candidates
	  (libkkc-candidate-list-create :session
					"org.du_a.Kkc.Server"
					(format "%s/CandidateList"
						context-object-path)))
    (make-local-variable 'libkkc-segments)
    (setq libkkc-segments
	  (libkkc-segment-list-create :session
				      "org.du_a.Kkc.Server"
				      (format "%s/SegmentList"
					      context-object-path)))
    (make-local-variable 'libkkc-sentence-overlay)
    (setq libkkc-sentence-overlay nil)
    (make-local-variable 'libkkc-segment-overlay)
    (setq libkkc-segment-overlay nil)
    (make-local-variable 'libkkc-candidates-visible)
    (setq libkkc-candidates-visible nil)
    (libkkc-candidate-list-register-populated-signal
     libkkc-candidates
     (lambda (_proxy)
       (setq libkkc-candidates-visible t)))
    (libkkc-candidate-list-register-selected-signal
     libkkc-candidates
     (lambda (_proxy &rest _args)
       (setq libkkc-candidates-visible nil))))
  (setq input-method-function
	#'libkkc-input-method-function)
  (setq deactivate-current-input-method-function
	#'libkkc-deactivate-current-input-method-function))

(register-input-method
 "japanese-libkkc" "Japanese"
 'libkkc-activate ""
 "Japanese input method by Roman transliteration and Kana-Kanji conversion.")

(provide 'libkkc)

;;; libkkc.el ends here
