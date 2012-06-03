(use-package 'bson)
(use-package 'mongodb)
(use-package 'cffi)

(defvar *b* (bson-create))
(defvar *sub* (bson-create))
(defvar *empty* (bson-create))
(defvar *it* (bson-iterator-create))
(defvar *conn* (mongo-create))
(defvar *cursor* (mongo-cursor-create))

(bson-init *b*)

(bson-append-new-oid *b* "_id")
(bson-append-new-oid *b* "user_id")


(bson-append-start-array *b* "items")
(bson-append-start-object *b* "0")
(bson-append-string *b* "name" "John Coltrane: Impressions")
(bson-append-int *b* "price" 1099)
(bson-append-finish-object *b*)

(bson-append-start-object *b* "1")
(bson-append-string *b* "mame" "Larry Young: Unity")
(bson-append-int *b* "price" 1199)
(bson-append-finish-object *b*)
(bson-append-finish-array *b*)


(bson-append-start-object *b* "address")
(bson-append-string *b* "street" "59 18th St.")
(bson-append-int *b* "zip" 10010)
(bson-append-finish-object *b*)


(bson-append-int *b* "total" 2298)

(bson-finish *b*)
(print "Here's the whole BSON object:\n")
(bson-print *b*)


(bson-find *it* *b* "items")

(bson-iterator-subobject *it* *sub*)

(print "And here's the inner sub-object by itself.\n")
(bson-print *sub*)


(if (not (eql (mongo-connect *conn* "127.0.0.1" 27017) 0))
  (progn
    (case (foreign-slot-value *conn* 'mongo :err)
      (:mongo_conn_no_socket (print "Could not create a socket"))
      (:mongo_conn_fail (print "FAIL: Could not connect to mongod. Make sure it's listening at 127.0.0.1:27017.")))
    (quit :unix-status 1)))

(if (not (eql (mongo-insert *conn* "test.records" *b* (null-pointer)) 0 ))
  (progn
    (format t "FAIL: Failed to insert document with error ~a" (foreign-slot-value *conn* 'mongo :err))
    (quit :unix-status 1)))

(mongo-cursor-init *cursor* *conn* "test.records")
(mongo-cursor-set-query *cursor* (bson-empty *empty*))
(if (not (eql (mongo-cursor-next *cursor*) +mongo_ok+))
  (progn
    (print "FAIL: failed to find inserted document")
    (quit :unix-status 1)))

(print "Found saved BSON object")
(bson-print (mongo-cursor-bson *cursor*))

(mongo-cursor-destroy *cursor*)
(bson-destroy *b*)
(mongo-destroy *conn*)


(defvar *oid* (foreign-alloc :bson_oid_t))
(bson-oid-gen *oid*)
(defvar *oid_str* (foreign-alloc :char :count 25))
(bson-oid-to-string *oid* *oid_str*)
(print (foreign-string-to-lisp *oid_str*))
(foreign-free *oid*)
(foreign-free *oid_str*)
