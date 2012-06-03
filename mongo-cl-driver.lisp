(ql:quickload 'cffi)

(sb-alien:load-shared-object "libmongoc.so")
(sb-alien:load-shared-object "libbson.so")

(defpackage bson
  (:use :common-lisp :cffi)
  (:export :bson_type
    :bson_t
    :bson_bool_t
    :bson-empty
    :bson-create
    :bson-dispose
    :bson-init
    :bson-destroy
    :bson-append-new-oid
    :bson-append-int
    :bson-append-string
    :bson-append-start-array
    :bson-append-start-object
    :bson-append-finish-object
    :bson-append-finish-array
    :bson-iterator-create
    :bson-print
    :bson-find
    :bson-iterator-subobject
    :bson-iterator-dispose
    :bson-oid-gen
    :bson-oid-to-string
    :bson-finish))

(in-package bson)

;;; typedefs
(cffi:defctype bson_bool_t :int)
;; data types

(defcstruct bson_t
  (:data :pointer)
  (:cur :pointer)
  (:data-size :int)
  (:finished bson_bool_t)
  (:stack :int :count 32)
  (:stack-pos :int)
  (:err :int)
  (:errstr :string))

(defcunion :bson_oid_t
  (ints :int :count 3)
  (bytes :unsigned-char :count 12))

(defcenum bson_type
  :bson_eoo
  :bson_double
  :bson_string
  :bson_object
  :bson_array
  :bson_bindata
  :bson_undefined
  :bson_oid
  :bson_bool
  :bson_date
  :bson_null
  :bson_regex
  :bson_dbref
  :bson_code
  :bson_symbol
  :bson_codewscope
  :bson_int
  :bson_timestamp
  :bson_long)

(cffi:define-foreign-library libbson
  (:t "libbson.so"))

(cffi:load-foreign-library 'libbson)

(defcfun ("bson_create" :library libbson) :pointer)

(defcfun ("bson_dispose" :library libbson) :void (b :pointer))

(defcfun ("bson_init" :library libbson) :void (b :pointer))

(defcfun ("bson_destroy" :library libbson) :void (b :pointer))

(defcfun ("bson_empty" :library libbson) :pointer (b :pointer))

(defcfun ("bson_append_new_oid" :library libbson) :int
  (b :pointer) (name :string))

(defcfun ("bson_append_int" :library libbson) :int
  (b :pointer) (name :string) (value :int))

(defcfun ("bson_append_string" :library libbson) :int
  (b :pointer) (name :string) (value :string))

(defcfun ("bson_finish" :library libbson) :int (b :pointer) )

(defcfun ("bson_append_start_array" :library libbson) :int
  (b :pointer) (name :string))

(defcfun ("bson_append_start_object" :library libbson) :int
  (b :pointer) (name :string))

(defcfun ("bson_append_finish_object" :library libbson) :int
  (b :pointer))

(defcfun ("bson_append_finish_array" :library libbson) :int
  (b :pointer))

(defcfun ("bson_iterator_create" :library libbson) :pointer)

(defcfun ("bson_print" :library libbson) :void
  (b :pointer))

(defcfun ("bson_find" :library libbson) bson_type
  (it :pointer)
  (obj :pointer)
  (name :string))

(defcfun ("bson_iterator_subobject" :library libbson) :void
  (bson_iterator :pointer)
  (sub :pointer))

(defcfun ("bson_iterator_dispose" :library libbson) :void
  (i :pointer))

(defcfun ("bson_oid_gen" :library libbson) :void
  (oid :pointer))

(defcfun ("bson_oid_to_string" :library libbson) :void
  (oid :pointer)
  (str :pointer))

(defpackage mongodb
  (:use :common-lisp :cffi :bson)
  (:export :mongo_error_t
    :mongo
    :mongo-create
    :mongo-dispose
    :mongo-init
    :mongo-destroy
    :mongo-connect
    :mongo-disconnect
    :mongo-reconnect
    :mongo-cursor-create
    :mongo-cursor-init
    :mongo-cursor-next
    :mongo-cursor-bson
    :mongo-cursor-destroy
    :mongo-cursor-dispose
    :mongo-cursor-set-query
    :+mongo_ok+
    :+mongo_error+
    :mongo-insert))

(in-package mongodb)

(defmacro cffi-fix (form)
  (eval form))

(cffi:define-foreign-library libmongoc
  (:t "libmongoc.so"))
(cffi:load-foreign-library 'libmongoc)
;;; datatypes
(defconstant +mongo_ok+ 0)
(defconstant +mongo_error+ -1)

(cffi:defcenum mongo_error_t
  (:mongo_conn_success 0)
  :mongo_conn_no_socket
  :mongo_conn_fail
  :mongo_conn_addr_fail
  :mongo_conn_not_master
  :mongo_conn_bad_set_name
  :mongo_conn_not_primary

  :mongo_io_error
  :mongo_socket_error
  :mongo_read_size_error
  :mongo_command_failed
  :mongo_write_error
  :mongo_ns_invalid
  :mongo_bson_invalid
  :mongo_bson_not_finished
  :mongo_bson_too_large
  :mongo_write_concern_invalid)

(defcenum mongo_cursor_error_t
  :mongo_cursor_exhausted
  :mongo_cursor_invalid
  :mongo_cursor_pending
  :mongo_cursor_query_fail
  :mongo_cursor_bson_error)

(defcenum mongo_cursor_flags
  (:mongo_cursor_must_free 1)
  (:mongo_cursor_query_sent 2))

(defcenum mongo_index_opts
  (:mongo_index_unique 1)
  (:mongo_index_drop_dups 4)
  (:mongo_index_background 8)
  (:mongo_index_sparse 16))

(defcenum mongo_update_opts
  (:mongo_update_upsert #x1)
  (:mongo_update_multi #x2)
  (:mongo_update_basic #x4))

(defcenum mongo_insert_opts
  (:mongo_continue_on_error #x1))

(defcenum mongo_cursor_opts
  (:mongo_tailable 2)
  (:mongo_slave_ok 4)
  (:mongo_no_cursor_timeout 16)
  (:mongo_await_data 32)
  (:mongo_exhaust 64)
  (:mongo_partial 128))

(defcenum mongo_operations
  (:mongo_op_msg 1000)
  (:mongo_op_update 2001)
  (:mongo_op_insert 2002)
  (:mongo_op_query 2004)
  (:mongo_op_get_more 2005)
  (:mongo_op_delete 2006)
  (:mongo_op_kill_cursors 2007))


;; (defconst +mongo_err_len+ 128)

;;; structs

(defcstruct mongo_host_port
  (:host :char :count 255)
  (:port :int)
  (:next :pointer))

(defcstruct mongo_write_concern
  (:w :int)
  (:wtimeout :int)
  (:j :int)
  (:fsync :int)
  (:mode :string)
  (:bson :pointer))

(defcstruct mongo_replset
  (:seeds :pointer)
  (:hosts :pointer)
  (:name :string)
  (:primary_connected bson_bool_t))

(cffi:defcstruct mongo
  (:primary :pointer) ;; mongo_host_port
  (:replset :pointer) ;;mongo_replset
  (:sock :int)
  (:flags :int)
  (:conn_timeout_ms :int)
  (:op_timeout_ms :int)
  (:max_bson_size :int)
  (:connected bson_bool_t)
  (:write_concern :pointer)
  (:err mongo_error_t)
  (:errorcode :int)
  (:errstr :string)
  (:lasterrcode :int)
  (:lasterrstr :string))

(defcstruct mongo_cursor
  (:reply :pointer)
  (:conn :pointer)
  (:ns :string)
  (:flags :int)
  (:seen :int)
  (:current bson:bson_t)
  (:err mongo_cursor_error_t)
  (:query :pointer)
  (:fields :pointer)
  (:options :int)
  (:limit :int)
  (:skip :int))


(defcfun ("mongo_create" :library libmongoc) :pointer)

(defcfun ("mongo_dispose" :library libmongoc) :void (conn :pointer))

(defcfun ("mongo_init" :library libmongoc) :void (conn :pointer))

(defcfun ("mongo_destroy" :library libmongoc) :void (conn :pointer))

(defcfun ("mongo_connect" :library libmongoc) :int
  (conn :pointer) (host :string) (port :int))

(defcfun ("mongo_disconnect" :library libmongoc) :void
  (conn :pointer))

(defcfun ("mongo_reconnect" :library libmongoc) :int
  (conn :pointer))

(defcfun ("mongo_insert" :library libmongoc) :int
  (conn :pointer) (ns :string) (bson :pointer) (write_concern :pointer))

(defcfun ("mongo_cursor_create" :library libmongoc) :pointer)

(defcfun ("mongo_cursor_init" :library libmongoc) :void
  (cursor :pointer)
  (conn :pointer)
  (ns :string))

(defcfun ("mongo_cursor_set_query" :library libmongoc) :void
  (cursor :pointer)
  (query :pointer))

(defcfun ("mongo_cursor_next" :library libmongoc) :int
  (cursor :pointer))

(defcfun ("mongo_cursor_bson" :library libmongoc) :pointer
  (cursor :pointer))

(defcfun ("mongo_cursor_destroy" :library libmongoc) :void (conn :pointer))

(defcfun ("mongo_cursor_dispose" :library libmongoc) :void (conn :pointer))
