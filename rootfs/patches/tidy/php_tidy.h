--- php_tidy.h
+++ php_tidy.h.p
@@ -37,7 +37,7 @@
 
 #include "tidyenum.h"
 #include "tidy.h"
-#include "buffio.h"
+#include "tidybuffio.h"
 
 #ifdef ZTS
 #define TG(v) TSRMG(tidy_globals_id, zend_tidy_globals *, v)
