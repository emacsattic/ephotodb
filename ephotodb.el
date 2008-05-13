;;; ephotodb.el --- provides ephotodb, the Emacs Photo Database:
;;               interaction with a SQL database containing film,
;;               negative, and print information for wet-process
;;               photographers and other fossils

;; Copyright (C) 2008 Markus Hoenicka

;; Author: Markus Hoenicka <markus@mhoenicka.de>

;; This file is NOT part of GNU emacs.

;; This is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;;; todo
;; nothing at this time

;; -------------------------------------------------------------------
;; Commentary
;; -------------------------------------------------------------------

;;; Prerequisites

;;  ephotodb stores data in a SQL database. You need some sort of
;;  database engine with a client that runs in batch mode without
;;  asking for passwords interactively. SQLite (http://www.sqlite.org)
;;  is a standalone, zero-administration database engine which is well
;;  suited for our purposes. However, heavyweights like MySQL
;;  (http://www.mysql.com) work just fine. The instructions below
;;  assume that you use one of these engines. It is fairly
;;  straightforward to adapt the instructions to other engines.


;;; Installation and operation

;;  1. Either put this file into a directory that's already in your
;;     load path (e.g. /usr/local/share/emacs/site-lisp), or add
;;     whatever directory it's already in to your load path. For
;;     example,
;;
;;       (add-to-list 'load-path "/home/me/mystuff/elisp/")
;;
;;  2. Add the following to the end of your .emacs file exactly as
;;     shown:
;;
;;       (require 'ephotodb)
;;
;;  3. Specify the command to run your database client in your .emacs
;;     file. ephotodb appends a query string to the string you
;;     provide, so you'll have to include all other options that the
;;     client may need. When using SQLite, it is as simple as:
;;
;;       (setq photo-dbclient-command "sqlite3 PATH/TO/DATABASE")
;;
;;     Use the following for MySQL (in one line), replacing the
;;     uppercase words with appropriate values:
;;
;;       (setq photo-dbclient-command "mysql -u USERNAME
;;       --password=PASSWD -D DATABASE -e")
;;
;;
;;  5. To create an empty database for use with ephotodb, use the
;;     SQL script (you'll find this either in the tarball, or you can
;;     extract and uncomment the script from the comments a couple of
;;     screens below) in your shell like this, using the same command
;;     line client and database as above:
;;
;;       sqlite3 DATABASE < photo.sql
;;
;;     The SQL script should be sufficiently generic to work with most
;;     database engines.
;;
;;  6. To start a session, run M-x photo-init. This initializes the
;;     completion lists used to select films, negatives, or prints
;;     based on their names. To re-synchronize the completion lists
;;     after adding, editing, or removing entries, run the command
;;     again anytime.
;;
;;  7. To add entries, use M-x photo-create-film, M-x
;;     photo-create-negative, and M-x photo-create-print. These
;;     commands will create new buffers with simple text forms that
;;     you have to fill in. It may be convenient to have all three
;;     buffers open at the same time, e.g. in different frames. Leave
;;     fields blank if they do not apply, or if you don't know the
;;     data. To commit the data to the database, run M-x photo-add in
;;     the appropriate buffer. You can reuse the buffers right away to
;;     enter the next item, changing only the variant fields. It is
;;     probably best to first add a film, then all negatives of this
;;     film, each one followed by its prints. Use the mouse to copy
;;     and paste film and negative names for further use.
;;
;;  8. To display the information concerning a print, negative, or
;;     film, run M-x photo-display-print, M-x photo-display-negative,
;;     and M-x photo-display-film, respectively. Tab completion is
;;     available in the minibuffer to select an existing item. The
;;     information about a print includes the associated negative and
;;     film info. Along the same lines, the information about a
;;     negative includes the associated film info.
;;
;;  9. To display all prints made from a particular negative, run M-x
;;     photo-list-prints-of-negative. To display all prints made from
;;     a film, use M-x photo-list-prints-of-film accordingly. Tab
;;     completion is available in the minibuffer to select an existing
;;     item.
;;
;; 10. The photo-display-* and photo-list-* commands have
;;     *-from-region equivalents. Instead of entering a name at the
;;     prompt, mark an item name in any of the buffers before running the
;;     appropriate command to select an item.
;;
;; 11. The command M-x photo-find-negatives uses a keyword to find
;;     negatives which use this keyword in either the location or the
;;     description field.
;;
;; 12. To edit an item, run M-x photo-edit-print, M-x
;;     photo-edit-negative, or M-x photo-edit-film as appropriate. Tab
;;     completion to select an existing item is available. Alter the
;;     displayed values as appropriate. You'll notice that you can't
;;     change the id value in the first line. This value is required
;;     to match your copy of the dataset with the one in the
;;     database. To commit the altered values, run M-x photo-update in
;;     the appropriate buffer.
;;
;; 13. To delete entries from your database, use M-x
;;     photo-delete-print, M-x photo-delete-cascade-negative, or M-x
;;     photo-delete-cascade-film. The latter two functions take care
;;     of removing all associated prints, or all associated negatives
;;     and prints, respectively. If for some reason you want to remove
;;     a film or a negative without removing the dependent items
;;     (usually you don't want to do this!), use M-x photo-delete-film
;;     and M-x photo-delete-negative instead.
;;
;; 14. There are two ways to display scans of prints,
;;     negatives, or films in a photo-output buffer: 
;;     - run M-x photo-show-images to display the referenced images
;;       inline. Run M-x photo-hide-images to display the path again
;;     - move point into the filename and run M-x browse-url or a
;;       related function, e.g. browse-url-firefox, to display the
;;       image in a web browser. This is convenient for scans which
;;       are too large to display properly within an Emacs frame.




;;; Database concepts and item naming suggestions

;; The suggested naming scheme is not mandatory as ephotodb does not
;; depend on this particular scheme. However, it is convenient to have
;; all required information encoded in the names.

;; A film is either a 35mm/roll film, or one set of sheet films that
;; were developed together in the same tray, tank, or drum. Use the
;; development date in ISO notation, followed by a two-digit sequence
;; starting at 01 each day to name films, e.g. 20080430-01

;; A negative is a single image on a 35mm/roll film, or one sheet
;; film. Each negative belongs to exactly one film. The negative name
;; is derived from the film name by adding the negative number
;; starting at 01, e.g. 20080430-01-04

;; A print is a negative printed onto photgraphic paper, or (if you
;; prefer) one set of paper/printing/developing conditions for such
;; prints. Each print (or print condition) belongs to exactly one
;; negative. Use the negative name and append a two-digit number
;; starting at 01 for each print, e.g. 20080430-01-04-02

;; Links to scans can be provided for each film, negative, and
;; print. The URLs can either be fully qualified, e.g.
;; file:///usr/home/me/photo/contacts/foo.jpg or they can be composed
;; of a root directory common for all scans and partial paths. To this
;; end, set photo-image-root to e.g. "file:///usr/home/me/photo/", and
;; specify the scan URL as "contacts/foo.jpg". The obvious advantage
;; is that you can move the directory containing your scans without
;; having to change every single URL in the database. All you need to
;; do is to adjust the image root.


;;; Summary of available commands

;; photo-display-print (printname) "Display all information associated
;; with a given print. The print is identified by a SQL regular
;; expression."

;; photo-display-negative (negname) "Display all information associated
;; with a given negative. The negative is identified by a SQL regular
;; expression."

;; photo-display-film (filmname) "Display all information associated with
;; a given film. The film is identified by a SQL regular expression."

;; photo-list-prints-of-negative (negname) "List all prints made from
;; a particular negative. The negative is identified by a SQL regular
;; expression."

;; photo-list-prints-of-film (filmname) "List all prints made from a
;; particular film. The film is identified by a SQL regular
;; expression."

;; photo-list-prints-of-negative-from-region () "List all prints made
;; from a particular negative. The negative is identified by the
;; currently marked region."

;; photo-list-prints-of-film-from-region () "List all prints made from
;; a particular film. The film is identified by the currently marked
;; region."

;; photo-display-print-from-region () "Displays all available information
;; about a particular print. The print is identified by the currently
;; marked region."

;; photo-display-negative-from-region () "Displays all available
;; information about a particular negative. The negative is identified
;; by the currently marked region."

;; photo-display-film-from-region () "Displays all available information
;; about a particular film. The film is identified by the currently
;; marked region."

;; photo-find-negatives (term) "List all negatives whose location or
;; description matches TERM. TERM is a SQL regular expression."

;; photo-create-print () "Creates and displays a template for a new
;; print. The filled-in template can be added to the database using
;; photo-add-print."

;; photo-edit-print (printname) "Retrieves the specified print from
;; the database and displays it in an editable buffer."

;; photo-add-print () "Adds the print information from a buffer
;; created with photo-create-print to the database."

;; photo-update-print () "Commits the changes of the print information
;; in a buffer created with photo-edit-print."

;; photo-create-negative () "Creates and displays a template for a new
;; negative. The filled-in template can be added to the database using
;; photo-add-negative."

;; photo-edit-negative (negname) "Retrieves the specified negative
;; from the database and displays it in an editable buffer."

;; photo-add-negative () "Adds the negative information from a buffer
;; created with photo-create-negative to the database."

;; photo-update-negative () "Commits the changes of the negative
;; information in a buffer created with photo-edit-negative."

;; photo-create-film () "Creates and displays a template for a new
;; film. The filled-in template can be added to the database using
;; photo-add-film."

;; photo-edit-film (filmname) "Retrieves the specified film from the
;; database and displays it in an editable buffer."

;; photo-add-film () "Adds the film information from a buffer created
;; with photo-create-film to the database."
 
;; photo-update-film () "Commits the changes of the film information
;; in a buffer created with photo-edit-film."
 
;; photo-add () "Provides a shorthand for the functions
;; photo-add-film, photo-add-negative, and photo-add-print.

;; photo-update () "Provides a shorthand for the functions
;; photo-update-film, photo-update-negative, and photo-update-print.

;; photo-delete-print (printname) "Delete the specified print from the
;; database."

;; photo-delete-negative (negname) "Delete the specified negative from
;; the database."

;; photo-delete-cascade-negative (negname) "Delete the specified
;; negative, and all prints made from this negative, from the
;; database."

;; photo-delete-film (filmname) "Delete the specified film from the
;; database."

;; photo-delete-cascade-film (filmname) "Delete the specified film,
;; and all negatives and prints associated with this film, from the
;; database."

;; photo-scan-prints-list () "Scan list of prints."

;; photo-scan-negatives-list () "Scan list of negatives."

;; photo-scan-films-list () "Scan list of films."

;; photo-init () "Initialize the completion lists of ephotodb."

;; photo-show-database () "Display the access command of the ephotodb
;; database."

;; photo-show-version () "Display the version of ephotodb."

;; photo-show-manual () "Display the info manual of ephotodb."

;; photo-show-messages () "Show photo messages buffer (stderr output
;; from database clients)."

;; photo-show-images () "Display images in output buffers."

;; photo-hide-images () "Hide images in output buffers."


;; -------------------------------------------------------------------
;; SQL script to generate the required database structure
;; Save the SQL commands to a separate file and uncomment all lines
;; To generate the database, use a command like
;; sqlite3 /home/myname/dbname < script.sql
;; -------------------------------------------------------------------

;; CREATE TABLE t_film (
;;        film_id INTEGER PRIMARY KEY,
;;        film_name TEXT,
;;        film_zonemode INTEGER,
;;        film_speed INTEGER,
;;        film_type TEXT,
;;        film_size TEXT,
;;        film_devdate DATE,
;;        film_developer TEXT,
;;        film_devtime FLOAT,
;;        film_devtemp INTEGER,
;;        film_devdilution TEXT,
;;        film_devmode TEXT,
;;        film_scan TEXT);

;; CREATE UNIQUE INDEX t_film_film_name ON t_film(film_name);

;; CREATE TABLE t_negative (
;;        neg_id INTEGER PRIMARY KEY,
;;        neg_name TEXT UNIQUE,
;;        neg_film_id INTEGER REFERENCES t_film (film_id),
;;        neg_date DATE,
;;        neg_aperture TEXT,
;;        neg_speed TEXT,
;;        neg_filter TEXT,
;;        neg_lens TEXT,
;;        neg_location TEXT,
;;        neg_description TEXT,
;;        neg_scan TEXT);

;; CREATE UNIQUE INDEX t_negative_neg_name ON t_negative(neg_name);

;; CREATE TABLE t_print (
;;        print_id INTEGER PRIMARY KEY,
;;        print_name TEXT UNIQUE,
;;        print_neg_id INTEGER REFERENCES t_negative (neg_id),
;;        print_papertype TEXT,
;;        print_developer TEXT,
;;        print_devdate DATE,
;;        print_devtime FLOAT,
;;        print_devtemp INTEGER,
;;        print_devdilution TEXT,
;;        print_grade TEXT,
;;        print_size TEXT,
;;        print_exposure TEXT,
;;        print_developing TEXT,
;;        print_scan TEXT);

;; CREATE UNIQUE INDEX t_print_print_name ON t_print(print_name);

;; -------------------------------------------------------------------
;; end of SQL script
;; -------------------------------------------------------------------


;;; Code:

;; *******************************************************************
;;; User-customizable options
;; *******************************************************************

;; the shell command to execute a SQL query using your database
;; client. Include the database name, and authentication options if
;; needed
(defvar photo-dbclient-command "sqlite3 /usr/local/var/db/photo.sqlite3")

;; the root directory of all scans. Use 'nil' if you prefer to provide
;; a fully qualified URL for each scan. If non-nil, each scan is
;; located by a partial path which is relative to photo-image-root
(defvar photo-image-root nil)

;; *******************************************************************
;;; End of user-customizable options
;; *******************************************************************

;; required for the image display code
(eval-when-compile
  (require 'image-file))

;; todo: replace with svn revision
(defvar photo-version "0.5")

;; a list of field names to pretty-print the film output
(defvar photo-filmfields '(
			("film_id" 1)
			("film_name" 2)
			("film_zonemode" 3)
			("film_speed" 4)
			("film_type" 5)
			("film_size" 6)
			("film_devdate" 7)
			("film_developer" 8)
			("film_devtime" 9)
			("film_devtemp" 10)
			("film_devdilution" 11)
			("film_devmode" 12)
			("film_scan" 13)
			))

;; a list of field names to pretty-print the negative output
(defvar photo-negfields '(
			("neg_id" 1)
			("neg_name" 2)
			("neg_film_id" 3)
			("neg_date" 4)
			("neg_aperture" 5)
			("neg_speed" 6)
			("neg_filter" 7)
			("neg_lens" 8)
			("neg_location" 9)
			("neg_description" 10)
			("neg_scan" 11)
			))

;; a list of field names to pretty-print the print output
(defvar photo-printfields '(
			  ("print_id" 1)
			  ("print_name" 2)
			  ("print_neg_id" 3)
			  ("print_papertype" 4)
			  ("print_developer" 5)
			  ("print_devdate" 6)
			  ("print_devtime" 7)
			  ("print_devtemp" 8)
			  ("print_devdilution" 9)
			  ("print_grade" 10)
			  ("print_size" 11)
			  ("print_exposure" 12)
			  ("print_developing" 13)
			  ("print_scan" 14)
			  ))

;; avoid error messages if tab completion is attempted without having
;; filled the lists with photo-init first
(defvar photo-current-prints-list nil)
(defvar photo-current-negatives-list nil)
(defvar photo-current-films-list nil)

;;;;; display print, negative, or film information

(defun photo-display-print (printname)
  "Display all information associated with a given print.
The print is identified by a SQL regular expression."
  (interactive
   (list 
    (completing-read "Print name: "
		     (photo-make-alist-from-list photo-current-prints-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving print information...")

  (let* (
	 ;; we need print, negative, and film info. Create a new list
	 ;; from the individual lists. The final nil arguments forces
	 ;; the preceding argument to be copied so it is not altered
	 (printfields (append
		       photo-printfields
		       photo-negfields
		       photo-filmfields
		       nil))
	 ;; assemble the field values returned by the SQL query in a list
	 ;; the list may contain the values of zero to many hits
	 (printprops
	  (split-string
	   (with-output-to-string
	     (with-current-buffer
		 standard-output
	       (call-process
		shell-file-name nil '(t nil) nil shell-command-switch
		(format
		 "%s \"SELECT %s FROM t_print INNER JOIN t_negative ON t_print.print_neg_id=t_negative.neg_id INNER JOIN t_film ON t_negative.neg_film_id=t_film.film_id WHERE t_print.print_name LIKE \'%s\'\""
		 photo-dbclient-command
		 (photo-build-fieldstring printfields)
		 printname)
		"*photo-output*" "*photo-messages*")
	       ))
	   "[\|\n\t]"))
	 ;; iterator used to access the field names
	 (i 0))
    (message
     "Retrieving print information...done")
    (pop-to-buffer "*photo-output*")
    (set-buffer-file-coding-system 'utf-8-unix)

    ;; append the output to the end of the buffer
    (goto-char (point-max))

    ;; loop over all list members except the last one which is always empty
    ;; nbutlast instead of butlast avoids an expensive list copy
    (dolist (item (nbutlast printprops))
      (insert
;       (format
;	"%s: %s\n"
;	(car (nth i printfields))
;	item)
       (photo-format-output-field printfields i item)
       )
      ;; wrap if we're at the end of the field names, this ends the current hit
      (if (= i (- (length printfields) 1))
	  (progn
	    (setq i 0)
	    (insert
	     (format
	      "\n====\n")))
	(setq i (+ i 1)))))
  (setq resize-mini-windows resize-mini-windows-default)
)

(defun photo-display-negative (negname)
  "Display all information associated with a given negative.
The negative is identified by a SQL regular expression."
  (interactive
   (list 
    (completing-read "Negative name: "
		     (photo-make-alist-from-list photo-current-negatives-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving negative information...")

  (let* (
	 ;; we need negative and film info. Create a new list
	 ;; from the individual lists. The final nil arguments forces
	 ;; the preceding argument to be copied so it is not altered
	 (negfields (append
		       photo-negfields
		       photo-filmfields
		       nil))
	 ;; assemble the field values returned by the SQL query in a list
	 ;; the list may contain the values of zero to many hits
	 (negprops
	  (split-string
	   (with-output-to-string
	     (with-current-buffer
		 standard-output
	       (call-process
		shell-file-name nil '(t nil) nil shell-command-switch
		(format
		 "%s \"SELECT %s FROM t_negative INNER JOIN t_film ON t_negative.neg_film_id=t_film.film_id WHERE t_negative.neg_name LIKE \'%s\'\""
		 photo-dbclient-command
		 (photo-build-fieldstring negfields)
		 negname)
		"*photo-output*" "*photo-messages*")
	       ))
	   "[\|\n\t]"))
	 ;; iterator used to access the field names
	 (i 0))
    (message
     "Retrieving negative information...done")
    (pop-to-buffer "*photo-output*")
    (set-buffer-file-coding-system 'utf-8-unix)

    ;; append the output to the end of the buffer
    (goto-char (point-max))

    ;; loop over all list members except the last one which is always empty
    ;; nbutlast instead of butlast avoids an expensive list copy
    (dolist (item (nbutlast negprops))
      (insert
       (format
	"%s: %s\n"
	(car (nth i negfields))
	item))
      ;; wrap if we're at the end of the field names, this ends the current hit
      (if (= i (- (length negfields) 1))
	  (progn
	    (setq i 0)
	    (insert
	     (format
	      "\n====\n")))
	(setq i (+ i 1)))))
  (setq resize-mini-windows resize-mini-windows-default)
)

(defun photo-display-film (filmname)
  "Display all information associated with a given film.
The film is identified by a SQL regular expression."
  (interactive
   (list 
    (completing-read "Film name: "
		     (photo-make-alist-from-list photo-current-films-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving Film information...")

  (let* (
	 ;; assemble the field values returned by the SQL query in a list
	 ;; the list may contain the values of zero to many hits
	 (filmprops
	  (split-string
	   (with-output-to-string
	     (with-current-buffer
		 standard-output
	       (call-process
		shell-file-name nil '(t nil) nil shell-command-switch
		(format
		 "%s \"SELECT %s FROM t_film WHERE film_name LIKE \'%s\'\""
		 photo-dbclient-command
		 (photo-build-fieldstring photo-filmfields)
		 filmname)
		"*photo-output*" "*photo-messages*")
	       ))
	   "[\|\n\t]"))
	 ;; iterator used to access the field names
	 (i 0))
    (message
     "Retrieving film information...done")
    (pop-to-buffer "*photo-output*")
    (set-buffer-file-coding-system 'utf-8-unix)

    ;; append the output to the end of the buffer
    (goto-char (point-max))

    ;; loop over all list members except the last one which is always empty
    ;; nbutlast instead of butlast avoids an expensive list copy
    (dolist (item (nbutlast filmprops))
      (insert
       (format
	"%s: %s\n"
	(car (nth i photo-filmfields))
	item))
      ;; wrap if we're at the end of the field names, this ends the current hit
      (if (= i (- (length photo-filmfields) 1))
	  (progn
	    (setq i 0)
	    (insert
	     (format
	      "\n====\n")))
	(setq i (+ i 1)))))
  (setq resize-mini-windows resize-mini-windows-default)
)


;;;;; list associated items

(defun photo-list-prints-of-negative (negname)
  "List all prints made from a particular negative.
The negative is identified by a SQL regular expression."
  (interactive
   (list 
    (completing-read "Negative name: "
		     (photo-make-alist-from-list photo-current-negatives-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving print list...")
  (pop-to-buffer "*photo-output*")
  (set-buffer-file-coding-system 'utf-8-unix)

  ;; append the output to the end of the buffer
  (goto-char (point-max))
  (shell-command
   (format
    "%s \"SELECT print_name, neg_description FROM t_print INNER JOIN t_negative ON t_print.print_neg_id=t_negative.neg_id WHERE t_negative.neg_name LIKE \'%s\'\""
    photo-dbclient-command
    negname
    )
   "*photo-output*" "*photo-messages*")
  (message
   "Retrieving print list...done")
  (setq resize-mini-windows resize-mini-windows-default)
)

(defun photo-list-prints-of-film (filmname)
  "List all prints made from a particular film.
The film is identified by a SQL regular expression."
  (interactive
   (list 
    (completing-read "Film name: "
		     (photo-make-alist-from-list photo-current-films-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving print list...")
  (pop-to-buffer "*photo-output*")
  (set-buffer-file-coding-system 'utf-8-unix)

  ;; append the output to the end of the buffer
  (goto-char (point-max))
  (shell-command
   (format
    "%s \"SELECT print_name, neg_description FROM t_print INNER JOIN t_negative ON t_print.print_neg_id=t_negative.neg_id INNER JOIN t_film on t_negative.neg_film_id=t_film.film_id WHERE t_film.film_name LIKE \'%s\'\""
    photo-dbclient-command
    filmname
    )
   "*photo-output*" "*photo-messages*")
  (message
   "Retrieving print list...done")
  (setq resize-mini-windows resize-mini-windows-default)
)


;;;;; list associated items, using a region

(defun photo-list-prints-of-negative-from-region ()
  "List all prints made from a particular negative.
The negative is identified by the currently marked region."
  (interactive)
  (save-excursion
    (let* ((negative
	    (buffer-substring (region-beginning) (region-end))))
      (photo-list-prints-of-negative negative)))
)

(defun photo-list-prints-of-film-from-region ()
  "List all prints made from a particular film.
The film is identified by the currently marked region."
  (interactive)
  (save-excursion
    (let* ((film
	    (buffer-substring (region-beginning) (region-end))))
      (photo-list-prints-of-film film)))
)

(defun photo-display-print-from-region ()
  "Displays all available information about a particular print.
The print is identified by the currently marked region."
  (interactive)
  (save-excursion
    (let* ((print
	    (buffer-substring (region-beginning) (region-end))))
      (photo-display-print print)))
)

(defun photo-display-negative-from-region ()
  "Displays all available information about a particular negative.
The negative is identified by the currently marked region."
  (interactive)
  (save-excursion
    (let* ((neg
	    (buffer-substring (region-beginning) (region-end))))
      (photo-display-negative neg)))
)

(defun photo-display-film-from-region ()
  "Displays all available information about a particular film.
The film is identified by the currently marked region."
  (interactive)
  (save-excursion
    (let* ((film
	    (buffer-substring (region-beginning) (region-end))))
      (photo-display-film film)))
)


;;;;; find negatives using location or description data

(defun photo-find-negatives (term)
  "List all negatives whose location or description matches TERM.
TERM is a SQL regular expression."
  (interactive (list (read-string (format "Term: "))))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving negative list...")
  (pop-to-buffer "*photo-output*")
  (set-buffer-file-coding-system 'utf-8-unix)

  ;; append the output to the end of the buffer
  (goto-char (point-max))
  (shell-command
   (format
    "%s \"SELECT neg_name, neg_description FROM t_negative WHERE neg_location LIKE \'%s\' OR neg_description LIKE \'%s\'\""
    photo-dbclient-command
    term
    term
    )
   "*photo-output*" "*photo-messages*")
  (message
   "Retrieving negative list...done")
  (setq resize-mini-windows resize-mini-windows-default)
)


;;;;; create forms for data entry, add or update data
(defun photo-create-print ()
  "Creates and displays a template for a new print.
The filled-in template can be added to the database using photo-add-print."
  (interactive)
  (with-output-to-temp-buffer
      "*photo-print*"
    (pop-to-buffer "*photo-print*")
    (fundamental-mode)
    (buffer-enable-undo)
    (set-buffer-file-coding-system 'utf-8-unix)
    (insert (photo-build-fieldcolumn photo-printfields))
    )
)

(defun photo-edit-print (printname)
  "Retrieves the specified print from the database and displays it in an editable buffer."
  (interactive
   (list 
    (completing-read "Print name: "
		     (photo-make-alist-from-list photo-current-prints-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving print information...")

  (let* (
	 ;; assemble the field values returned by the SQL query in a list
	 (printprops
	  (split-string
	   (with-output-to-string
	     (with-current-buffer
		 standard-output
	       (call-process
		shell-file-name nil '(t nil) nil shell-command-switch
		(format
		 "%s \"SELECT %s FROM t_print WHERE print_name=\'%s\'\""
		 photo-dbclient-command
		 (photo-build-fieldstring photo-printfields)
		 printname)
		"*photo-output*" "*photo-messages*")
	       ))
	   "[\|\n\t]"))
	 ;; iterator used to access the field names
	 (i 0))
    (message
     "Retrieving print information...done")
    (if (get-buffer "*photo-print*")
	(kill-buffer "*photo-print*"))
    (pop-to-buffer "*photo-print*")
    (set-buffer-file-coding-system 'utf-8-unix)
    (fundamental-mode)
    (buffer-enable-undo)

    ;; loop over all list members except the last one which is always empty
    ;; nbutlast instead of butlast avoids an expensive list copy
    (dolist (item (nbutlast printprops))
      (insert
       (if (string-equal (car (nth i photo-printfields)) "print_id")
	   (photo-make-string-rointangible
	    (format
	     "%s%s\n"
	     (concat (car (nth i photo-printfields)) ": ")
	     item)
	    0)
	 (format
	  "%s%s\n"
	  (photo-make-string-rointangible
	   (concat (car (nth i photo-printfields)) ": ")
	   0)
	  item)))
      ;; wrap if we're at the end of the field names, this ends the current hit
      (setq i (+ i 1))))
  (setq resize-mini-windows resize-mini-windows-default)
  )

(defun photo-add-or-update-print (do-add)
  "Adds or updates the print information from a photo buffer.
Returns the exit status of the shell command used to add or update the data."
  (save-excursion
    (message "Adding print to database ...")
    (goto-char (point-min))
    (let* ((print_id (if (not do-add)
			(if (re-search-forward "print_id: \\(.+\\)$" nil t)
			    (match-string 1 nil)
			  "NULL")
		     nil))
	   (print_name (progn
			;; must rewind as print id is intangible
			(goto-char (point-min))
			(if (re-search-forward "print_name: \\(.+\\)$" nil t)
			    (concat "\'" (match-string 1 nil) "\'")
			  "NULL")))
	   (neg_name (if (re-search-forward "neg_name: \\(.+\\)$" nil t)
			  (concat "\'" (match-string 1 nil) "\'")
			"NULL"))
	   (print_papertype (if (re-search-forward "print_papertype: \\(.+\\)$" nil t)
				(concat "\'" (match-string 1 nil) "\'")
			      "NULL"))
	   (print_developer (if (re-search-forward "print_developer: \\(.+\\)$" nil t)
				(concat "\'" (match-string 1 nil) "\'")
			      "NULL"))
	   (print_devdate (if (re-search-forward "print_devdate: \\(.+\\)$" nil t)
			      (concat "\'" (match-string 1 nil) "\'")
			    "NULL"))
	   (print_devtime (if (re-search-forward "print_devtime: \\(.+\\)$" nil t)
			      (match-string 1 nil)
			    "NULL"))
	   (print_devtemp (if (re-search-forward "print_devtemp: \\(.+\\)$" nil t)
			      (match-string 1 nil)
			    "NULL"))
	   (print_devdilution (if (re-search-forward "print_devdilution: \\(.+\\)$" nil t)
			     (concat "\'" (match-string 1 nil) "\'")`
			   "NULL"))
	   (print_grade (if (re-search-forward "print_grade: \\(.+\\)$" nil t)
			       (concat "\'" (match-string 1 nil) "\'")
			     "NULL"))
	   (print_size (if (re-search-forward "print_size: \\(.+\\)$" nil t)
			       (concat "\'" (match-string 1 nil) "\'")
			     "NULL"))
	   (print_exposure (if (re-search-forward "print_exposure: \\(.+\\)$" nil t)
			       (concat "\'" (match-string 1 nil) "\'")
			     "NULL"))
	   (print_developing (if (re-search-forward "print_developing: \\(.+\\)$" nil t)
			       (concat "\'" (match-string 1 nil) "\'")
			     "NULL"))
	   (print_scan (if (re-search-forward "print_scan: \\(.+\\)$" nil t)
			   (concat "\'" (match-string 1 nil) "\'")
			 "NULL"))
	   (neg_query (format
			"SELECT neg_id FROM t_negative WHERE neg_name=%s"
			neg_name))
	   (neg_query_result
	    (with-output-to-string
	      (with-current-buffer
		  standard-output
		(call-process
		 shell-file-name nil '(t nil) nil shell-command-switch
		 (format "%s \"%s\""
			 photo-dbclient-command
			 neg_query
			 )
		 ))))
	   (neg_id (string-to-number
		     (substring neg_query_result (string-match "^[^\n]*" neg_query_result) (match-end 0))))
	   (sql_command 
	    (if (not do-add)
		(let* ((print_db_id
			(split-string 
			 (with-output-to-string
			   (with-current-buffer
			       standard-output
			     (call-process
			      shell-file-name nil '(t nil) nil shell-command-switch
			      (format
			       "%s \"SELECT print_id FROM t_print WHERE print_id=%s\""
			       photo-dbclient-command
			       print_id)
			      )))
			 "\n")))
		  ;; split-string creates an empty
		  ;; trailing element, so if the SELECT is
		  ;; successful, there are two list
		  ;; members
		  (if (< 1 (length print_db_id))
		      (format
		       (concat
			"UPDATE t_print SET print_name=%s,"
			"print_neg_id=%s,print_papertype=%s,"
			"print_developer=%s,print_devdate=%s,"
			"print_devtime=%s,print_devtemp=%s,"
			"print_devdilution=%s,print_grade=%s,"
			"print_size=%s,print_exposure=%s,"
			"print_developing=%s,"
			"print_scan=%s WHERE print_id=%s")
		       print_name
		       neg_id
		       print_papertype
		       print_developer
		       print_devdate
		       print_devtime
		       print_devtemp
		       print_devdilution
		       print_grade
		       print_size
		       print_exposure
		       print_developing
		       print_scan
		       print_id)
		    (error (format "There is no print %s in the database" film_id))
		    ))
	      (if (< 0 neg_id)
		  (format
		   (concat
		    "INSERT INTO t_print (print_name,print_neg_id,"
		    "print_papertype,print_developer,print_devdate,"
		    "print_devtime,print_devtemp, print_devdilution,"
		    "print_grade,print_size,print_exposure,"
		    "print_developing,print_scan) "
		    "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)")
		   print_name
		   neg_id
		   print_papertype
		   print_developer
		   print_devdate
		   print_devtime
		   print_devtemp
		   print_devdilution
		   print_grade
		   print_size
		   print_exposure
		   print_developing
		   print_scan)
		(error "The negative %s does not exist" film_name)))))
      (shell-command
       (format
	"%s \"%s\""
	photo-dbclient-command
	sql_command)
       "*photo-output*" "*photo-messages*"))
    ))

(defun photo-add-print ()
  "Adds the print information from a buffer created with photo-create-print to the database."
  (interactive)
  (message "Adding print to database ...")
  (if (= 0 (photo-add-or-update-print t))
      (message "Adding print to database...done")
    (error "Adding print to database...failed"))
  )

(defun photo-update-print ()
  "Commits the changes of the print information in a buffer created with photo-edit-print."
  (interactive)
  (message "Updating print in database ...")
  (if (= 0 (photo-add-or-update-print nil))
      (message "Updating print in database...done")
    (error "Updating print in database...failed"))
  )

(defun photo-create-negative ()
  "Creates and displays a template for a new negative.
The filled-in template can be added to the database using photo-add-negative."
  (interactive)
  (with-output-to-temp-buffer
      "*photo-negative*"
    (pop-to-buffer "*photo-negative*")
    (fundamental-mode)
    (buffer-enable-undo)
    (set-buffer-file-coding-system 'utf-8-unix)
    (insert (photo-build-fieldcolumn photo-negfields))
    )
)

(defun photo-edit-negative (negname)
  "Retrieves the specified negative from the database and displays it in an editable buffer."
  (interactive
   (list 
    (completing-read "Negative name: "
		     (photo-make-alist-from-list photo-current-negatives-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving negative information...")

  (let* (
	 ;; assemble the field values returned by the SQL query in a list
	 (negprops
	  (split-string
	   (with-output-to-string
	     (with-current-buffer
		 standard-output
	       (call-process
		shell-file-name nil '(t nil) nil shell-command-switch
		(format
		 "%s \"SELECT %s FROM t_negative WHERE neg_name=\'%s\'\""
		 photo-dbclient-command
		 (photo-build-fieldstring photo-negfields)
		 negname)
		"*photo-output*" "*photo-messages*")
	       ))
	   "[\|\n\t]"))
	 ;; iterator used to access the field names
	 (i 0))
    (message
     "Retrieving negative information...done")
    (if (get-buffer "*photo-negative*")
	(kill-buffer "*photo-negative*"))
    (pop-to-buffer "*photo-negative*")
    (set-buffer-file-coding-system 'utf-8-unix)
    (fundamental-mode)
    (buffer-enable-undo)

    ;; loop over all list members except the last one which is always empty
    ;; nbutlast instead of butlast avoids an expensive list copy
    (dolist (item (nbutlast negprops))
      (insert
       (if (string-equal (car (nth i photo-negfields)) "neg_id")
	   (photo-make-string-rointangible
	    (format
	     "%s%s\n"
	     (concat (car (nth i photo-negfields)) ": ")
	     item)
	    0)
	 (format
	  "%s%s\n"
	  (photo-make-string-rointangible
	   (concat (car (nth i photo-negfields)) ": ")
	   0)
	  item)))
      ;; wrap if we're at the end of the field names, this ends the current hit
      (setq i (+ i 1))))
  (setq resize-mini-windows resize-mini-windows-default)
  )

(defun photo-add-or-update-negative (do-add)
  "Adds or updates the negative information from a photo buffer.
Returns the exit status of the shell command used to add or update the data."
  (save-excursion
    (goto-char (point-min))
    (let* ((neg_id (if (not do-add)
			(if (re-search-forward "neg_id: \\(.+\\)$" nil t)
			    (match-string 1 nil)
			  "NULL")
		     nil))
	   (neg_name (progn
			;; must rewind as negative id is intangible
			(goto-char (point-min))
			(if (re-search-forward "neg_name: \\(.+\\)$" nil t)
			    (concat "\'" (match-string 1 nil) "\'")
			  "NULL")))
	   (film_name (if (re-search-forward "film_name: \\(.+\\)$" nil t)
			  (concat "\'" (match-string 1 nil) "\'")
			"NULL"))
	   (neg_date (if (re-search-forward "neg_date: \\(.+\\)$" nil t)
			     (concat "\'" (match-string 1 nil) "\'")
			   "NULL"))
	   (neg_aperture (if (re-search-forward "neg_aperture: \\(.+\\)$" nil t)
			     (concat "\'" (match-string 1 nil) "\'")
			   "NULL"))
	   (neg_speed (if (re-search-forward "neg_speed: \\(.+\\)$" nil t)
			  (concat "\'" (match-string 1 nil) "\'")
			"NULL"))
	   (neg_filter (if (re-search-forward "neg_filter: \\(.+\\)$" nil t)
			   (concat "\'" (match-string 1 nil) "\'")
			 "NULL"))
	   (neg_lens (if (re-search-forward "neg_lens: \\(.+\\)$" nil t)
			   (concat "\'" (match-string 1 nil) "\'")
			 "NULL"))
	   (neg_location (if (re-search-forward "neg_location: \\(.+\\)$" nil t)
			     (concat "\'" (match-string 1 nil) "\'")`
			   "NULL"))
	   (neg_description (if (re-search-forward "neg_description: \\(.+\\)$" nil t)
			       (concat "\'" (match-string 1 nil) "\'")
			     "NULL"))
	   (neg_scan (if (re-search-forward "neg_scan: \\(.+\\)$" nil t)
			 (concat "\'" (match-string 1 nil) "\'")
		       "NULL"))
	   (film_query (format
			"SELECT film_id FROM t_film WHERE film_name=%s"
			film_name))
	   (film_query_result (with-output-to-string
		      (with-current-buffer
			  standard-output
			(call-process
			 shell-file-name nil '(t nil) nil shell-command-switch
			 (format "%s \"%s\""
				 photo-dbclient-command
				 film_query
				 )
			 ))))
	   (film_id (string-to-number
		     (substring film_query_result (string-match "^[^\n]*" film_query_result) (match-end 0))))
	   (sql_command
	    (if (not do-add)
		(let* ((neg_db_id
			(split-string 
			 (with-output-to-string
			   (with-current-buffer
			       standard-output
			     (call-process
			      shell-file-name nil '(t nil) nil shell-command-switch
			      (format
			       "%s \"SELECT neg_id FROM t_negative WHERE neg_id=%s\""
			       photo-dbclient-command
			       neg_id)
			      )))
			 "\n")))
		  ;; split-string creates an empty
		  ;; trailing element, so if the SELECT is
		  ;; successful, there are two list
		  ;; members
		  (if (< 1 (length neg_db_id))
		      (format
		       (concat
			"UPDATE t_negative SET neg_name=%s,"
			"neg_film_id=%s,neg_date=%s,"
			"neg_aperture=%s,neg_speed=%s,"
			"neg_filter=%s,neg_lens=%s,"
			"neg_location=%s,neg_description=%s,"
			"neg_scan=%s WHERE neg_id=%s")
		       neg_name
		       film_id
		       neg_date
		       neg_aperture
		       neg_speed
		       neg_filter
		       neg_lens
		       neg_location
		       neg_description
		       neg_scan
		       neg_id)
		    (error (format "There is no negative %s in the database" film_id))
		    ))
	      (if (< 0 film_id)
		  (format
		   (concat
		    "INSERT INTO t_negative (neg_name,neg_film_id,"
		    "neg_date,neg_aperture,neg_speed,neg_filter,"
		    "neg_lens,neg_location,neg_description,neg_scan) "
		    "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)")
		   neg_name
		   film_id
		   neg_date
		   neg_aperture
		   neg_speed
		   neg_filter
		   neg_lens
		   neg_location
		   neg_description
		   neg_scan)
		(error "The film %s does not exist" film_name)))))
      (shell-command
       (format
	"%s \"%s\""
	photo-dbclient-command
	sql_command)
       "*photo-output*" "*photo-messages*"))
    ))
 
(defun photo-add-negative ()
  "Adds the negative information from a buffer created with photo-create-negative to the database."
  (interactive)
  (message "Adding negative to database ...")
  (if (photo-add-or-update-negative t)
      (message "Adding negative to database...done")
    (error "Adding negative to database...failed"))
  )

(defun photo-update-negative ()
  "Commits the changes of the negative information in a buffer created with photo-edit-negative."
  (interactive)
  (message "Updating negative in database ...")
  (if (photo-add-or-update-negative nil)
      (message "Updating negative in database...done")
    (error "Updating negative in database...failed"))
  )

(defun photo-create-film ()
  "Creates and displays a template for a new film.
The filled-in template can be added to the database using photo-add-film."
  (interactive)
  (with-output-to-temp-buffer
      "*photo-film*"
    (pop-to-buffer "*photo-film*")
    (fundamental-mode)
    (buffer-enable-undo)
    (set-buffer-file-coding-system 'utf-8-unix)
    (insert (photo-build-fieldcolumn photo-filmfields))
    )
)

(defun photo-edit-film (filmname)
  "Retrieves the specified film from the database and displays it in an editable buffer."
  (interactive
   (list 
    (completing-read "Film name: "
		     (photo-make-alist-from-list photo-current-films-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Retrieving film information...")
  
  (let* (
	 ;; assemble the field values returned by the SQL query in a list
	 (filmprops
	  (split-string
	   (with-output-to-string
	     (with-current-buffer
		 standard-output
	       (call-process
		shell-file-name nil '(t nil) nil shell-command-switch
		(format
		 "%s \"SELECT %s FROM t_film WHERE film_name=\'%s\'\""
		 photo-dbclient-command
		 (photo-build-fieldstring photo-filmfields)
		 filmname)
		"*photo-output*" "*photo-messages*")
	       ))
	   "[\|\n\t]"))
	 ;; iterator used to access the field names
	 (i 0))
    (message
     "Retrieving film information...done")
    (if (get-buffer "*photo-film*")
	(kill-buffer "*photo-film*"))
    (pop-to-buffer "*photo-film*")
    (set-buffer-file-coding-system 'utf-8-unix)
    (fundamental-mode)
    (buffer-enable-undo)

    ;; loop over all list members except the last one which is always empty
    ;; nbutlast instead of butlast avoids an expensive list copy
    (dolist (item (nbutlast filmprops))
      (insert
       (if (string-equal (car (nth i photo-filmfields)) "film_id")
	   (photo-make-string-rointangible
	    (format
	     "%s%s\n"
	     (concat (car (nth i photo-filmfields)) ": ")
	     item)
	    0)
	 (format
	  "%s%s\n"
	  (photo-make-string-rointangible
	   (concat (car (nth i photo-filmfields)) ": ")
	   0)
	  item)))
      ;; wrap if we're at the end of the field names, this ends the current hit
      (setq i (+ i 1))))
  (setq resize-mini-windows resize-mini-windows-default)
  )

(defun photo-add-or-update-film (do-add)
  "Adds or updates the film information from a photo buffer.
Returns the exit status of the shell command used to add or update the data."
  (save-excursion
    (goto-char (point-min))
    (let* ((film_id (if (not do-add)
			(if (re-search-forward "film_id: \\(.+\\)$" nil t)
			    (match-string 1 nil)
			  "NULL")
		      nil))
	   (film_name (progn
			;; must rewind as film id is intangible
			(goto-char (point-min))
			(if (re-search-forward "film_name: \\(.+\\)$" nil t)
			    (concat "\'" (match-string 1 nil) "\'")
			  "NULL")))
	   (film_zonemode (if (re-search-forward "film_zonemode: \\(.+\\)$" nil t)
			      (match-string 1 nil)
			    "NULL"))
	   (film_speed (if (re-search-forward "film_speed: \\(.+\\)$" nil t)
			   (match-string 1 nil)
			 "NULL"))
	   (film_type (if (re-search-forward "film_type: \\(.+\\)$" nil t)
			  (concat "\'" (match-string 1 nil) "\'")
			"NULL"))
	   (film_size (if (re-search-forward "film_size: \\(.+\\)$" nil t)
			  (concat "\'" (match-string 1 nil) "\'")
			"NULL"))
	   (film_devdate (if (re-search-forward "film_devdate: \\(.+\\)$" nil t)
			     (concat "\'" (match-string 1 nil) "\'")`
			   "NULL"))
	   (film_developer (if (re-search-forward "film_developer: \\(.+\\)$" nil t)
			       (concat "\'" (match-string 1 nil) "\'")
			     "NULL"))
	   (film_devtime (if (re-search-forward "film_devtime: \\(.+\\)$" nil t)
			     (match-string 1 nil)
			   "NULL"))
	   (film_devtemp (if (re-search-forward "film_devtemp: \\(.+\\)$" nil t)
			     (match-string 1 nil)
			   "NULL"))
	   (film_devdilution (if (re-search-forward "film_devdilution: \\(.*+\\)$" nil t)
				 (concat "\'" (match-string 1 nil) "\'")
			       "NULL"))
	   (film_devmode (if (re-search-forward "film_devmode: \\(.+\\)$" nil t)
			     (concat "\'" (match-string 1 nil) "\'")
			   "NULL"))
	   (film_scan (if (re-search-forward "film_scan: \\(.+\\)$" nil t)
			  (concat "\'" (match-string 1 nil) "\'")
			"NULL"))
	   (sql_command
	    (if (not do-add)
		(let* ((film_db_id
			(split-string 
			 (with-output-to-string
			   (with-current-buffer
			       standard-output
			     (call-process
			      shell-file-name nil '(t nil) nil shell-command-switch
			      (format
			       "%s \"SELECT film_id FROM t_film WHERE film_id=%s\""
			       photo-dbclient-command
			       film_id)
			      )))
			 "\n")))
		  ;; split-string creates an empty
		  ;; trailing element, so if the SELECT is
		  ;; successful, there are two list
		  ;; members
		  (if (< 1 (length film_db_id))
		      (format
		       (concat
			"UPDATE t_film SET film_name=%s,"
			"film_zonemode=%s,film_speed=%s,"
			"film_type=%s,film_size=%s,"
			"film_devdate=%s,film_developer=%s,"
			"film_devtime=%s,film_devtemp=%s,"
			"film_devdilution=%s,film_devmode=%s,"
			"film_scan=%s WHERE film_id=%s")
		       film_name
		       film_zonemode
		       film_speed
		       film_type
		       film_size
		       film_devdate
		       film_developer
		       film_devtime
		       film_devtemp
		       film_devdilution
		       film_devmode
		       film_scan
		       film_id)
		    (error (format "There is no film %s in the database" film_id))
		    ))
	      (format
	       (concat
		"INSERT INTO t_film (film_name,film_zonemode,"
		"film_speed,film_type,film_size,film_devdate,"
		"film_developer,film_devtime,film_devtemp,"
		"film_devdilution,film_devmode,film_scan) "
		"VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)")
	       film_name
	       film_zonemode
	       film_speed
	       film_type
	       film_size
	       film_devdate
	       film_developer
	       film_devtime
	       film_devtemp
	       film_devdilution
	       film_devmode
	       film_scan))))
      (shell-command
       (format
	"%s \"%s\""
	photo-dbclient-command
	sql_command)
       "*photo-output*" "*photo-messages*"))
    ))
 
(defun photo-add-film ()
  "Adds the film information from a buffer created with photo-create-film to the database."
  (interactive)
  (message "Adding film to database ...")
  (if (= 0 (photo-add-or-update-film t))
      (message "Adding film to database...done")
    (error "Adding film to database...failed"))
  )

(defun photo-update-film ()
  "Commits the changes of the film information in a buffer created with photo-edit-film."
  (interactive)
  (message "Updating film in database ...")
  (if (= 0 (photo-add-or-update-film nil))
      (message "Updating film in database...done")
    (error "Updating film in database...failed"))
  )

(defun photo-add ()
  "Provides a wrapper for the functions photo-add-film, photo-add-negative, and photo-add-print, calling the right one based on the current buffer.
The function checks the name of the current buffer (created with photo-create-film, photo-create-negative, or photo-create-print) and decides which function to call."
  (interactive)
  (cond ((string-equal (buffer-name) "*photo-film*")
	 (call-interactively 'photo-add-film))
	((string-equal (buffer-name) "*photo-negative*")
	 (call-interactively 'photo-add-negative))
	((string-equal (buffer-name) "*photo-print*")
	 (call-interactively 'photo-add-print))
	(t
	 (error "Not a ephotodb buffer, use photo-add-foo explicitly"))
	))

(defun photo-update ()
  "Provides a wrapper for the functions photo-update-film, photo-update-negative, and photo-update-print, calling the right one based on the current buffer.
The function checks the name of the current buffer (created with photo-edit-film, photo-edit-negative, or photo-edit-print) and decides which function to call."
  (interactive)
  (cond ((string-equal (buffer-name) "*photo-film*")
	 (call-interactively 'photo-update-film))
	((string-equal (buffer-name) "*photo-negative*")
	 (call-interactively 'photo-update-negative))
	((string-equal (buffer-name) "*photo-print*")
	 (call-interactively 'photo-update-print))
	(t
	 (error "Not a ephotodb buffer, use photo-update-foo explicitly"))
	))


;;;;; delete items from the database

(defun photo-delete-print (printname)
  "Delete the specified print from the database.
The print is specified as a SQL regular expression to remove more than one at a time."
  (interactive
   (list 
    (completing-read "Print name: "
		     (photo-make-alist-from-list photo-current-prints-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Deleting print ...")
  (let ((sql-command
	 (format
	  "DELETE FROM t_print WHERE print_name LIKE \'%s\'"
	  printname)))
    (if (< 0 (shell-command
	      (format
	       "%s \"%s\""
	       photo-dbclient-command
	       sql-command)
	      "*photo-output*" "*photo-messages*"))
	(error "Deleting print...failed")
      (message "Deleting print...done")
      ))
  (setq resize-mini-windows resize-mini-windows-default)
)

(defun photo-delete-negative (negname)
  "Delete the specified negative from the database.
The negative is specified as a SQL regular expression to remove more than one at a time."
  (interactive
   (list 
    (completing-read "Negative name: "
		     (photo-make-alist-from-list photo-current-negatives-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Deleting negative ...")
  (let ((sql-command
	 (format
	  "DELETE FROM t_negative WHERE neg_name LIKE \'%s\'"
	  negname)))
    (if (< 0 (shell-command
	      (format
	       "%s \"%s\""
	       photo-dbclient-command
	       sql-command)
	      "*photo-output*" "*photo-messages*"))
	(error "Deleting negative...failed")
      (message "Deleting negative...done")
      ))
  (setq resize-mini-windows resize-mini-windows-default)
)

(defun photo-delete-cascade-negative (negname)
  "Delete the specified negative, and all prints made from this negative, from the database.
The negative is specified as a SQL regular expression to remove more than one at a time."
  (interactive
   (list 
    (completing-read "Negative name: "
		     (photo-make-alist-from-list photo-current-negatives-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)
  
  (message
   "Deleting associated prints ...")
  (let ((sql-command
	 (format
	  "DELETE FROM t_print WHERE print_id IN (SELECT print_id FROM t_print INNER JOIN t_negative ON t_print.print_neg_id=t_negative.neg_id WHERE t_negative.neg_name=\'%s\')"
	  negname)))
    (if (< 0 (shell-command
	      (format
	       "%s \"%s\""
	       photo-dbclient-command
	       sql-command)
	      "*photo-output*" "*photo-messages*"))
	(error "Deleting associated prints...failed")
      (photo-delete-negative negname)
      ))
  (setq resize-mini-windows resize-mini-windows-default)
)
   
(defun photo-delete-film (filmname)
  "Delete the specified film from the database.
The film is specified as a SQL regular expression to remove more than one film at a time."
  (interactive
   (list 
    (completing-read "Film name: "
		     (photo-make-alist-from-list photo-current-films-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)

  (message
   "Deleting film ...")
  (let ((sql-command
	 (format
	  "DELETE FROM t_film WHERE film_name LIKE \'%s\'"
	  filmname)))
    (if (< 0 (shell-command
	      (format
	       "%s \"%s\""
	       photo-dbclient-command
	       sql-command)
	      "*photo-output*" "*photo-messages*"))
	(error "Deleting film...failed")
      (message "Deleting film...done")
      ))
  (setq resize-mini-windows resize-mini-windows-default)
)

(defun photo-delete-cascade-film (filmname)
  "Delete the specified film, and all negatives and prints associated with this film, from the database.
The film is specified as a SQL regular expression to remove more than one at a time."
  (interactive
   (list 
    (completing-read "Film name: "
		     (photo-make-alist-from-list photo-current-films-list))
    ))

  ;; temporarily set resize-mini-windows to nil to force Emacs to show
  ;; output in separate buffer instead of minibuffer
  (setq resize-mini-windows-default resize-mini-windows)
  (setq resize-mini-windows nil)
  
  (message
   "Deleting associated prints ...")
  (let ((sql-print-command
	 (format
	  "DELETE FROM t_print WHERE print_id IN (SELECT print_id FROM t_print INNER JOIN t_negative ON t_print.print_neg_id=t_negative.neg_id WHERE t_negative.neg_name IN (SELECT neg_name from t_negative INNER JOIN t_film ON t_negative.neg_film_id=t_film.film_id WHERE t_film.film_name=\'%s\'))"
	  filmname))
	(sql-negative-command
	 (format
	  "DELETE FROM t_negative WHERE neg_id IN (SELECT neg_id FROM t_negative INNER JOIN t_film ON t_negative.neg_film_id=t_film.film_id WHERE t_film.film_name=\'%s\')"
	  filmname))
	)
    (if (< 0 (shell-command
	      (format
	       "%s \"%s\""
	       photo-dbclient-command
	       sql-print-command)
	      "*photo-output*" "*photo-messages*"))
	(error "Deleting associated prints...failed")
      (if (< 0 (shell-command
		(format
		 "%s \"%s\""
		 photo-dbclient-command
		 sql-negative-command)
		"*photo-output*" "*photo-messages*"))
	  (error "Deleting associated negatives...failed")
      (photo-delete-film filmname)
      )))
  (setq resize-mini-windows resize-mini-windows-default)
  )


;;;;; fill the completion lists

(defun photo-list-prints ()
  "List available prints."
  (split-string 
   (with-output-to-string
     (with-current-buffer
	 standard-output
       (call-process
	shell-file-name nil '(t nil) nil shell-command-switch
	(format
	 "%s \"SELECT print_name FROM t_print\""
	 photo-dbclient-command)
     )))
   "\n")
  )

(defun photo-scan-prints-list ()
  "Scan list of prints."
  (interactive)
  (message
   "Building list of prints...")
  (progn
    (setq photo-current-prints-list (photo-list-prints))
    )
  (message
   "Building list of prints...done")
  )

(defun photo-list-negatives ()
  "List available negatives."
  (split-string 
   (with-output-to-string
     (with-current-buffer
	 standard-output
       (call-process
	shell-file-name nil '(t nil) nil shell-command-switch
	(format
	 "%s \"SELECT neg_name FROM t_negative\""
	 photo-dbclient-command)
     )))
   "\n")
  )

(defun photo-scan-negatives-list ()
  "Scan list of negatives."
  (interactive)
  (message
   "Building list of negatives...")
  (progn
    (setq photo-current-negatives-list (photo-list-negatives))
    )
  (message
   "Building list of negatives...done")
  )

(defun photo-list-films ()
  "List available films."
  (split-string 
   (with-output-to-string
     (with-current-buffer
	 standard-output
       (call-process
	shell-file-name nil '(t nil) nil shell-command-switch
	(format
	 "%s \"SELECT film_name FROM t_film\""
	 photo-dbclient-command)
     )))
   "\n")
  )

(defun photo-scan-films-list ()
  "Scan list of films."
  (interactive)
  (message
   "Building list of films...")
  (progn
    (setq photo-current-films-list (photo-list-films))
    )
  (message
   "Building list of films...done")
  )

(defun photo-init ()
  "Initialize the completion lists of ephotodb."
  (interactive)
  (photo-scan-films-list)
  (photo-scan-negatives-list)
  (photo-scan-prints-list)
  )


;;;;; display mode information

(defun photo-show-database ()
  "Display the access command of the ephotodb database."
  (interactive)
  (message (format "Current photo database: %s" photo-dbclient-command))
  )

(defun photo-show-version ()
  "Display the version of ephotodb."
  (interactive)
  (message (format "ephotodb %s" photo-version))
  )

(defun photo-show-manual ()
  "Display the info manual of ephotodb."
  (interactive)
  (info "ephotodb")
  )

(defun photo-show-messages ()
  "Show photo messages buffer (stderr output from database clients)."
  (interactive)
  (pop-to-buffer "*photo-messages*")
)

;;;;; image display functions
;; NB the image display code was borrowed from iimage.el
;; http://www.netlaputa.ne.jp/~kose/Emacs/iimage.html
;; with only slight modifications

(defvar photo-image-filename-regex
  (concat "[-+./_0-9a-zA-Z]+\\."
	  (regexp-opt (nconc (mapcar #'upcase
				     image-file-name-extensions)
			     image-file-name-extensions)
		      t)))

(defvar photo-image-regex-alist
  `((,(concat "\\(`?file://\\|\\[\\[\\|<\\|`\\)?"
	      "\\(" photo-image-filename-regex "\\)"
	      "\\(\\]\\]\\|>\\|'\\)?") . 2))
"*Alist of filename REGEXP vs NUM.
Each element looks like (REGEXP . NUM).
NUM specifies which parenthesized expression in the regexp.

image filename regex exsamples:
    file://foo.png
    `file://foo.png'
    \\[\\[foo.gif]]
    <foo.png>
     foo.JPG
")

(defvar photo-image-search-path nil
"*List of directories to search for image files for photo.")

;; provide locate-file for Emacs < 22
(if (fboundp 'locate-file)
    (defalias 'photo-locate-file 'locate-file)
  (defun photo-locate-file (filename path)
    (locate-library filename t path)))

(defun photo-image (arg)
"Display/undisplay images.
If ARG is non-nil, display the images, else display their path."
  (interactive)
  (let ((modp (buffer-modified-p (current-buffer)))
	file buffer-read-only)
    (save-excursion
      (goto-char (point-min))
      (dolist (pair photo-image-regex-alist)
	(while (re-search-forward (car pair) nil t)
	  (if (and (setq file (match-string (cdr pair)))
		   (setq file (photo-locate-file file
				   (cons default-directory
					 photo-image-search-path))))
	      (if arg
		  (add-text-properties (match-beginning 0) (match-end 0)
				       (list 'display (create-image file)))
		(remove-text-properties (match-beginning 0) (match-end 0)
					'(display)))))))
    (set-buffer-modified-p modp)))

(defun photo-show-images ()
  "Display images whose filename is in the current buffer."
  (interactive)
  (photo-image t))

(defun photo-hide-images ()
  "Hide images whose filename is in the current buffer."
  (interactive)
  (photo-image nil))


;;;;; internal helper functions

(defun photo-make-alist-from-list (list)
  "Make an alist from LIST by cons'ing elements with themselves."
  (mapcar
   (lambda (atom)
     (cons atom nil))
   list)
  )

(defun photo-build-fieldstring (fieldlist)
  "Builds a comma-separated string from a list of lists whose CARs are field names."
  (let* ((fieldstring ""))
    (dolist (item fieldlist)
      (setq fieldstring (concat fieldstring "," (car item)))
      )
    (substring fieldstring 1)
))

(defun photo-build-fieldcolumn (fieldlist)
  "Builds a newline-separated string from a list of lists whose CARs are field names."
  (let ((fieldstring ""))
    (dolist (item fieldlist)
      ;; we use photo-printfields as a source for all field columns,
      ;; but we exclude all items which don't match the given
      ;; pattern. In addition we skip the ID fields as the user is not
      ;; supposed to fiddle with these. Instead of neg_film_id and
      ;; print_neg_id which are foreign keys we ask for the film and
      ;; negative names, respectively, as the user is going to know
      ;; these without a database lookup
      (unless (or
	       (string-equal (car item) "film_id")
	       (string-equal (car item) "neg_id")
	       (string-equal (car item) "print_id")
	       )
	(setq fieldstring
	      (cond ((string-equal (car item) "neg_film_id")
		     (concat
		      fieldstring
		      (photo-make-string-rointangible "film_name: \n" 1)))
		    ((string-equal (car item) "print_neg_id")
		     (concat
		      fieldstring
		      (photo-make-string-rointangible "neg_name: \n" 1)))
		    (t
		     (concat
		      fieldstring
		      (photo-make-string-rointangible 
		       (concat (car item) ": \n")
		       1)))
		    ))))
    fieldstring
    ))

(defun photo-make-string-rointangible (string exclude)
  "Add the intangible and read-only text properties to STRING, excluding EXCLUDE trailing characters."
  (let ((start 0)
	(end (- (length string) exclude))
	)
    (add-text-properties start end '(intangible t read-only t rear-nonsticky t face bold) string)
    string
  ))

(defun photo-format-output-field (fields index item)
  "Create a formatted string using the INDEXth entry of the FIELDS list as tag and ITEM as value."
  (let ((tag (car (nth index fields))))
    (format
     "%s: %s\n"
     tag
     (if (and
	  (string-match "^\\(print\\|film\\|neg\\)_scan" tag)
	  ;; add image root only if set and if item is a partial path
	  photo-image-root
	  (< 0 (length item))
	  (not (string-match "^file://" item)))
	 (format
	  "%s%s"
	  photo-image-root
	  item)
       item)
     )))


(provide 'ephotodb)

;;; end of ephotodb.el
