# Symfony 2 PHP-FPM Nginx

Nginx and PHP-FPM running together in a docker container.
This image is based on `alpine:3.3` with [S6](http://skarnet.org/software/s6/) 
and optimized for Symfony 3.

## Build

`docker build -t username/alpine-php-nginx .`

## Use

### Mounting your project file for development purpose

To be used in your Symfony 3 folder:  
`docker run -d --name my-app -p 1337:80 -e SYMFONY_ENV=dev -v $(pwd):/var/www username/alpine-php-nginx .`

### Use bash inside your container

`docker exec -ti -u nginx:www-data -w /var/www my-app bash`

## Tweak

To build a PHP extension from source, just append a `pecl_install` function in `rootfs/sbin/build-php-extensions`.  
It take 4 arguments:

`pecl_install $EXT_TYPE $NAME $VERSION $CONFIGURE_ARGS`

- `$EXT_TYPE`: either `extension` or `zend_extension`
- `$NAME`: The name of your extension
- `$VERSION`: The version you wish to build
- `$CONFIGURE_ARGS`: configuration options passed to the  `./configure` script (ex: `--enable-memcache`)

## Modify...

...your `./web/app.php` file to switch between Symfony environments using (drum roll) an environment variable.

For example:

```php
<?php
use Symfony\Component\HttpFoundation\Request;

/** @var Composer\Autoload\ClassLoader $loader */
$loader = require dirname(__DIR__) . '/app/autoload.php';

$env = getenv('SYMFONY_ENV') ?: 'prod';
$debug = false;

if (in_array($env, ['dev', 'test'])) {
    $debug = true;
    Symfony\Component\Debug\Debug::enable();
} else {
    include_once  dirname(__DIR__).'/var/bootstrap.php.cache';
}

$kernel = new AppKernel($env, $debug);
$kernel->loadClassCache();

$request = Request::createFromGlobals();
$response = $kernel->handle($request);
$response->send();
$kernel->terminate($request, $response);
```

## Contribute

This image can be improved in many ways, feel free to contribute ;)
