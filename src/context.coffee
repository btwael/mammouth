exports.Context = class Context
	constructor: (element) ->
		@scopes = []
		@scopes.unshift(element)

	push: (iden) ->
		@scopes[0][iden.name] = {}
		@scopes[0][iden.name].name = iden.name
		@scopes[0][iden.name].type = iden.type

	scopein: () ->
		@scopes.unshift({});

	scopeout: () ->
		@scopes.shift()

	Identify: (name) ->
		for scope in @scopes
			if scope[name] isnt undefined
				if scope[name].type in ['function', 'cte', 'class', 'interface']
					return name
				else
					return '$' + name
		return '$' + name

###
	Precontext Addition todo list:
	[ ] Affecting PHP's Behaviour
		[ ] APC
		[ ] APD
		[ ] bcompiler
		[ ] BLENC
		[ ] Error Handling
		[ ] htscanner
		[ ] inclued
		[ ] Memtrack
		[ ] OPcache
		[ ] Output Control
		[ ] PHP Options/Info
		[ ] runkit
		[ ] scream
		[ ] uopz
		[ ] Weakref
		[ ] WinCache
		[ ] Xhprof
	[ ] Audio Formats Manipulation
		[ ] ID3
		[ ] KTaglib
		[ ] oggvorbis
		[ ] OpenAL
	[ ] Authentication Services
		[ ] KADM5
		[ ] Radius
	[ ] Command Line Specific Extensions
		[ ] Ncurses
		[ ] Newt
		[ ] Readline
	[ ] Compression and Archive Extensions
		[ ] Bzip2
		[ ] LZF
		[ ] Phar
		[ ] Rar
		[ ] Zip
		[ ] Zlib
	[ ] Credit Card Processing
		[ ] MCVE
		[ ] SPPLUS
	[x] Cryptography Extensions
		[x] Crack
		[x] Hash
		[x] Mcrypt
		[x] Mhash
		[x] OpenSSL
		[x] Password Hashing
	[ ] Database Extensions
		[ ] Abstraction Layers
		[ ] Vendor Specific Database Extensions
	[ ] Date and Time Related Extensions
		[ ] Calendar
		[ ] Date/Time
		[ ] HRTime
	[x] File System Related Extensions
		[x] Direct IO
		[x] Directories
		[x] Fileinfo
		[x] Filesystem
		[x] Inotify
		[x] Mimetype
		[x] Proctitle
		[x] xattr
		[x] xdiff
	[ ] Human Language and Character Encoding Support
		[ ] Enchant
		[ ] FriBiDi
		[ ] Gender
		[ ] Gettext
		[ ] iconv
		[ ] intl
		[ ] Multibyte String
		[ ] Pspell
		[ ] Recode
	[ ] Image Processing and Generation
		[ ] Cairo
		[ ] Exif
		[ ] GD
		[ ] Gmagick
		[ ] ImageMagick
	[ ] Mail Related Extensions
		[ ] Cyrus
		[ ] IMAP
		[ ] Mail
		[ ] Mailparse
		[ ] vpopmail
	[ ] Mathematical Extensions
		[ ] BC Math
		[ ] GMP
		[ ] Lapack
		[ ] Math
		[ ] Statistics
		[ ] Trader
	[ ] Non-Text MIME Output
		[ ] FDF
		[ ] GnuPG
		[ ] haru
		[ ] Ming
		[ ] PDF
		[ ] PS
		[ ] RPM Reader
		[ ] SWF
	[ ] Process Control Extensions
		[ ] Eio
		[ ] Ev
		[ ] Expect
		[ ] Libevent
		[ ] PCNTL
		[ ] POSIX
		[ ] Program execution
		[ ] pthreads
		[ ] Semaphore
		[ ] Shared Memory
		[ ] Sync
	[ ] Other Basic Extensions
		[ ] GeoIP
		[ ] FANN
		[ ] JSON
		[ ] Judy
		[ ] Lua
		[ ] Misc.
		[ ] Parsekit
		[ ] SPL
		[ ] SPL Types
		[ ] Streams
		[ ] Tidy
		[ ] Tokenizer
		[ ] URLs
		[ ] V8js
		[ ] Yaml
		[ ] Yaf
		[ ] Taint
	[ ] Other Services
		[ ] chdb
		[ ] cURL
		[ ] Event
		[ ] FAM
		[ ] FTP
		[ ] Gearman
		[ ] Gopher
		[ ] Gupnp
		[ ] HTTP
		[ ] Hyperwave
		[ ] Hyperwave API
		[ ] Java
		[ ] LDAP
		[ ] Lotus Notes
		[ ] Memcache
		[ ] Memcached
		[ ] mqseries
		[ ] Network
		[ ] RRD
		[ ] SAM
		[ ] SNMP
		[ ] Sockets
		[ ] SSH2
		[ ] Stomp
		[ ] SVM
		[ ] SVN
		[ ] TCP
		[ ] Varnish
		[ ] YAZ
		[ ] YP/NIS
		[ ] 0MQ messaging
	[ ] Search Engine Extensions
		[ ] mnoGoSearch
		[ ] Solr
		[ ] Sphinx
		[ ] Swish
	[ ] Server Specific Extensions
		[ ] Apache
		[ ] FastCGI Process Manager
		[ ] IIS
		[ ] NSAPI
	[ ] Session Extensions
		[ ] Msession
		[ ] Sessions
		[ ] Session PgSQL
	[ ] Text Processing
		[ ] BBCode
		[ ] PCRE
		[ ] POSIX Regex
		[ ] ssdeep
		[ ] Strings
	[x] Variable and Type Related Extensions
		[x] Arrays
		[x] Classes/Objects
		[x] Classkit
		[x] Ctype
		[x] Filter
		[x] Function Handling
		[x] Object Aggregation
		[x] Quickhash
		[x] Reflection
		[x] Variable handling
	[ ] Web Services
		[ ] OAuth
		[ ] SCA
		[ ] SOAP
		[ ] Yar
		[ ] XML-RPC
	[ ] Windows Only Extensions
		[ ] .NET
		[ ] COM
		[ ] W32api
		[ ] win32ps
		[ ] win32service
	[ ] XML Manipulation
		[ ] DOM
		[ ] libxml
		[ ] qtdom
		[ ] SDO
		[ ] SDO-DAS-Relational
		[ ] SDO DAS XML
		[ ] SimpleXML
		[ ] WDDX
		[ ] XMLDiff
		[ ] XML Parser
		[ ] XMLReader
		[ ] XMLWriter
		[ ] XSL
		[ ] XSLT (PHP 4)
###
PreContext = exports.PreContext = new Context({
	### Variable and Type Related Extensions ###

	# Function handling
	# Function handling Functions
	'call_​user_​func_​array':
		'type': 'function'
	'call_user_func':
		'type': 'function'
	'create_function':
		'type': 'function'
	'forward_static_call_array':
		'type': 'function'
	'forward_static_call':
		'type': 'function'
	'func_get_arg':
		'type': 'function'
	'func_get_args':
		'type': 'function'
	'func_num_args':
		'type': 'function'
	'function_exists':
		'type': 'function'
	'get_defined_functions':
		'type': 'function'
	'register_shutdown_function':
		'type': 'function'
	'register_tick_function':
		'type': 'function'
	'unregister_tick_function':
		'type': 'function'

	# Arrays
	# Array Constants
	'CASE_LOWER':
		'type': 'cte'
	'CASE_UPPER':
		'type': 'cte'
	'SORT_ASC':
		'type': 'cte'
	'SORT_DESC':
		'type': 'cte'
	'SORT_REGULAR':
		'type': 'cte'
	'SORT_NUMERIC':
		'type': 'cte'
	'SORT_STRING':
		'type': 'cte'
	'SORT_LOCALE_STRING':
		'type': 'cte'
	'SORT_NATURAL':
		'type': 'cte'
	'SORT_FLAG_CASE':
		'type': 'cte'
	'COUNT_NORMAL':
		'type': 'cte'
	'COUNT_RECURSIVE':
		'type': 'cte'
	'EXTR_OVERWRITE':
		'type': 'cte'
	'EXTR_SKIP':
		'type': 'cte'
	'EXTR_PREFIX_SAME':
		'type': 'cte'
	'EXTR_PREFIX_ALL':
		'type': 'cte'
	'EXTR_PREFIX_INVALID':
		'type': 'cte'
	'EXTR_PREFIX_IF_EXISTS':
		'type': 'cte'
	'EXTR_IF_EXISTS':
		'type': 'cte'
	'EXTR_REFS':
		'type': 'cte'
	# Array functions
	'array_change_key_case':
		'type': 'function'
	'array_chunk':
		'type': 'function'
	'array_column':
		'type': 'function'
	'array_combine':
		'type': 'function'
	'array_count_values':
		'type': 'function'
	'array_diff_assoc':
		'type': 'function'
	'array_diff_key':
		'type': 'function'
	'array_diff_uassoc':
		'type': 'function'
	'array_diff_ukey':
		'type': 'function'
	'array_diff':
		'type': 'function'
	'array_fill_keys':
		'type': 'function'
	'array_fill':
		'type': 'function'
	'array_filter':
		'type': 'function'
	'array_flip':
		'type': 'function'
	'array_intersect_assoc':
		'type': 'function'
	'array_intersect_key':
		'type': 'function'
	'array_intersect_uassoc':
		'type': 'function'
	'array_intersect_ukey':
		'type': 'function'
	'array_intersect':
		'type': 'function'
	'array_key_exists':
		'type': 'function'
	'array_keys':
		'type': 'function'
	'array_map':
		'type': 'function'
	'array_merge_recursive':
		'type': 'function'
	'array_merge':
		'type': 'function'
	'array_multisort':
		'type': 'function'
	'array_pad':
		'type': 'function'
	'array_pop':
		'type': 'function'
	'array_product':
		'type': 'function'
	'array_push':
		'type': 'function'
	'array_rand':
		'type': 'function'
	'array_reduce':
		'type': 'function'
	'array_replace_recursive':
		'type': 'function'
	'array_replace':
		'type': 'function'
	'array_reverse':
		'type': 'function'
	'array_search':
		'type': 'function'
	'array_shift':
		'type': 'function'
	'array_slice':
		'type': 'function'
	'array_splice':
		'type': 'function'
	'array_sum':
		'type': 'function'
	'array_udiff_assoc':
		'type': 'function'
	'array_udiff_uassoc':
		'type': 'function'
	'array_udiff':
		'type': 'function'
	'array_uintersect_assoc':
		'type': 'function'
	'array_uintersect_uassoc':
		'type': 'function'
	'array_uintersect':
		'type': 'function'
	'array_unique':
		'type': 'function'
	'array_unshift':
		'type': 'function'
	'array_values':
		'type': 'function'
	'array_walk_recursive':
		'type': 'function'
	'array_walk':
		'type': 'function'
	'array':
		'type': 'function'
	'arsort':
		'type': 'function'
	'asort':
		'type': 'function'
	'compact':
		'type': 'function'
	'count':
		'type': 'function'
	'current':
		'type': 'function'
	'each':
		'type': 'function'
	'end':
		'type': 'function'
	'extract':
		'type': 'function'
	'in_array':
		'type': 'function'
	'key_exists':
		'type': 'function'
	'key':
		'type': 'function'
	'krsort':
		'type': 'function'
	'ksort':
		'type': 'function'
	'list':
		'type': 'function'
	'natcasesort':
		'type': 'function'
	'natsort':
		'type': 'function'
	'next':
		'type': 'function'
	'pos':
		'type': 'function'
	'prev':
		'type': 'function'
	'range':
		'type': 'function'
	'reset':
		'type': 'function'
	'rsort':
		'type': 'function'
	'shuffle':
		'type': 'function'
	'sizeof':
		'type': 'function'
	'sort':
		'type': 'function'
	'uasort':
		'type': 'function'
	'uksort':
		'type': 'function'
	'usort':
		'type': 'function'


	# Objects/classes
	# Objects function
	'__autoload':
		'type': 'function'
	'call_user_method_array':
		'type': 'function'
	'call_user_method':
		'type': 'function'
	'class_alias':
		'type': 'function'
	'class_exists':
		'type': 'function'
	'get_called_class':
		'type': 'function'
	'get_class_methods':
		'type': 'function'
	'get_class_vars':
		'type': 'function'
	'get_class':
		'type': 'function'
	'get_declared_classes':
		'type': 'function'
	'get_declared_interfaces':
		'type': 'function'
	'get_declared_traits':
		'type': 'function'
	'get_object_vars':
		'type': 'function'
	'get_parent_class':
		'type': 'function'
	'interface_exists':
		'type': 'function'
	'is_a':
		'type': 'function'
	'is_subclass_of':
		'type': 'function'
	'method_exists':
		'type': 'function'
	'property_exists':
		'type': 'function'
	'trait_exists':
		'type': 'function'


	# Classkit
	# Classkit Constants
	'CLASSKIT_ACC_PRIVATE':
		'type': 'cte'
	'CLASSKIT_ACC_PROTECTED':
		'type': 'cte'
	'CLASSKIT_ACC_PUBLIC':
		'type': 'cte'
	# Classkit Functions
	'classkit_import':
		'type': 'function'
	'classkit_method_add':
		'type': 'function'
	'classkit_method_copy':
		'type': 'function'
	'classkit_method_redefine':
		'type': 'function'
	'classkit_method_remove':
		'type': 'function'
	'classkit_method_rename':
		'type': 'function'


	# Ctype
	# Ctype functions
	'ctype_alnum':
		'type': 'function'
	'ctype_alpha':
		'type': 'function'
	'ctype_cntrl':
		'type': 'function'
	'ctype_digit':
		'type': 'function'
	'ctype_graph':
		'type': 'function'
	'ctype_lower':
		'type': 'function'
	'ctype_print':
		'type': 'function'
	'ctype_punct':
		'type': 'function'
	'ctype_space':
		'type': 'function'
	'ctype_upper':
		'type': 'function'
	'ctype_xdigit':
		'type': 'function'


	# Data Filtering
	# Data Filtering Constants	
	'INPUT_POST':
		'type': 'cte'
	'INPUT_GET':
		'type': 'cte'
	'INPUT_COOKIE':
		'type': 'cte'
	'INPUT_ENV':
		'type': 'cte'
	'INPUT_SERVER':
		'type': 'cte'
	'INPUT_SESSION':
		'type': 'cte'
	'INPUT_REQUEST':
		'type': 'cte'
	'FILTER_FLAG_NONE':
		'type': 'cte'
	'FILTER_REQUIRE_SCALAR':
		'type': 'cte'
	'FILTER_REQUIRE_ARRAY':
		'type': 'cte'
	'FILTER_FORCE_ARRAY':
		'type': 'cte'
	'FILTER_NULL_ON_FAILURE':
		'type': 'cte'
	'FILTER_VALIDATE_INT':
		'type': 'cte'
	'FILTER_VALIDATE_BOOLEAN':
		'type': 'cte'
	'FILTER_VALIDATE_FLOAT':
		'type': 'cte'
	'FILTER_VALIDATE_REGEXP':
		'type': 'cte'
	'FILTER_VALIDATE_URL':
		'type': 'cte'
	'FILTER_VALIDATE_EMAIL':
		'type': 'cte'
	'FILTER_VALIDATE_IP':
		'type': 'cte'
	'FILTER_DEFAULT':
		'type': 'cte'
	'FILTER_UNSAFE_RAW':
		'type': 'cte'
	'FILTER_SANITIZE_STRING':
		'type': 'cte'
	'FILTER_SANITIZE_STRIPPED':
		'type': 'cte'
	'FILTER_SANITIZE_ENCODED':
		'type': 'cte'
	'FILTER_SANITIZE_SPECIAL_CHARS':
		'type': 'cte'
	'FILTER_SANITIZE_EMAIL':
		'type': 'cte'
	'FILTER_SANITIZE_URL':
		'type': 'cte'
	'FILTER_SANITIZE_NUMBER_INT':
		'type': 'cte'
	'FILTER_SANITIZE_NUMBER_FLOAT':
		'type': 'cte'
	'FILTER_SANITIZE_MAGIC_QUOTES':
		'type': 'cte'
	'FILTER_CALLBACK':
		'type': 'cte'
	'FILTER_FLAG_ALLOW_OCTAL':
		'type': 'cte'
	'FILTER_FLAG_ALLOW_HEX':
		'type': 'cte'
	'FILTER_FLAG_STRIP_LOW':
		'type': 'cte'
	'FILTER_FLAG_STRIP_HIGH':
		'type': 'cte'
	'FILTER_FLAG_ENCODE_LOW':
		'type': 'cte'
	'FILTER_FLAG_ENCODE_HIGH':
		'type': 'cte'
	'FILTER_FLAG_ENCODE_AMP':
		'type': 'cte'
	'FILTER_FLAG_NO_ENCODE_QUOTES':
		'type': 'cte'
	'FILTER_FLAG_EMPTY_STRING_NULL':
		'type': 'cte'
	'FILTER_FLAG_ALLOW_FRACTION':
		'type': 'cte'
	'FILTER_FLAG_ALLOW_THOUSAND':
		'type': 'cte'
	'FILTER_FLAG_ALLOW_SCIENTIFIC':
		'type': 'cte'
	'FILTER_FLAG_PATH_REQUIRED':
		'type': 'cte'
	'FILTER_FLAG_QUERY_REQUIRED':
		'type': 'cte'
	'FILTER_FLAG_IPV4':
		'type': 'cte'
	'FILTER_FLAG_IPV6':
		'type': 'cte'
	'FILTER_FLAG_NO_RES_RANGE':
		'type': 'cte'
	'FILTER_FLAG_NO_PRIV_RANGE':
		'type': 'cte'
	# Data filtering functions
	'filter_has_var':
		'type': 'function'
	'filter_id':
		'type': 'function'
	'filter_input_array':
		'type': 'function'
	'filter_input':
		'type': 'function'
	'filter_list':
		'type': 'function'
	'filter_var_array':
		'type': 'function'
	'filter_var':
		'type': 'function'


	# Object Aggregation/Composition
	# Object Aggregation functions
	'aggregate_infoh':
		'type': 'function'
	'aggregate_methods_by_list':
		'type': 'function'
	'aggregate_methods_by_regexp':
		'type': 'function'
	'aggregate_methods':
		'type': 'function'
	'aggregate_properties_by_list':
		'type': 'function'
	'aggregate_properties_by_regexp':
		'type': 'function'
	'aggregate_properties':
		'type': 'function'
	'aggregate':
		'type': 'function'
	'aggregation_info':
		'type': 'function'
	'deaggregate':
		'type': 'function'


	# Quickhash
	# Quickhash classes
	'QuickHashIntSet':
		'type': 'class'
	'QuickHashIntHash':
		'type': 'class'
	'QuickHashStringIntHash':
		'type': 'class'
	'QuickHashIntStringHash':
		'type': 'class'


	# Reflection
	# Reflection classes
	'Reflection':
		'type': 'class'
	'ReflectionClass':
		'type': 'class'
	'ReflectionZendExtension':
		'type': 'class'
	'ReflectionExtension':
		'type': 'class'
	'ReflectionFunction':
		'type': 'class'
	'ReflectionFunctionAbstract':
		'type': 'class'
	'ReflectionMethod':
		'type': 'class'
	'ReflectionObject':
		'type': 'class'
	'ReflectionParameter':
		'type': 'class'
	'ReflectionProperty':
		'type': 'class'
	'Reflector':
		'type': 'class'
	'ReflectionException':
		'type': 'class'


	# Variable handling
	# Variable handling functions
	'boolval':
		'type': 'function'
	'debug_zval_dump':
		'type': 'function'
	'doubleval':
		'type': 'function'
	'empty':
		'type': 'function'
	'floatval':
		'type': 'function'
	'get_defined_vars':
		'type': 'function'
	'get_resource_type':
		'type': 'function'
	'gettype':
		'type': 'function'
	'import_request_variables':
		'type': 'function'
	'intval':
		'type': 'function'
	'is_array':
		'type': 'function'
	'is_bool':
		'type': 'function'
	'is_callable':
		'type': 'function'
	'is_double':
		'type': 'function'
	'is_float':
		'type': 'function'
	'is_int':
		'type': 'function'
	'is_integer':
		'type': 'function'
	'is_long':
		'type': 'function'
	'is_null':
		'type': 'function'
	'is_numeric':
		'type': 'function'
	'is_object':
		'type': 'function'
	'is_real':
		'type': 'function'
	'is_resource':
		'type': 'function'
	'is_scalar':
		'type': 'function'
	'is_string':
		'type': 'function'
	'isset':
		'type': 'function'
	'print_r':
		'type': 'function'
	'serialize':
		'type': 'function'
	'settype':
		'type': 'function'
	'strval':
		'type': 'function'
	'unserialize':
		'type': 'function'
	'unset':
		'type': 'function'
	'var_dump':
		'type': 'function'
	'var_export':
		'type': 'function'


	### File System Related Extensions ###

	# Direct IO
	# Direct IO constants
	'F_DUPFD':
		'type': 'cte'
	'F_GETFD':
		'type': 'cte'
	'F_GETFL':
		'type': 'cte'
	'F_GETLK':
		'type': 'cte'
	'F_GETOWN':
		'type': 'cte'
	'F_RDLCK':
		'type': 'cte'
	'F_SETFL':
		'type': 'cte'
	'F_SETLK':
		'type': 'cte'
	'F_SETLKW':
		'type': 'cte'
	'F_SETOWN':
		'type': 'cte'
	'F_UNLCK':
		'type': 'cte'
	'F_WRLCK':
		'type': 'cte'
	'O_APPEND':
		'type': 'cte'
	'O_ASYNC':
		'type': 'cte'
	'O_CREAT':
		'type': 'cte'
	'O_EXCL':
		'type': 'cte'
	'O_NDELAY':
		'type': 'cte'
	'O_NOCTTY':
		'type': 'cte'
	'O_NONBLOCK':
		'type': 'cte'
	'O_RDONLY':
		'type': 'cte'
	'O_RDWR':
		'type': 'cte'
	'O_SYNC':
		'type': 'cte'
	'O_TRUNC':
		'type': 'cte'
	'O_WRONLY':
		'type': 'cte'
	'S_IRGRP':
		'type': 'cte'
	'S_IROTH':
		'type': 'cte'
	'S_IRUSR':
		'type': 'cte'
	'S_IRWXG':
		'type': 'cte'
	'S_IRWXO':
		'type': 'cte'
	'S_IRWXU':
		'type': 'cte'
	'S_IWGRP':
		'type': 'cte'
	'S_IWOTH':
		'type': 'cte'
	'S_IWUSR':
		'type': 'cte'
	'S_IXGRP':
		'type': 'cte'
	'S_IXOTH':
		'type': 'cte'
	'S_IXUSR':
		'type': 'cte'
	# Direct IO functions
	'dio_close':
		'type': 'function'
	'dio_fcntl':
		'type': 'function'
	'dio_open':
		'type': 'function'
	'dio_read':
		'type': 'function'
	'dio_seek':
		'type': 'function'
	'dio_stat':
		'type': 'function'
	'dio_tcsetattr':
		'type': 'function'
	'dio_truncate':
		'type': 'function'
	'dio_write':
		'type': 'function'

	# Directories 
	# Directories constants
	'DIRECTORY_SEPARATOR':
		'type': 'cte'
	'PATH_SEPARATOR':
		'type': 'cte'
	'SCANDIR_SORT_ASCENDING':
		'type': 'cte'
	'SCANDIR_SORT_DESCENDING':
		'type': 'cte'
	'SCANDIR_SORT_NONE':
		'type': 'cte'
	# Directories classes
	"Directory":
		"type": "class"
	# Directories functions
	'chdir':
		'type': 'function'
	'chroot':
		'type': 'function'
	'closedir':
		'type': 'function'
	'dir':
		'type': 'function'
	'getcwd':
		'type': 'function'
	'opendir':
		'type': 'function'
	'readdir':
		'type': 'function'
	'rewinddir':
		'type': 'function'
	'scandir':
		'type': 'function'

	# File Information
	# File Information constants
	'FILEINFO_NONE':
		'type': 'cte'
	'FILEINFO_SYMLINK':
		'type': 'cte'
	'FILEINFO_MIME_TYPE':
		'type': 'cte'
	'FILEINFO_MIME_ENCODING':
		'type': 'cte'
	'FILEINFO_MIME':
		'type': 'cte'
	'FILEINFO_COMPRESS':
		'type': 'cte'
	'FILEINFO_DEVICES':
		'type': 'cte'
	'FILEINFO_CONTINUE':
		'type': 'cte'
	'FILEINFO_PRESERVE_ATIME':
		'type': 'cte'
	'FILEINFO_RAW':
		'type': 'cte'
	# File Information functions
	'finfo_close':
		'type': 'function'
	'finfo_file':
		'type': 'function'
	'finfo_open':
		'type': 'function'
	'finfo_set_flags':
		'type': 'function'
	'mime_content_type':
		'type': 'function'

	# Filesystem
	# Filesystem constants
	'SEEK_SET':
		'type': 'cte'
	'SEEK_CUR':
		'type': 'cte'
	'SEEK_END':
		'type': 'cte'
	'LOCK_SH':
		'type': 'cte'
	'LOCK_EX':
		'type': 'cte'
	'LOCK_UN':
		'type': 'cte'
	'LOCK_NB':
		'type': 'cte'
	'GLOB_BRACE':
		'type': 'cte'
	'GLOB_ONLYDIR':
		'type': 'cte'
	'GLOB_MARK':
		'type': 'cte'
	'GLOB_NOSORT':
		'type': 'cte'
	'GLOB_NOCHECK':
		'type': 'cte'
	'GLOB_NOESCAPE':
		'type': 'cte'
	'GLOB_AVAILABLE_FLAGS':
		'type': 'cte'
	'PATHINFO_DIRNAME':
		'type': 'cte'
	'PATHINFO_BASENAME':
		'type': 'cte'
	'PATHINFO_EXTENSION':
		'type': 'cte'
	'PATHINFO_FILENAME':
		'type': 'cte'
	'FILE_USE_INCLUDE_PATH':
		'type': 'cte'
	'FILE_NO_DEFAULT_CONTEXT':
		'type': 'cte'
	'FILE_APPEND':
		'type': 'cte'
	'FILE_IGNORE_NEW_LINES':
		'type': 'cte'
	'FILE_SKIP_EMPTY_LINES':
		'type': 'cte'
	'FILE_BINARY':
		'type': 'cte'
	'FILE_TEXT':
		'type': 'cte'
	'INI_SCANNER_NORMAL':
		'type': 'cte'
	'INI_SCANNER_RAW':
		'type': 'cte'
	'FNM_NOESCAPE':
		'type': 'cte'
	'FNM_PATHNAME':
		'type': 'cte'
	'FNM_PERIOD':
		'type': 'cte'
	'FNM_CASEFOLD':
		'type': 'cte'
	# Filesystem functions
	'basename':
		'type': 'function'
	'chgrp':
		'type': 'function'
	'chmod':
		'type': 'function'
	'chown':
		'type': 'function'
	'clearstatcache':
		'type': 'function'
	'copy':
		'type': 'function'
	'delete':
		'type': 'function'
	'dirname':
		'type': 'function'
	'disk_free_space':
		'type': 'function'
	'disk_total_space':
		'type': 'function'
	'diskfreespace':
		'type': 'function'
	'fclose':
		'type': 'function'
	'feof':
		'type': 'function'
	'fflush':
		'type': 'function'
	'fgetc':
		'type': 'function'
	'fgetcsv':
		'type': 'function'
	'fgets':
		'type': 'function'
	'fgetss':
		'type': 'function'
	'file_exists':
		'type': 'function'
	'file_get_contents':
		'type': 'function'
	'file_put_contents':
		'type': 'function'
	'file':
		'type': 'function'
	'fileatime':
		'type': 'function'
	'filectime':
		'type': 'function'
	'filegroup':
		'type': 'function'
	'fileinode':
		'type': 'function'
	'filemtime':
		'type': 'function'
	'fileowner':
		'type': 'function'
	'fileperms':
		'type': 'function'
	'filesize':
		'type': 'function'
	'filetype':
		'type': 'function'
	'flock':
		'type': 'function'
	'fnmatch':
		'type': 'function'
	'fopen':
		'type': 'function'
	'fpassthru':
		'type': 'function'
	'fputcsv':
		'type': 'function'
	'fputs':
		'type': 'function'
	'fread':
		'type': 'function'
	'fscanf':
		'type': 'function'
	'fseek':
		'type': 'function'
	'fstat':
		'type': 'function'
	'ftell':
		'type': 'function'
	'ftruncate':
		'type': 'function'
	'fwrite':
		'type': 'function'
	'glob':
		'type': 'function'
	'is_dir':
		'type': 'function'
	'is_executable':
		'type': 'function'
	'is_file':
		'type': 'function'
	'is_link':
		'type': 'function'
	'is_readable':
		'type': 'function'
	'is_uploaded_file':
		'type': 'function'
	'is_writable':
		'type': 'function'
	'is_writeable':
		'type': 'function'
	'lchgrp':
		'type': 'function'
	'lchown':
		'type': 'function'
	'link':
		'type': 'function'
	'linkinfo':
		'type': 'function'
	'lstat':
		'type': 'function'
	'mkdir':
		'type': 'function'
	'move_uploaded_file':
		'type': 'function'
	'parse_ini_file':
		'type': 'function'
	'parse_ini_string':
		'type': 'function'
	'pathinfo':
		'type': 'function'
	'pclose':
		'type': 'function'
	'popen':
		'type': 'function'
	'readfile':
		'type': 'function'
	'readlink':
		'type': 'function'
	'realpath_cache_get':
		'type': 'function'
	'realpath_cache_size':
		'type': 'function'
	'realpath':
		'type': 'function'
	'rename':
		'type': 'function'
	'rewind':
		'type': 'function'
	'rmdir':
		'type': 'function'
	'set_file_buffer':
		'type': 'function'
	'stat':
		'type': 'function'
	'symlink':
		'type': 'function'
	'tempnam':
		'type': 'function'
	'tmpfile':
		'type': 'function'
	'touch':
		'type': 'function'
	'umask':
		'type': 'function'
	'unlink':
		'type': 'function'

	# Inotify
	# Inotify constants
	'IN_ACCESS':
		'type': 'cte'
	'IN_MODIFY':
		'type': 'cte'
	'IN_ATTRIB':
		'type': 'cte'
	'IN_CLOSE_WRITE':
		'type': 'cte'
	'IN_CLOSE_NOWRITE':
		'type': 'cte'
	'IN_OPEN':
		'type': 'cte'
	'IN_MOVED_TO':
		'type': 'cte'
	'IN_MOVED_FROM':
		'type': 'cte'
	'IN_CREATE':
		'type': 'cte'
	'IN_DELETE':
		'type': 'cte'
	'IN_DELETE_SELF':
		'type': 'cte'
	'IN_MOVE_SELF':
		'type': 'cte'
	'IN_CLOSE':
		'type': 'cte'
	'IN_MOVE':
		'type': 'cte'
	'IN_ALL_EVENTS':
		'type': 'cte'
	'IN_UNMOUNT':
		'type': 'cte'
	'IN_Q_OVERFLOW':
		'type': 'cte'
	'IN_IGNORED':
		'type': 'cte'
	'IN_ISDIR':
		'type': 'cte'
	'IN_ONLYDIR':
		'type': 'cte'
	'IN_DONT_FOLLOW':
		'type': 'cte'
	'IN_MASK_ADD':
		'type': 'cte'
	'IN_ONESHOT':
		'type': 'cte'
	# Inotify functions
	'inotify_add_watch':
		'type': 'function'
	'inotify_init':
		'type': 'function'
	'inotify_queue_len':
		'type': 'function'
	'inotify_read':
		'type': 'function'
	'inotify_rm_watch':
		'type': 'function'

	# Proctitle
	# Proctitle functions
	'setproctitle':
		'type': 'function'
	'setthreadtitle':
		'type': 'function'

	# xattr
	# xattr constants
	'XATTR_ROOT':
		'type': 'cte'
	'XATTR_DONTFOLLOW':
		'type': 'cte'
	'XATTR_CREATE':
		'type': 'cte'
	'XATTR_REPLACE':
		'type': 'cte'
	# xattr functions
	'xattr_get':
		'type': 'function'
	'xattr_list':
		'type': 'function'
	'xattr_remove':
		'type': 'function'
	'xattr_set':
		'type': 'function'
	'xattr_supported':
		'type': 'function'

	# xdiff
	# xdiff constants
	'XDIFF_PATCH_NORMAL':
		'type': 'cte'
	'XDIFF_PATCH_REVERSE':
		'type': 'cte'
	# xdiff functions
	'xdiff_file_bdiff_size':
		'type': 'function'
	'xdiff_file_bdiff':
		'type': 'function'
	'xdiff_file_bpatch':
		'type': 'function'
	'xdiff_file_diff_binary':
		'type': 'function'
	'xdiff_file_diff':
		'type': 'function'
	'xdiff_file_merge3':
		'type': 'function'
	'xdiff_file_patch_binary':
		'type': 'function'
	'xdiff_file_patch':
		'type': 'function'
	'xdiff_file_rabdiff':
		'type': 'function'
	'xdiff_string_bdiff_size':
		'type': 'function'
	'xdiff_string_bdiff':
		'type': 'function'
	'xdiff_string_bpatch':
		'type': 'function'
	'xdiff_string_diff_binary':
		'type': 'function'
	'xdiff_string_diff':
		'type': 'function'
	'xdiff_string_merge3':
		'type': 'function'
	'xdiff_string_patch_binary':
		'type': 'function'
	'xdiff_string_patch':
		'type': 'function'
	'xdiff_string_rabdiff':
		'type': 'function'


	### Cryptography Extensions ###

	# Crack
	# Crack functions
	'crack_check':
		'type': 'function'
	'crack_closedict':
		'type': 'function'
	'crack_getlastmessage':
		'type': 'function'
	'crack_opendict':
		'type': 'function'

	# Hash
	# Hash constants
	'HASH_HMAC':
		'type': 'cte'
	# Hash functions
	'hash_algos':
		'type': 'function'
	'hash_copy':
		'type': 'function'
	'hash_file':
		'type': 'function'
	'hash_final':
		'type': 'function'
	'hash_hmac_file':
		'type': 'function'
	'hash_hmac':
		'type': 'function'
	'hash_init':
		'type': 'function'
	'hash_pbkdf2':
		'type': 'function'
	'hash_update_file':
		'type': 'function'
	'hash_update_stream':
		'type': 'function'
	'hash_update':
		'type': 'function'
	'hash':
		'type': 'function'

	# Mcrypt
	# Mcrypt constants
	'MCRYPT_MODE_ECB':
		'type': 'cte'
	'MCRYPT_MODE_CBC':
		'type': 'cte'
	'MCRYPT_MODE_CFB':
		'type': 'cte'
	'MCRYPT_MODE_OFB':
		'type': 'cte'
	'MCRYPT_MODE_NOFB':
		'type': 'cte'
	'MCRYPT_MODE_STREAM':
		'type': 'cte'
	'MCRYPT_ENCRYPT':
		'type': 'cte'
	'MCRYPT_DECRYPT':
		'type': 'cte'
	'MCRYPT_DEV_RANDOM':
		'type': 'cte'
	'MCRYPT_DEV_URANDOM':
		'type': 'cte'
	'MCRYPT_RAND':
		'type': 'cte' 
	# Mcrypt functions
	'mcrypt_cbc':
		'type': 'function'
	'mcrypt_cfb':
		'type': 'function'
	'mcrypt_create_iv':
		'type': 'function'
	'mcrypt_decrypt':
		'type': 'function'
	'mcrypt_ecb':
		'type': 'function'
	'mcrypt_enc_get_algorithms_name':
		'type': 'function'
	'mcrypt_enc_get_block_size':
		'type': 'function'
	'mcrypt_enc_get_iv_size':
		'type': 'function'
	'mcrypt_enc_get_key_size':
		'type': 'function'
	'mcrypt_enc_get_modes_name':
		'type': 'function'
	'mcrypt_enc_get_supported_key_sizes':
		'type': 'function'
	'mcrypt_enc_is_block_algorithm_mode':
		'type': 'function'
	'mcrypt_enc_is_block_algorithm':
		'type': 'function'
	'mcrypt_enc_is_block_mode':
		'type': 'function'
	'mcrypt_enc_self_test':
		'type': 'function'
	'mcrypt_encrypt':
		'type': 'function'
	'mcrypt_generic_deinit':
		'type': 'function'
	'mcrypt_generic_end':
		'type': 'function'
	'mcrypt_generic_init':
		'type': 'function'
	'mcrypt_generic':
		'type': 'function'
	'mcrypt_get_block_size':
		'type': 'function'
	'mcrypt_get_cipher_name':
		'type': 'function'
	'mcrypt_get_iv_size':
		'type': 'function'
	'mcrypt_get_key_size':
		'type': 'function'
	'mcrypt_list_algorithms':
		'type': 'function'
	'mcrypt_list_modes':
		'type': 'function'
	'mcrypt_module_close':
		'type': 'function'
	'mcrypt_module_get_algo_block_size':
		'type': 'function'
	'mcrypt_module_get_algo_key_size':
		'type': 'function'
	'mcrypt_module_get_supported_key_sizes':
		'type': 'function'
	'mcrypt_module_is_block_algorithm_mode':
		'type': 'function'
	'mcrypt_module_is_block_algorithm':
		'type': 'function'
	'mcrypt_module_is_block_mode':
		'type': 'function'
	'mcrypt_module_open':
		'type': 'function'
	'mcrypt_module_self_test':
		'type': 'function'
	'mcrypt_ofb':
		'type': 'function'
	'mdecrypt_generic':
		'type': 'function'

	# Mhash
	# Mhash constants
	'MHASH_ADLER32':
		'type': 'cte'
	'MHASH_CRC32':
		'type': 'cte'
	'MHASH_CRC32B':
		'type': 'cte'
	'MHASH_GOST':
		'type': 'cte'
	'MHASH_HAVAL128':
		'type': 'cte'
	'MHASH_HAVAL160':
		'type': 'cte'
	'MHASH_HAVAL192':
		'type': 'cte'
	'MHASH_HAVAL224':
		'type': 'cte'
	'MHASH_HAVAL256':
		'type': 'cte'
	'MHASH_MD2':
		'type': 'cte'
	'MHASH_MD4':
		'type': 'cte'
	'MHASH_MD5':
		'type': 'cte'
	'MHASH_RIPEMD128':
		'type': 'cte'
	'MHASH_RIPEMD256':
		'type': 'cte'
	'MHASH_RIPEMD320':
		'type': 'cte'
	'MHASH_SHA1':
		'type': 'cte'
	'MHASH_SHA192':
		'type': 'cte'
	'MHASH_SHA224':
		'type': 'cte'
	'MHASH_SHA256':
		'type': 'cte'
	'MHASH_SHA384':
		'type': 'cte'
	'MHASH_SHA512':
		'type': 'cte'
	'MHASH_SNEFRU128':
		'type': 'cte'
	'MHASH_SNEFRU256':
		'type': 'cte'
	'MHASH_TIGER':
		'type': 'cte'
	'MHASH_TIGER128':
		'type': 'cte'
	'MHASH_TIGER160':
		'type': 'cte'
	'MHASH_WHIRLPOOL ':
		'type': 'cte'
	# Mhash functions
	'mhash_count':
		'type': 'function'
	'mhash_get_block_size':
		'type': 'function'
	'mhash_get_hash_name':
		'type': 'function'
	'mhash_keygen_s2k':
		'type': 'function'
	'mhash':
		'type': 'function'

	# OpenSSL
	# OpenSSL constants
	'X509_PURPOSE_SSL_CLIENT':
		'type': 'cte'
	'X509_PURPOSE_SSL_SERVER':
		'type': 'cte'
	'X509_PURPOSE_NS_SSL_SERVER':
		'type': 'cte'
	'X509_PURPOSE_SMIME_SIGN':
		'type': 'cte'
	'X509_PURPOSE_SMIME_ENCRYPT':
		'type': 'cte'
	'X509_PURPOSE_CRL_SIGN':
		'type': 'cte'
	'X509_PURPOSE_ANY':
		'type': 'cte' 
	'OPENSSL_PKCS1_PADDING':
		'type': 'cte'
	'OPENSSL_SSLV23_PADDING':
		'type': 'cte'
	'OPENSSL_NO_PADDING':
		'type': 'cte'
	'OPENSSL_PKCS1_OAEP_PADDING':
		'type': 'cte'
	'OPENSSL_KEYTYPE_RSA':
		'type': 'cte'
	'OPENSSL_KEYTYPE_DSA':
		'type': 'cte'
	'OPENSSL_KEYTYPE_DH':
		'type': 'cte'
	'OPENSSL_KEYTYPE_EC':
		'type': 'cte'
	'OPENSSL_KEYTYPE_EC':
		'type': 'cte'
	'PKCS7_TEXT':
		'type': 'cte'
	'PKCS7_BINARY':
		'type': 'cte'
	'PKCS7_NOINTERN':
		'type': 'cte'
	'PKCS7_NOVERIFY':
		'type': 'cte'
	'PKCS7_NOCHAIN':
		'type': 'cte'
	'PKCS7_NOCERTS':
		'type': 'cte'
	'PKCS7_NOATTR':
		'type': 'cte'
	'PKCS7_DETACHED':
		'type': 'cte'
	'PKCS7_NOSIGS':
		'type': 'cte'
	'OPENSSL_ALGO_DSS1':
		'type': 'cte'
	'OPENSSL_ALGO_SHA1':
		'type': 'cte'
	'OPENSSL_ALGO_SHA224':
		'type': 'cte'
	'OPENSSL_ALGO_SHA256':
		'type': 'cte'
	'OPENSSL_ALGO_SHA384':
		'type': 'cte'
	'OPENSSL_ALGO_SHA512':
		'type': 'cte'
	'OPENSSL_ALGO_RMD160':
		'type': 'cte'
	'OPENSSL_ALGO_MD5':
		'type': 'cte'
	'OPENSSL_ALGO_MD4':
		'type': 'cte'
	'OPENSSL_ALGO_MD2':
		'type': 'cte' 
	'OPENSSL_CIPHER_RC2_40':
		'type': 'cte'
	'OPENSSL_CIPHER_RC2_128':
		'type': 'cte'
	'OPENSSL_CIPHER_RC2_64':
		'type': 'cte'
	'OPENSSL_CIPHER_DES':
		'type': 'cte'
	'OPENSSL_CIPHER_3DES':
		'type': 'cte' 
	'OPENSSL_CIPHER_AES_128_CBC':
		'type': 'cte'
	'OPENSSL_CIPHER_AES_192_CBC':
		'type': 'cte'
	'OPENSSL_CIPHER_AES_256_CBC':
		'type': 'cte' 
	'OPENSSL_VERSION_TEXT':
		'type': 'cte'
	'OPENSSL_VERSION_NUMBER':
		'type': 'cte'
	'OPENSSL_TLSEXT_SERVER_NAME':
		'type': 'cte'
	# OpenSSL functions
	'openssl_cipher_iv_length':
		'type': 'function'
	'openssl_csr_export_to_file':
		'type': 'function'
	'openssl_csr_export':
		'type': 'function'
	'openssl_csr_get_public_key':
		'type': 'function'
	'openssl_csr_get_subject':
		'type': 'function'
	'openssl_csr_new':
		'type': 'function'
	'openssl_csr_sign':
		'type': 'function'
	'openssl_decrypt':
		'type': 'function'
	'openssl_dh_compute_key':
		'type': 'function'
	'openssl_digest':
		'type': 'function'
	'openssl_encrypt':
		'type': 'function'
	'openssl_error_string':
		'type': 'function'
	'openssl_free_key':
		'type': 'function'
	'openssl_get_cipher_methods':
		'type': 'function'
	'openssl_get_md_methods':
		'type': 'function'
	'openssl_get_privatekey':
		'type': 'function'
	'openssl_get_publickey':
		'type': 'function'
	'openssl_open':
		'type': 'function'
	'openssl_pbkdf2':
		'type': 'function'
	'openssl_pkcs12_export_to_file':
		'type': 'function'
	'openssl_pkcs12_export':
		'type': 'function'
	'openssl_pkcs12_read':
		'type': 'function'
	'openssl_pkcs7_decrypt':
		'type': 'function'
	'openssl_pkcs7_encrypt':
		'type': 'function'
	'openssl_pkcs7_sign':
		'type': 'function'
	'openssl_pkcs7_verify':
		'type': 'function'
	'openssl_pkey_export_to_file':
		'type': 'function'
	'openssl_pkey_export':
		'type': 'function'
	'openssl_pkey_free':
		'type': 'function'
	'openssl_pkey_get_details':
		'type': 'function'
	'openssl_pkey_get_private':
		'type': 'function'
	'openssl_pkey_get_public':
		'type': 'function'
	'openssl_pkey_new':
		'type': 'function'
	'openssl_private_decrypt':
		'type': 'function'
	'openssl_private_encrypt':
		'type': 'function'
	'openssl_public_decrypt':
		'type': 'function'
	'openssl_public_encrypt':
		'type': 'function'
	'openssl_random_pseudo_bytes':
		'type': 'function'
	'openssl_seal':
		'type': 'function'
	'openssl_sign':
		'type': 'function'
	'openssl_spki_export_challenge':
		'type': 'function'
	'openssl_spki_export':
		'type': 'function'
	'openssl_spki_new':
		'type': 'function'
	'openssl_spki_verify':
		'type': 'function'
	'openssl_verify':
		'type': 'function'
	'openssl_x509_check_private_key':
		'type': 'function'
	'openssl_x509_checkpurpose':
		'type': 'function'
	'openssl_x509_export_to_file':
		'type': 'function'
	'openssl_x509_export':
		'type': 'function'
	'openssl_x509_fingerprint':
		'type': 'function'
	'openssl_x509_free':
		'type': 'function'
	'openssl_x509_parse':
		'type': 'function'
	'openssl_x509_read':
		'type': 'function'

	# Password Hashing
	# Password Hashing constants
	'PASSWORD_BCRYPT':
		'type': 'cte'
	'PASSWORD_DEFAULT':
		'type': 'cte'
	# Password Hashing functions
	'password_get_info':
		'type': 'function'
	'password_hash':
		'type': 'function'
	'password_needs_rehash':
		'type': 'function'
	'password_verify':
		'type': 'function'
})