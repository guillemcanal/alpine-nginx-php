--- tidy.c
+++ tidy.c.p
@@ -29,7 +29,6 @@
 #include "ext/standard/info.h"
 #include "Zend/zend_API.h"
 #include "Zend/zend_hash.h"
-#include "safe_mode.h"
 
 ZEND_DECLARE_MODULE_GLOBALS(tidy);
 
@@ -40,13 +39,13 @@
 } \
 
 #define TIDY_SAFE_MODE_CHECK(filename) \
-if ((PG(safe_mode) && (!php_checkuid(filename, NULL, CHECKUID_CHECK_FILE_AND_DIR))) || php_check_open_basedir(filename TSRMLS_CC)) { \
+if (php_check_open_basedir(filename TSRMLS_CC)) { \
 	RETURN_FALSE; \
 } \
 
 #define TIDY_CLEAR_ERROR  if (TG(tdoc)->errbuf && TG(tdoc)->errbuf->bp) { tidyBufClear(TG(tdoc)->errbuf); }
 
-function_entry tidy_functions[] = {
+zend_function_entry tidy_functions[] = {
 	PHP_FE(tidy_setopt,             NULL)
 	PHP_FE(tidy_getopt,             NULL)
 	PHP_FE(tidy_parse_string,       NULL)
